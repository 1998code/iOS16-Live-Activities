<img width="64px" src="https://user-images.githubusercontent.com/54872601/181689472-8f443ca9-4fa0-418b-b0d3-e0730883889a.png" />

# Apple Live Activities + Dynamic Island 🏝️ (Since iOS16)
### SwiftPizza 🍕👨🏻‍🍳 App for Apple ActivityKit &amp; WidgetKit

This is the first project example referring to the latest <a href="https://developer.apple.com/news/?id=hi37aek8">Apple ActivityKit beta</a> and 
<a href="https://developer.apple.com/news/?id=ttuz9vwq">Dynamic Island (NEW)</a> release.

> Live Activities will help you follow an ongoing activity right from your Lock Screen, so you can track the progress of your food delivery or use the Now Playing controls without unlocking your device.

> Your app’s Live Activities display on the Lock Screen and in Dynamic Island — a new design that introduces an intuitive, delightful way to experience iPhone 14 Pro and iPhone 14 Pro Max.

## Preview 📱
<img width="1080" height="810" alt="Demo" src="https://github.com/user-attachments/assets/d2884598-5270-4c3a-a795-7fdf8f42093b" />

<img width="350px" src="https://user-images.githubusercontent.com/54872601/181690034-bf5b5c58-16c2-45e7-8ef3-57899b0bf208.gif" /> <img width="350px" src="https://user-images.githubusercontent.com/54872601/190294592-0e019d65-0b37-4636-a8af-49a49cc3657b.gif" />

## Environment 🔨
- iOS 16.1 or above
- Xcode 14.1 or above

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
            .keylineTint(.accentColor)
    }
}
```

### Xcode Preview (iOS 16.2 or above)
```swift
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
```

## Offline End-State & Midpoint Flips 🔋

Live Activity widgets on the Lock Screen are **snapshot-rendered** with a strict render budget. Two side effects matter here:

1. `TimelineView(.explicit([...]))` / `.periodic(...)` inside the content closure is **unreliable** — iOS throttles / drops scheduled snapshots once the phone is locked or the app is backgrounded. `Text(timerInterval:)` and `ProgressView(timerInterval:)` with `.linear` are the **only** primitives iOS interpolates frame-to-frame; everything else is a static snapshot until the next `activity.update()` / push.
2. `staleDate` alone cannot flip the widget to its "done" layout at an exact time offline. Without a real push, the snapshot taken around `staleDate` can lag by multiple seconds.

To flip a Live Activity to its end state **offline, at the exact time, with no APNs push**, this project ships two app-side keep-alive strategies that keep the app runnable in the background long enough to fire `activity.update(finalContent)` precisely at `endDate`:

| Strategy            | Mechanism                                                             | Natural fit                       |
| ------------------- | --------------------------------------------------------------------- | --------------------------------- |
| `LocationKeepAlive` | `CLLocationManager.startMonitoringSignificantLocationChanges()`       | Delivery / navigation apps        |
| `AudioKeepAlive`    | Silent PCM WAV looped on `AVAudioSession(.playback, .mixWithOthers)`  | Timer / meditation / workout apps |

Both run a `DispatchSourceTimer` to `endDate`, then call `activity.update(finalContent)`. The UI toggle (`Location [ ⇆ ] Sound`) in `ContentView` picks which side-channel starts for each delivery.

**Required capabilities** (both added to `Info.plist`):
```xml
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>audio</string>
</array>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Track your driver in the background so the Live Activity stays fresh.</string>
```

### Midpoint re-render push

Because `TimelineView` is unreliable on the lock screen, any **discrete in-progress state change** (e.g. warehouse icon → ✓ when the fill sweeps past the midpoint marker) also needs a keep-alive-driven push. The same `DispatchSourceTimer` pattern fires a second time at `startDate + duration/2`, re-pushing the current state just to force a snapshot — the widget body then re-evaluates `Date() >= midpoint` and flips the icon:

```swift
LocationKeepAlive.shared.start(
    until: endDate,
    midpoint: Date().addingTimeInterval(duration / 2),
    midpointFire: pushSnapshot,   // flips warehouse → ✓
    fire: pushSnapshot            // flips bar → delivered layout
)
```

## Progress Bar Design 🚚

The lock-screen notification bar renders a 3-stop delivery journey:

```
[📦 package]──[⏱ timer  🏢 warehouse]──[🏠 home]
```

- **Track**: full-width `Capsule()` in gray.
- **Fill**: `ProgressView(timerInterval:)` with `.linear` style and a `LinearGradient(colors: [.blue, .green])` tint — the **only** way to get a frame-by-frame smooth fill inside a Live Activity. `scaleEffect(x: 1, y: 7)` fattens the ~4pt system bar to 28pt; `clipShape(Capsule())` keeps the leading edge vertical.
- **Icons**: package (left), warehouse (center, dead-centered via a `HStack(spacing: 0)` split into two `maxWidth: .infinity` halves with the warehouse icon as the seam), home (right). Timer text sits on the left of the warehouse inside the left half.
- **Midpoint flip**: warehouse 🏢 → ✓ via the midpoint keep-alive push.
- **End state**: the same bar, fully filled `LinearGradient`, with a single ✓ parked at the right — reached via the final keep-alive push at `endDate`. Bottom paid-footer text stays so the widget doesn't change height between in-progress / delivered.

## Responses
### Start Activity
```swift
Console: Requested a pizza delivery Live Activity DA288E1B-F6F5-4BF1-AA73-E43E0CC13150
```
### Update Activity
```swift
Updating content state for activity DA288E1B-F6F5-4BF1-AA73-E43E0CC13150
```
### Show ALL Activities
```swift
Console: Pizza delivery details: DA288E1B-F6F5-4BF1-AA73-E43E0CC13150 -> PizzaDeliveryAttributes(numberOfPizzas: 1, totalAmount: "$99")
```

## How to pass image data to the widget?
Q1. Can I use Local Assets Folder?<br />
A1. YES.<br />
    ✅ Easy to implement <br/>
    ✅ May possible to change image (string name) when updating the event<br/>
    ❎ Limited options and big app size.<br/>
            If you need to add more image sets, then re-upload to App Store is required (Time wasting, and not all users can get the instant update)
<br/><br/>
Q2. Can I use Network Image?<br />
A2. YES. Load the image from the Internet, and pass the data to the widget via App Group and AppStorage (aka UserDefaults)<br/>
    ✅ Update in any time as the url can be changed / modify remotely.<br/>
    ✅ No need to store in Assets Folder and reduced app size.<br/>
    ❎ Unless the user re-open the app, the image cannot be updated in the background.
<br /><br />
Q3. How about AsyncImage?<br />
A3. NO. (Known not working)

Both cases 1 & 2 are already demoed in the sample project.

## Structure
![diagram](https://raw.githubusercontent.com/1998code/iOS16-Live-Activities/main/diagram.svg)

## Resources 🐋
https://developer.apple.com/documentation/activitykit/displaying-live-data-on-the-lock-screen-with-live-activities

## Legal 😄
Swift® and SwiftUI® are trademarks of Apple Inc.

## Supported By
<a href="https://m.do.co/c/ce873177d9ab">
    <img src="https://opensource.nyc3.cdn.digitaloceanspaces.com/attribution/assets/SVG/DO_Logo_horizontal_blue.svg" width="201px">
</a>
