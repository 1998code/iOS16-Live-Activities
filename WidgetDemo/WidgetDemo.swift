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
//       PizzaAdActivityWidget()
   }
}

struct PizzaDeliveryActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PizzaDeliveryAttributes.self) { context in
            // Create the view that appears on the Lock Screen and as a banner on the Home Screen of devices that don't support the Dynamic Island.
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("\(context.attributes.numberOfPizzas) Pizzas", systemImage: "bag")
                        .font(.title2)
                }
                DynamicIslandExpandedRegion(.trailing) {
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
                DynamicIslandExpandedRegion(.center) {
                    Text("\(context.state.driverName) is on his way!")
                        .lineLimit(1)
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Button {
                        // Deep link into the app.
                    } label: {
                        Label("Contact driver", systemImage: "phone")
                    }
                }
            } compactLeading: {
                Label {
                    Text("\(context.attributes.numberOfPizzas) Pizzas")
                } icon: {
                    Image(systemName: "bag")
                }
                .font(.caption2)
            } compactTrailing: {
                Text(timerInterval: context.state.estimatedDeliveryTime, countsDown: true)
                    .multilineTextAlignment(.center)
                    .frame(width: 40)
                    .font(.caption2)
            } minimal: {
                VStack(alignment: .center) {
                    Image(systemName: "timer")
                    Text(timerInterval: context.state.estimatedDeliveryTime, countsDown: true)
                        .multilineTextAlignment(.center)
                        .monospacedDigit()
                        .font(.caption2)
                }
            }
            .keylineTint(.cyan)
        }
    }
}

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<PizzaDeliveryAttributes>
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(context.state.driverName) is on the way!").font(.headline)
                    HStack {
                        VStack {
                            Divider().frame(height: 6).overlay(.blue).cornerRadius(5)
                        }
                        Image(systemName: "box.truck.badge.clock.fill").foregroundColor(.blue)
                        VStack {
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(.secondary, style: StrokeStyle(lineWidth: 1, dash: [5]))
                                .frame(height: 6)
                        }
                        Text(timerInterval: context.state.estimatedDeliveryTime, countsDown: true)
                        VStack {
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(.secondary, style: StrokeStyle(lineWidth: 1, dash: [5]))
                                .frame(height: 6)
                        }
                        Image(systemName: "house.fill").foregroundColor(.green)
                    }
                }.padding(.trailing, 25)
                Text("\(context.attributes.numberOfPizzas) 🍕").font(.title).bold()
            }.padding(5)
            Text("You've already paid: \(context.attributes.totalAmount) + $9.9 Delivery Fee 💸").font(.caption).foregroundColor(.secondary)
        }.padding(15)
    }
}

//struct PizzaAdActivityWidget: Widget {
//    var body: some WidgetConfiguration {
//        ActivityConfiguration(attributesType: PizzaAdAttributes.self) { context in
//            VStack {
//                Text("\(context.state.adName)").font(.caption).foregroundColor(.secondary)
//                VStack {
//                    Text("Get \(Text(context.attributes.discount).fontWeight(.black).foregroundColor(.blue)) OFF").bold().font(.system(size: 50)).foregroundColor(.secondary)
//                    Text("when purchase 🍕 every $1,000 | ONLY TODAY").font(.callout).italic()
//                }
//            }.padding()
//        }
//    }
//}


//struct DemoWidget: View {
//    var body: some View {
//        VStack {
//            Text("Push Ads Demo").font(.caption).foregroundColor(.secondary)
//            VStack {
//                Text("Get $100 OFF").bold().font(.system(size: 50)).foregroundColor(.secondary)
//                Text("when purchase 🍕 every $1,000 | ONLY TODAY").font(.caption).italic()
//            }
//        }
//    }
//}
//
//struct PizzaAdActivityWidget_Previews: PreviewProvider {
//    static var previews: some View {
//        DemoWidget()
//            .previewContext(WidgetPreviewContext(family: .systemMedium))
//    }
//}
