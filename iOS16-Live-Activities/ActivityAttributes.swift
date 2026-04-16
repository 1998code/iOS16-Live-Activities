//
//  PizzaDeliveryAttributes.swift
//  iOS16-Live-Activities
//
//  Created by Ming on 29/7/2022.
//

import SwiftUI
import ActivityKit

struct PizzaDeliveryAttributes: ActivityAttributes {
    public typealias PizzaDeliveryStatus = ContentState

    public struct ContentState: Codable, Hashable {
        var driverName: String
        var estimatedDeliveryTime: ClosedRange<Date>
        /// Which end-state trigger method this activity is exercising.
        /// Values: "stale", "timeline", "both". Used by the widget to decide
        /// whether to wrap its body in `TimelineView(.explicit([endDate]))`.
        var method: String = "stale"
    }

    var numberOfPizzas: Int
    var totalAmount: String
}

struct PizzaAdAttributes: ActivityAttributes {
    public typealias PizzaAdStatus = ContentState

    public struct ContentState: Codable, Hashable {
        var adName: String
        var showTime: Date
    }
    var discount: String
}
