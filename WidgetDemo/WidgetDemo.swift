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
