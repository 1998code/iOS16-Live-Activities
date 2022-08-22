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
        ActivityConfiguration(attributesType: PizzaDeliveryAttributes.self) { context in
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
                                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                    .frame(height: 6)
                            }
                            Text(context.state.estimatedDeliveryTime, style: .timer)
                            VStack {
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
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
}


struct PizzaAdActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(attributesType: PizzaAdAttributes.self) { context in
            VStack {
                Text("\(context.state.adName)").font(.caption).foregroundColor(.secondary)
                VStack {
                    Text("Get \(Text(context.attributes.discount).fontWeight(.black).foregroundColor(.blue)) OFF").bold().font(.system(size: 50)).foregroundColor(.secondary)
                    Text("when purchase 🍕 every $1,000 | ONLY TODAY").font(.callout).italic()
                }
            }.padding()
        }
    }
}


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
