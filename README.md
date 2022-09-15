<img width="64px" src="https://user-images.githubusercontent.com/54872601/181689472-8f443ca9-4fa0-418b-b0d3-e0730883889a.png" />

# iOS16 Live Activities + Dynmaic Island 🏝️
### SwiftPizza 🍕👨🏻‍🍳 App for Apple ActivityKit &amp; WidgetKit

This is the first project example referring to the latest <a href="https://developer.apple.com/news/?id=hi37aek8">Apple ActivityKit beta</a> and 
<a href="https://developer.apple.com/news/?id=ttuz9vwq">Dynamic Island (NEW)</a> release.

> Live Activities will help you follow an ongoing activity right from your Lock Screen, so you can track the progress of your food delivery or use the Now Playing controls without unlocking your device.

> Your app’s Live Activities display on the Lock Screen and in Dynamic Island — a new design that introduces an intuitive, delightful way to experience iPhone 14 Pro and iPhone 14 Pro Max.

## Preview
![CleanShot 2022-07-29 at 13 37 05](https://user-images.githubusercontent.com/54872601/181690034-bf5b5c58-16c2-45e7-8ef3-57899b0bf208.gif)

### More Videos
https://twitter.com/1998design/status/1552681295607566336?s=21&t=waceX8VvaP-VCGc2KJmHpw
https://twitter.com/1998design/status/1552686498276814848?s=21&t=waceX8VvaP-VCGc2KJmHpw

## Environment
- iOS 16 beta 4* ... iOS 16.1 beta 1
- Xcode 14 beta 4 ... Xcode 14.1 beta 1

<i>*Real Devices on iOS 16 beta 5-8, RC, GM will crash, please use simulators instead.</i>

## Tutorial
Medium: https://1998design.medium.com/how-to-create-live-activities-widget-for-ios-16-2c07889f1235

## Usage
### Info.plist
Add `NSSupportsLiveActivities` key and set to `YES`.
### Import
```swift
import ActivityKit
```
### Activity Attributes (Targeted to both App and Widget)
```swift
struct PizzaDeliveryAttributes: ActivityAttributes {
    public typealias PizzaDeliveryStatus = ContentState

    public struct ContentState: Codable, Hashable {
        var driverName: String
        var estimatedDeliveryTime: Date
    }

    var numberOfPizzas: Int
    var totalAmount: String
}
```
Gist: https://gist.github.com/1998code/c58a0e53ce1eae2ba5f0549ae6d9a370
### Functions (Start / Update / Stop / Show ALL)
```swift
func startDeliveryPizza() {
    let pizzaDeliveryAttributes = PizzaDeliveryAttributes(numberOfPizzas: 1, totalAmount:"$99")

    let initialContentState = PizzaDeliveryAttributes.PizzaDeliveryStatus(driverName: "TIM 👨🏻‍🍳", estimatedDeliveryTime: Date().addingTimeInterval(15 * 60))

    do {
        let deliveryActivity = try Activity<PizzaDeliveryAttributes>.request(
            attributes: pizzaDeliveryAttributes,
            contentState: initialContentState,
            pushType: nil)
        print("Requested a pizza delivery Live Activity \(deliveryActivity.id)")
    } catch (let error) {
        print("Error requesting pizza delivery Live Activity \(error.localizedDescription)")
    }
}

func updateDeliveryPizza() {
    Task {
        let updatedDeliveryStatus = PizzaDeliveryAttributes.PizzaDeliveryStatus(driverName: "TIM 👨🏻‍🍳", estimatedDeliveryTime: Date().addingTimeInterval(60 * 60))

        for activity in Activity<PizzaDeliveryAttributes>.activities{
            await activity.update(using: updatedDeliveryStatus)
        }
    }
}

func stopDeliveryPizza() {
    Task {
        for activity in Activity<PizzaDeliveryAttributes>.activities{
            await activity.end(dismissalPolicy: .immediate)
        }
    }
}

func showAllDeliveries() {
    Task {
        for activity in Activity<PizzaDeliveryAttributes>.activities {
            print("Pizza delivery details: \(activity.id) -> \(activity.attributes)")
        }
    }
}
```
Gist: https://gist.github.com/1998code/f32848acf22dc776b168f82cd68e8c61

### Widgets
```swift
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
```
Gist: https://gist.github.com/1998code/fea1227e866bc8c9a82ed1dc9654cdc3

## Responses
### Start Activity
```swift
Console: Requested a pizza delivery Live Activity DA288E1B-F6F5-4BF1-AA73-E43E0CC13150
```
### Show ALL Activities
```swift
Console: Pizza delivery details: DA288E1B-F6F5-4BF1-AA73-E43E0CC13150 -> PizzaDeliveryAttributes(numberOfPizzas: 1, totalAmount: "$99")
```

## Resources
https://developer.apple.com/documentation/activitykit/displaying-live-data-on-the-lock-screen-with-live-activities

## Legal
Swift® and SwiftUI® are trademarks of Apple Inc.
