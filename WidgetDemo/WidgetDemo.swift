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

struct PizzaDeliveryActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PizzaDeliveryAttributes.self) { context in
            // For devices that don't support the Dynamic Island.
            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Your \(context.state.driverName) is on the way!")
                            .font(.headline)
                        ZStack {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(.secondary)
                            HStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(.blue)
                                    .frame(width: 50)
                                Image(systemName: "shippingbox.circle.fill")
                                    .foregroundColor(.white)
                                    .padding(.leading, -25)
                                Image(systemName: "arrow.forward")
                                    .foregroundColor(.white.opacity(0.5))
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.white.opacity(0.5))
                                Text(timerInterval: (Date.init(timeIntervalSince1970: context.attributes.orderTime))...(Date.init(timeIntervalSince1970: context.state.estimatedDeliveryTime)), countsDown: true)
                                    .bold()
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.white.opacity(0.5))
                                Image(systemName: "arrow.forward")
                                    .foregroundColor(.white.opacity(0.5))
                                Image(systemName: "house.circle.fill")
                                    .foregroundColor(.green)
                                    .background(.white)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    Spacer()
                    VStack {
                        Text("\(context.attributes.numberOfPizzas) 🍕")
                            .font(.title)
                            .bold()
                        Spacer()
                    }
                }.padding(5)
                Text("You've already paid: \(context.attributes.totalAmount) + $9.9 Delivery Fee 💸")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 5)
            }.padding(15)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("\(context.attributes.numberOfPizzas) Pizzas", systemImage: "bag")
                        .font(.title2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Label {
                        Text(timerInterval: (Date.init(timeIntervalSince1970: context.attributes.orderTime))...(Date.init(timeIntervalSince1970: context.state.estimatedDeliveryTime)), countsDown: true)
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
                    Text("\(context.state.driverName) is on the way!")
                        .lineLimit(1)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    // Deep Linking test
                     Link(destination: URL(string: "pizza://TIM")!) {
                         Label("Contact driver", systemImage: "phone").padding()
                     }.background(Color.accentColor)
                     .clipShape(RoundedRectangle(cornerRadius: 15))
                }
            } compactLeading: {
                Label {
                    Text("\(context.attributes.numberOfPizzas) Pizzas")
                } icon: {
                    Image(systemName: "bag")
                }
                .font(.caption2)
            } compactTrailing: {
                Text(timerInterval: (Date.init(timeIntervalSince1970: context.attributes.orderTime))...(Date.init(timeIntervalSince1970: context.state.estimatedDeliveryTime)), countsDown: true)
                    .multilineTextAlignment(.center)
                    .frame(width: 40)
                    .font(.caption2)
            } minimal: {
                VStack(alignment: .center) {
                    Image(systemName: "timer")
                    Text(timerInterval: (Date.init(timeIntervalSince1970: context.attributes.orderTime))...(Date.init(timeIntervalSince1970: context.state.estimatedDeliveryTime)), countsDown: true)
                        .multilineTextAlignment(.center)
                        .monospacedDigit()
                        .font(.caption2)
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
                VStack(alignment: .leading) {
                    Text(context.state.adName).font(.caption).foregroundColor(.secondary)
                    Text("Get \(Text(context.attributes.discount).fontWeight(.black).foregroundColor(.blue)) OFF").bold().font(.system(size: 25)).foregroundColor(.secondary)
                    Text("when purchase 🍕 every $1,000 TODAY").font(.callout).italic()
                }
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

// If you wish to preview the widget:
struct DemoWidget: View {
    var body: some View {
        VStack {
            Text("Push Ads Demo").font(.caption).foregroundColor(.secondary)
            VStack {
                Text("Get $100 OFF").bold().font(.system(size: 50)).foregroundColor(.secondary)
                Text("when purchase 🍕 every $1,000 | ONLY TODAY").font(.caption).italic()
            }
        }
    }
}

struct PizzaAdActivityWidget_Previews: PreviewProvider {
    static var previews: some View {
        DemoWidget()
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
