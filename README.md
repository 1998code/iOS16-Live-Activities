<img width="64px" src="https://user-images.githubusercontent.com/54872601/181689472-8f443ca9-4fa0-418b-b0d3-e0730883889a.png" />

# iOS16 Live Activities + Dynamic Island 🏝️
### SwiftPizza 🍕👨🏻‍🍳 App for Apple ActivityKit &amp; WidgetKit

This is the first project example referring to the latest <a href="https://developer.apple.com/news/?id=hi37aek8">Apple ActivityKit beta</a> and 
<a href="https://developer.apple.com/news/?id=ttuz9vwq">Dynamic Island (NEW)</a> release.

> Live Activities will help you follow an ongoing activity right from your Lock Screen, so you can track the progress of your food delivery or use the Now Playing controls without unlocking your device.

> Your app’s Live Activities display on the Lock Screen and in Dynamic Island — a new design that introduces an intuitive, delightful way to experience iPhone 14 Pro and iPhone 14 Pro Max.

## Preview 📱
<img width="400px" src="https://user-images.githubusercontent.com/54872601/181690034-bf5b5c58-16c2-45e7-8ef3-57899b0bf208.gif" /> <img width="400px" src="https://user-images.githubusercontent.com/54872601/190294592-0e019d65-0b37-4636-a8af-49a49cc3657b.gif" />


### More Videos 📼
https://twitter.com/1998design/status/1552681295607566336?s=21&t=waceX8VvaP-VCGc2KJmHpw
https://twitter.com/1998design/status/1552686498276814848?s=21&t=waceX8VvaP-VCGc2KJmHpw
https://twitter.com/1998design/status/1570225193095933952?s=21&t=LoYk1Llj0cLpEhG0MBFZLw

## Environment 🔨
- iOS 16.1 beta 1
- Xcode 14.1 beta 1

## Tutorial 🤔
Dynamic Island: https://1998design.medium.com/how-to-create-dynamic-island-widgets-on-ios-16-1-or-above-dca0a7dd1483 <br/>
Live Activities: https://1998design.medium.com/how-to-create-live-activities-widget-for-ios-16-2c07889f1235

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
        // Changed from Date to ClosedRange<Date> - 16.1
        var estimatedDeliveryTime: ClosedRange<Date>
    }

    var numberOfPizzas: Int
    var totalAmount: String
}
```

### CRUD Functions (Start / Update / Stop / Show ALL)
```swift
func startDeliveryPizza() {
    let pizzaDeliveryAttributes = PizzaDeliveryAttributes(numberOfPizzas: 1, totalAmount:"$99")
    // Date() changed to Date()...Date() - 16.1
    let initialContentState = PizzaDeliveryAttributes.PizzaDeliveryStatus(driverName: "TIM 👨🏻‍🍳", estimatedDeliveryTime: Date()...Date().addingTimeInterval(15 * 60))

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
        // Date() changed to Date()...Date() - 16.1
        let updatedDeliveryStatus = PizzaDeliveryAttributes.PizzaDeliveryStatus(driverName: "TIM 👨🏻‍🍳", estimatedDeliveryTime: Date()...Date().addingTimeInterval(60 * 60))

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
        // attributesType changed to for - 16.1
        ActivityConfiguration(for: PizzaDeliveryAttributes.self) { context in
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
        // NEW 16.1
        dynamicIsland: { context in
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
```

## Responses
### Start Activity
```swift
Console: Requested a pizza delivery Live Activity DA288E1B-F6F5-4BF1-AA73-E43E0CC13150
```
### Show ALL Activities
```swift
Console: Pizza delivery details: DA288E1B-F6F5-4BF1-AA73-E43E0CC13150 -> PizzaDeliveryAttributes(numberOfPizzas: 1, totalAmount: "$99")
```

## How to pass image data to the widget
1. YES. Use Local Assets Folder <br/>
    a. Advantage: Easy to implement <br/>
       May possible to change image (string name) when updating the event<br/>
    b. Bad: Limited options and big app size.<br/>
            If you need to add more image sets, then re-upload to App Store is required (Time wasting, and not all users can get the instant update)<br/>
2. YES. Load the image from the Internet, and pass the data to the widget via App Group and AppStorage (aka UserDefaults)<br/>
    a. Advantage: Can update in any time as the url can be changed / modify remotely.<br/>
       No need to store in Assets Folder and reduced app size.<br/>
    b. Limitation: Unless the user re-open the app, the image cannot be updated in the background.
3. NO. Async Image (Known not working)

Both cases 1 & 2 are already demoed on the sample project.

## Resources 🐋
https://developer.apple.com/documentation/activitykit/displaying-live-data-on-the-lock-screen-with-live-activities

## Legal 😄
Swift® and SwiftUI® are trademarks of Apple Inc.
