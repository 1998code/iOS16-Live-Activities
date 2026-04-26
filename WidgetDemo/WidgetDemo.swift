//
//  WidgetDemo.swift
//  WidgetDemo
//
//  Created by Ming on 28/7/2022.
//

import ActivityKit
import WidgetKit
import SwiftUI

@main
struct Widgets: WidgetBundle {
   var body: some Widget {
       PizzaDeliveryActivityWidget()
       PizzaAdActivityWidget()
   }
}

/// Pure function of `state` + wall-clock time. This is the key:
/// because the widget body is re-evaluated when `staleDate` passes,
/// this check will flip from `false` → `true` on its own — no app code,
/// no push — and the widget swaps to its "done" layout.
private func isDelivered(_ context: ActivityViewContext<PizzaDeliveryAttributes>) -> Bool {
    context.isStale || Date() >= context.state.estimatedDeliveryTime.upperBound
}

/// Warehouse (orange) before the fill reaches it, ✓ (green) after.
/// Driven by the `activity.update()` push that the app's keep-alive
/// timer fires at the delivery midpoint — TimelineView alone is not
/// reliable for Live Activity re-renders once the phone is locked.
@ViewBuilder
private func midpointIcon(for range: ClosedRange<Date>) -> some View {
    let midpoint = range.lowerBound.addingTimeInterval(
        range.upperBound.timeIntervalSince(range.lowerBound) / 2
    )
    if Date() >= midpoint {
        Image(systemName: "checkmark.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundColor(.green)
            .background(Circle().fill(.white))
            .frame(width: 28, height: 28)
    } else {
        Image(systemName: "building.2.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundColor(.orange)
            .background(Circle().fill(.white))
            .frame(width: 28, height: 28)
    }
}

// Note on the progress bar:
// In Live Activities, `ProgressView(timerInterval:)` only auto-updates when
// rendered with a *built-in* style (`.linear`). Custom `ProgressViewStyle`s
// receive `fractionCompleted` once at body evaluation and never update again,
// which is why the previous custom style stayed frozen at its starting width.
// We use the built-in linear style and compose the rounded track + icon
// overlay around it.

/// Historical wrapper used across all Dynamic Island regions. The stale/timeline/
/// both experiments are gone, so it's now a passthrough — left in place to keep
/// the widget body diff small. Safe to inline away later.
@ViewBuilder
private func timelineWrapped<Content: View>(
    context: ActivityViewContext<PizzaDeliveryAttributes>,
    @ViewBuilder content: @escaping () -> Content
) -> some View {
    content()
}

struct PizzaDeliveryActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PizzaDeliveryAttributes.self) { context in
            timelineWrapped(context: context) {
            // MARK: - For devices that don't support the Dynamic Island.
            if isDelivered(context) {
                // End-state: driver message is the headline. Package has
                // met home → they collapse into a single ✓ at the right
                // end of the (now fully blue) bar. Paid-footer text is
                // kept to mirror the in-progress layout so the transition
                // doesn't shrink the widget.
                VStack(alignment: .leading) {
                    Text("\(context.state.driverName) dropped off your order! 📦")
                        .font(.headline)
                        .padding(.horizontal, 5)
                    HStack {
                        ZStack {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .green],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 28)

                            // Delivered: single ✓ at the right edge.
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.green)
                                    .background(Circle().fill(.white))
                                    .frame(width: 28, height: 28)
                            }
                        }
                        .frame(height: 32)
                        Spacer()
                        Image(context.state.driverName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                    }.padding(5)
                    Text("You've already paid: \(context.attributes.totalAmount) + $9.9 Delivery Fee 💸")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 5)
                }.padding(15)
            } else {
            VStack(alignment: .leading) {
                if context.state.driverName == "Tim" {
                    Text("Your \(context.state.driverName) is on the way!")
                        .font(.headline)
                        .padding(.horizontal, 5)
                } else {
                    Text("Apple reassigned \(context.state.driverName) to deliver your order")
                        .font(.headline)
                        .padding(.horizontal, 5)
                }
                HStack {
                    VStack(alignment: .leading) {
                        // Bar stack:
                        //  - Gray track (full width, height 28pt to fit icons)
                        //  - Blue fill: `ProgressView(timerInterval:)` + `.linear`
                        //    is the ONLY widget primitive iOS interpolates
                        //    frame-to-frame — stays buttery smooth.
                        //  - Package (left) + home (right) sit ON the bar;
                        //    both are 28pt so they match the bar height
                        //    exactly (no icons-taller-than-bar gap).
                        //  - Package is static: Live Activity widgets are
                        //    snapshot-rendered with strict re-render budgets,
                        //    so nothing except the ProgressView fill can
                        //    animate smoothly. The blue fill sweeping across
                        //    the package → home IS the progress visual.
                        //    At endDate the delivered layout renders a
                        //    single ✓ where the two icons "meet".
                        ZStack {
                            Capsule()
                                .fill(Color.secondary.opacity(0.25))
                                .frame(height: 28)

                            ProgressView(timerInterval: context.state.estimatedDeliveryTime, countsDown: false) {
                                EmptyView()
                            } currentValueLabel: {
                                EmptyView()
                            }
                            .tint(
                                LinearGradient(
                                    colors: [.blue, .green],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .progressViewStyle(.linear)
                            .scaleEffect(x: 1, y: 7, anchor: .center)
                            .frame(height: 28)
                            .clipShape(Capsule())

                            // Dead-center warehouse trick: split the bar
                            // into two equal halves via `maxWidth: .infinity`
                            // with the warehouse icon sitting in the seam.
                            // Each half gets (barWidth - 28)/2, so the
                            // warehouse's center lands exactly on barWidth/2
                            // regardless of how wide the timer text is.
                            HStack(spacing: 0) {
                                // Left half: package pinned left, timer pinned right
                                HStack {
                                    Image(systemName: "shippingbox.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.white)
                                        .frame(width: 28, height: 28)
                                    Spacer()
                                    Text(timerInterval: context.state.estimatedDeliveryTime, countsDown: true)
                                        .bold()
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .monospacedDigit()
                                        .padding(.trailing, 4)
                                }
                                .frame(maxWidth: .infinity)

                                // Warehouse → ✓ swap at midpoint. Driven by
                                // the app's keep-alive push; see helper.
                                midpointIcon(for: context.state.estimatedDeliveryTime)

                                // Right half: home pinned right
                                HStack {
                                    Spacer()
                                    Image(systemName: "house.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.green)
                                        .background(Circle().fill(.white))
                                        .frame(width: 28, height: 28)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: 32)
                    }
                    Spacer()
                    VStack {
                        Image(context.state.driverName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                        Spacer()
                    }
                }.padding(5)
                Text("You've already paid: \(context.attributes.totalAmount) + $9.9 Delivery Fee 💸")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 5)
            }.padding(15)
            }
            } // end timelineWrapped
            // MARK: - For Dynamic Island
        } dynamicIsland: { context in
            // NOTE: the `delivered` flag is NOT captured once at the top of the
            // closure — each region re-evaluates it inside its own TimelineView
            // so the DI regions flip the instant `endDate` is reached even when
            // the app is suspended and `staleDate` hasn't fired yet.
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    timelineWrapped(context: context) {
                        if isDelivered(context) {
                            Label("Delivered", systemImage: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.green)
                        } else {
                            Label("\(context.attributes.numberOfPizzas) Pizza", systemImage: "bag")
                                .font(.title3)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    timelineWrapped(context: context) {
                        if isDelivered(context) {
                            Label("Done", systemImage: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                        } else {
                            Label {
                                Text(timerInterval: context.state.estimatedDeliveryTime, countsDown: true)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 50)
                                    .monospacedDigit()
                                    .font(.caption2)
                            } icon: {
                                Image(systemName: "timer")
                            }
                            .font(.title2)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    timelineWrapped(context: context) {
                        if isDelivered(context) {
                            Text("Enjoy your pizza! 🍕")
                                .lineLimit(1)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            VStack(spacing: 5) {
                                Text("\(context.state.driverName) is on the way!")
                                    .lineLimit(1)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                ProgressView(timerInterval: context.state.estimatedDeliveryTime, countsDown: false)
                                    .tint(.blue)
                                    .progressViewStyle(.linear)
                            }
                        }
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    timelineWrapped(context: context) {
                        if isDelivered(context) {
                            HStack {
                                Spacer()
                                Label("Rate your order", systemImage: "star.fill")
                                    .font(.caption)
                                    .padding()
                                    .background(Color.yellow.opacity(0.3))
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                Spacer()
                            }
                        } else {
                            // Deep Linking
                            HStack {
                                Link(destination: URL(string: "pizza://contact+TIM")!) {
                                     Label("Contact driver", systemImage: "phone.circle.fill")
                                        .font(.caption)
                                        .padding()
                                 }.background(Color.accentColor)
                                 .clipShape(RoundedRectangle(cornerRadius: 15))
                                Spacer()
                                Link(destination: URL(string: "pizza://cancelOrder")!) {
                                     Label("Cancel Order", systemImage: "xmark.circle.fill")
                                        .font(.caption)
                                        .padding()
                                 }.background(Color.red)
                                 .clipShape(RoundedRectangle(cornerRadius: 15))
                            }
                        }
                    }
                }
            } compactLeading: {
                timelineWrapped(context: context) {
                    if isDelivered(context) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    } else {
                        Label {
                            Text("\(context.attributes.numberOfPizzas) Pizza")
                        } icon: {
                            Image(systemName: "bag")
                        }
                        .font(.caption2)
                    }
                }
            } compactTrailing: {
                timelineWrapped(context: context) {
                    if isDelivered(context) {
                        Text("Done").font(.caption2).foregroundColor(.green)
                    } else {
                        Text(timerInterval: context.state.estimatedDeliveryTime, countsDown: true)
                            .multilineTextAlignment(.center)
                            .frame(width: 40)
                            .font(.caption2)
                    }
                }
            } minimal: {
                timelineWrapped(context: context) {
                    if isDelivered(context) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    } else {
                        VStack(alignment: .center) {
                            Image(systemName: "timer")
                            Text(timerInterval: context.state.estimatedDeliveryTime, countsDown: true)
                                .multilineTextAlignment(.center)
                                .monospacedDigit()
                                .font(.caption2)
                        }
                    }
                }
            }
            .keylineTint(.accentColor)
        }
    }
}

struct PizzaAdActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PizzaAdAttributes.self) { context in
            HStack {
                let logo = UserDefaults(suiteName: "group.io.startway.iOS16-Live-Activities")?.data(forKey: "pizzaLogo")
                if (logo != nil) {
                    Image(uiImage: UIImage(data: logo!)!)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .cornerRadius(15)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text(context.state.adName).font(.caption).foregroundColor(.secondary)
                    Text("Get \(Text(context.attributes.discount).fontWeight(.black).foregroundColor(.blue)) OFF").bold().font(.system(size: 25)).foregroundColor(.secondary)
                    Text("when purchase 🍕 every $500").font(.callout).italic().lineLimit(1)
                }.padding(.trailing)
            }.padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.discount, systemImage: "dollarsign.arrow.circlepath")
                        .font(.title2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Label {
                        Text("Ads")
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)
                            .monospacedDigit()
                            .font(.caption2)
                    } icon: {
                        Image(systemName: "dollarsign.circle.fill")
                    }
                    .font(.title2)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.adName)
                        .lineLimit(1)
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Button {
                        // Deep link into the app.
                    } label: {
                        Label("Pay now", systemImage: "creditcard")
                    }
                }
            } compactLeading: {
                Label {
                    Text(context.attributes.discount)
                } icon: {
                    Image(systemName: "dollarsign.circle.fill")
                }
                .font(.caption2)
                .foregroundColor(.red)
            } compactTrailing: {
                Text("Due")
                    .multilineTextAlignment(.center)
                    .frame(width: 40)
                    .font(.caption2)
            } minimal: {
                VStack(alignment: .center) {
                    Image(systemName: "dollarsign.circle.fill")
                    Text(context.attributes.discount)
                        .multilineTextAlignment(.center)
                        .monospacedDigit()
                        .font(.caption2)
                }
            }
            .keylineTint(.accentColor)
        }
    }
}

// Preview available on iOS 16.2 or above
@available(iOSApplicationExtension 16.2, *)
struct PizzaDeliveryActivityWidget_Previews: PreviewProvider {
    static let activityAttributes = PizzaDeliveryAttributes(numberOfPizzas: 2, totalAmount: "1000")
    static let activityState = PizzaDeliveryAttributes.ContentState(driverName: "Tim", estimatedDeliveryTime: Date()...Date().addingTimeInterval(15 * 60))
    
    static var previews: some View {
        activityAttributes
            .previewContext(activityState, viewKind: .content)
            .previewDisplayName("Notification")
        
        activityAttributes
            .previewContext(activityState, viewKind: .dynamicIsland(.compact))
            .previewDisplayName("Compact")
        
        activityAttributes
            .previewContext(activityState, viewKind: .dynamicIsland(.expanded))
            .previewDisplayName("Expanded")
        
        activityAttributes
            .previewContext(activityState, viewKind: .dynamicIsland(.minimal))
            .previewDisplayName("Minimal")
    }
}
