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
    let initialContentState = PizzaDeliveryAttributes.PizzaDeliveryStatus(driverName: "Tim", estimatedDeliveryTime: Date()...Date().addingTimeInterval(15 * 60))

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
        // Demo reassignment: swap Tim → John mid-flight. The widget reads the
        // avatar via `Image(context.state.driverName)`, so changing the name
        // automatically swaps the rendered image set.
        let updatedDeliveryStatus = PizzaDeliveryAttributes.PizzaDeliveryStatus(driverName: "John", estimatedDeliveryTime: Date()...Date().addingTimeInterval(60 * 60))

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

Because `TimelineView` is unreliable on the lock screen, any **discrete in-progress state change** (e.g. warehouse icon → ✓ when the fill sweeps past the midpoint marker) also needs a keep-alive-driven push. The same `DispatchSourceTimer` pattern fires a second time at `startDate + duration/2`. Two patterns fit naturally on this midpoint fire:

1. **Force a snapshot only.** Re-push the activity's current state — the widget body re-evaluates `Date() >= midpoint` and flips the icon. Use this when nothing in `ContentState` actually needs to change.
2. **Mutate state at the midpoint.** Push a *modified* `ContentState` that reflects an in-progress event (e.g. driver reassignment). The demo in this project takes this path: at midpoint it swaps `driverName` from `"Tim"` to `"John"`, which simultaneously flips the warehouse → ✓ icon, swaps the avatar via `Image(context.state.driverName)`, and triggers the conditional "Apple reassigned …" caption — all from a single midpoint push.

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

## Sharing Images Across App, Widget & Live Activity 🖼️

The main app, widget extension, and Live Activity are **three separate targets** with three separate bundles. An asset added to one target is **not** automatically visible to the others, and a widget extension cannot make network requests of its own. Pick the strategy that matches where your images come from.

### Demo in this project

The driver avatar shown next to the delivery bar (`John`) is loaded with `Image(context.state.driverName)` in [`WidgetDemo.swift`](WidgetDemo/WidgetDemo.swift). The asset name is driven by the `driverName` value passed in `ContentState`, so changing the driver in the main app automatically swaps the avatar — provided a matching image set exists in the widget's bundle.

This project follows **Case 1 → Option A** below: the avatars (`Tim`, `John`) live in a shared catalog at [`Resources/Assets.xcassets`](Resources/Assets.xcassets) with **target membership ticked on both `iOS16-Live-Activities` and `WidgetDemo`**, so the same image set is reachable from the app, the widget, and the Live Activity without duplication on disk.

---

### Case 1 — Bundled images (shipped with the app)

Best for: a known, finite set of images (logos, badges, demo avatars, fixed driver roster).

**Option A — Multi-target asset catalog (quickest)**

1. Add the image set to *one* `Assets.xcassets`.
2. Select the image set → **File Inspector → Target Membership** → tick **both** the app target and the widget extension.
3. Reference it as usual: `Image("John")`.

> ⚠️ Each ticked target gets its own copy of the image baked into its bundle, so app size grows roughly linearly with the number of targets sharing the asset.

**Option B — Shared Swift Package (cleanest)**

1. Create a local Swift Package (e.g. `SharedAssets`) with its own `Assets.xcassets`.
2. Add the package as a dependency of every target that needs the image.
3. Reference it with the package's bundle:
   ```swift
   Image("John", bundle: .module)
   ```
4. Result: one copy of the asset for the whole app — smaller binary, single source of truth.

| | Multi-target catalog | Swift Package |
| --- | --- | --- |
| Setup | 30 seconds | A few minutes |
| Storage | Duplicated per target | Single copy |
| Asset name in code | `Image("John")` | `Image("John", bundle: .module)` |

---

### Case 2 — Downloaded images (fetched at runtime)

Best for: user-generated content, unbounded sets (real driver photos, dynamic product imagery), anything that must change without an App Store release.

Widget extensions and Live Activities **cannot perform network calls** during snapshot rendering, and `ActivityKit` `ContentState` payloads are capped at roughly 4 KB — so you cannot ship the image bytes inside the state. The pattern is: **the main app downloads, writes to a shared container, and the widget reads from disk.**

**1. Enable App Groups on both targets**

Xcode → *Signing & Capabilities* → add **App Groups** to the main app **and** the widget extension, both using the same identifier (e.g. `group.com.you.pizza`).

**2. Main app — download and persist**

```swift
let groupID = "group.com.you.pizza"
let container = FileManager.default
    .containerURL(forSecurityApplicationGroupIdentifier: groupID)!

func cacheAvatar(for driverID: String, from url: URL) async throws {
    let (data, _) = try await URLSession.shared.data(from: url)
    let dest = container.appendingPathComponent("\(driverID).png")
    try data.write(to: dest, options: .atomic)
}
```

**3. Activity state — pass an identifier, not the image bytes**

```swift
struct DeliveryAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var driverID: String   // e.g. "john_123" — NOT the image data
        var estimatedDeliveryTime: ClosedRange<Date>
    }
}
```

**4. Widget — load from the shared container**

```swift
private func avatar(for driverID: String) -> Image {
    let url = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: "group.com.you.pizza")!
        .appendingPathComponent("\(driverID).png")
    if let ui = UIImage(contentsOfFile: url.path) {
        return Image(uiImage: ui)
    }
    return Image(systemName: "person.crop.circle")   // graceful fallback
}
```

**Important caveats**

- The widget cannot trigger the download itself. Make sure the main app prefetches the image **before** calling `activity.request(...)` / `activity.update(...)`, otherwise the first snapshot will render the fallback.
- `AsyncImage` does **not** work inside Live Activity / widget snapshots — there is no async render pass. Always pre-write to disk and read synchronously.
- Keep cached images small (a few hundred KB max). Widget extensions have a tight memory budget — a giant image will cause the snapshot to be killed.
- If the user wipes the app data or the cache is evicted, fall back to a `systemName` placeholder rather than crashing.

### Quick chooser

| Image source | Pick |
| --- | --- |
| Static, known at build time | **Case 1** (Swift Package preferred) |
| Server-driven, per-user, or updated post-release | **Case 2** (App Group + shared container) |
| Mixed — a few branded fallbacks plus dynamic content | Combine both: bundle the fallbacks via Case 1, cache the dynamic ones via Case 2 |

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
