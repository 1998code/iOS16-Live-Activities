//
//  ContentView.swift
//  iOS16-Live-Activities
//
//  Created by Ming on 28/7/2022.
//

import SwiftUI
import ActivityKit

struct ContentView: View {
    
    @State var startingEvent: Bool = false
    @State var showContactAction: Bool = false
    @State var driver: String = ""
    @State var showAlert: Bool = false
    @State var alertMsg: String = ""
    @State var hasActiveDelivery: Bool = false
    /// Which offline keep-alive strategy to use when starting a delivery.
    /// Wired to the segmented toggle below the main button.
    @State var selectedMethod: EndStateMethod = .keepAlive
    
    // MARK: - Layout
    var body: some View {
        NavigationStack {
            ZStack {
                bgImage
                actionButtons
            }
            .background(.black)
            .navigationTitle("SwiftPizza 🍕")
            .inlineLargeTitleIfAvailable()
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { startPizzaAd() }) {
                        Text("Get Promo")
                            .bold()
                            .font(.caption)
                    }.buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .tint(.red)
                }
            }
            .onOpenURL(perform: { url in
                withAnimation {
                    if url.absoluteString.contains("contact") {
                        driver = url.absoluteString.replacingOccurrences(of: "pizza://contact+", with: "")
                        showContactAction = true
                    } else if url.absoluteString.contains("cancelOrder") {
                        stopDeliveryPizza()
                    }
                }
            })
            .confirmationDialog("Call Driver", isPresented: $showContactAction) {
                Link("(800)442–4000", destination: URL(string: "tel:8004424000")!)
                Button("Cancel", role: .cancel) {
                    showContactAction = false
                }
            } message: {
                Text("Are you sure to call \(driver)?")
            }
            .alert(isPresented: $showAlert, content: {
                Alert(title: Text("Pizza Order Event"), message: Text(alertMsg), dismissButton: .default(Text("OK")))
            })
            .task {
                await observeDeliveryActivities()
            }
        }
    }

    /// Keeps `hasActiveDelivery` in sync with the real ActivityKit state so the
    /// Update/Cancel buttons only appear when there's an active delivery.
    @MainActor
    func observeDeliveryActivities() async {
        func refresh() {
            hasActiveDelivery = !Activity<PizzaDeliveryAttributes>.activities.isEmpty
        }

        // Initial value + listen for state changes on any already-running activity.
        refresh()
        for activity in Activity<PizzaDeliveryAttributes>.activities {
            Task { [activity] in
                for await _ in activity.activityStateUpdates {
                    await MainActor.run { refresh() }
                }
            }
        }

        // Listen for newly-started activities; attach a state observer to each.
        for await activity in Activity<PizzaDeliveryAttributes>.activityUpdates {
            refresh()
            Task { [activity] in
                for await _ in activity.activityStateUpdates {
                    await MainActor.run { refresh() }
                }
            }
        }
    }
    var bgImage: some View {
        AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1513104890138-7c749659a591?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=3540&q=80"))
        { image in
            image.resizable().scaledToFill()
        } placeholder: {
            ProgressView()
        }.frame(width: UIScreen.main.bounds.size.width)
        .ignoresSafeArea(.all)
    }
    var actionButtons: some View {
        VStack {
            Spacer()
            VStack(spacing:0) {
                if hasActiveDelivery {
                    Button(action: { showAllDeliveries() }) {
                        HStack {
                            Spacer()
                            Text("Show All Orders 🍕").font(.headline)
                            Spacer()
                        }.frame(height: 45)
                    }.tint(.brown)
                }

                HStack(spacing:0) {
                    Button(action: { startDeliveryPizza() }) {
                        HStack {
                            Spacer()
                            Text(startingEvent ? "Loading... 🍕" : "Start Ordering 👨🏻‍🍳").font(.headline)
                            Spacer()
                        }.frame(height: 45)
                    }.tint(.blue)
                    if hasActiveDelivery {
                        Button(action: { updateDeliveryPizza() }) {
                            HStack {
                                Spacer()
                                Text("Update Order 🫠").font(.headline)
                                Spacer()
                            }.frame(height: 45)
                        }.tint(.purple)
                    }
                }

                if hasActiveDelivery {
                    Button(action: { stopDeliveryPizza() }) {
                        HStack {
                            Spacer()
                            Text("Cancel Order 😞").font(.headline)
                            Spacer()
                        }.frame(height: 45)
                    }.tint(.pink)
                }
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle(radius: 0))
            .background(.thickMaterial)
            .cornerRadius(25)
            .padding(.horizontal,5)

            // Pick which offline keep-alive strategy the main button uses.
            // Both push `activity.update(finalContent)` at endDate; they only
            // differ in how the app stays runnable until then.
            methodToggle
                .padding(.horizontal, 5)
                .padding(.top, 6)
        }
    }

    /// Location [ toggle ] Sound — the active side bolds, the other fades.
    var methodToggle: some View {
        HStack(spacing: 12) {
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "location.fill")
                Text("Location")
            }
            .foregroundColor(selectedMethod == .keepAlive ? .orange : .secondary)
            .fontWeight(selectedMethod == .keepAlive ? .bold : .regular)

            Toggle("", isOn: Binding(
                get: { selectedMethod == .audio },
                set: { selectedMethod = $0 ? .audio : .keepAlive }
            ))
            .labelsHidden()

            HStack(spacing: 4) {
                Image(systemName: "speaker.wave.2.fill")
                Text("Sound")
            }
            .foregroundColor(selectedMethod == .audio ? .green : .secondary)
            .fontWeight(selectedMethod == .audio ? .bold : .regular)
            Spacer()
        }
        .font(.subheadline)
        .padding(.vertical, 8)
        .background(.thickMaterial)
        .cornerRadius(12)
    }

    // MARK: - Functions
    /// Offline end-state trigger strategies. Both keep the app runnable past
    /// iOS's ~7s Live Activity render freeze so we can call
    /// `activity.update(finalContent)` exactly at `endDate`.
    enum EndStateMethod: String {
        /// Significant-location-change subscription keeps the app alive.
        /// Natural fit for delivery / navigation apps.
        case keepAlive
        /// Silent `AVAudioSession .playback` keeps the app alive.
        /// Natural fit for timer / alarm / meditation apps (what Loop-style
        /// countdown apps are known to use).
        case audio
    }

    /// Short demo delivery using whichever strategy the toggle has selected.
    /// 15s is enough to observe Start → reassign-at-midpoint → delivered.
    func startDeliveryPizza() {
        startDelivery(duration: 15, method: selectedMethod)
    }

    /// Parameterised starter used by both the main button and the A/B test buttons.
    /// - Parameters:
    ///   - duration: seconds from now until `endDate`
    ///   - method: which end-state trigger strategy to exercise
    func startDelivery(duration: TimeInterval, method: EndStateMethod) {
        startingEvent = true

        print(ActivityAuthorizationInfo().areActivitiesEnabled)

        // Run the whole start flow as one ordered async block so the cleanup
        // (`.end`) is guaranteed to finish before we `.request` the new one.
        Task { @MainActor in
            // 1. Tear down any in-flight activity first — running A/B tests
            //    on top of each other leaks render budget and skews results.
            //    Also stop any lingering offline-method side channels.
            LocationKeepAlive.shared.stop()
            AudioKeepAlive.shared.stop()
            for activity in Activity<PizzaDeliveryAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }

            // 2. Build the new activity.
            let pizzaDeliveryAttributes = PizzaDeliveryAttributes(numberOfPizzas: 1, totalAmount: "$99")
            let endDate = Date().addingTimeInterval(duration)
            let initialContentState = PizzaDeliveryAttributes.PizzaDeliveryStatus(
                driverName: "Tim",
                estimatedDeliveryTime: Date()...endDate,
                method: method.rawValue
            )

            // No `staleDate` — the keep-alive side channel will push a real
            // `activity.update(finalContent)` at endDate, which is the only
            // thing that punches through the lock-screen render freeze.
            let initialContent = ActivityContent(state: initialContentState, staleDate: nil)

            // 3. Request it.
            do {
                let deliveryActivity = try Activity<PizzaDeliveryAttributes>.request(
                    attributes: pizzaDeliveryAttributes,
                    content: initialContent,
                    pushType: .token)

                print("Requested a pizza delivery Live Activity \(deliveryActivity.id) [\(method.rawValue), \(Int(duration))s]")

                // 4. Flip UI state IMMEDIATELY — the push token may arrive later
                //    (or never, if APNs isn't reachable) and we don't want the
                //    "Loading..." label stuck forever if that happens.
                alertMsg = "Started [\(method.rawValue.uppercased()) · \(Int(duration))s]\n\n\(deliveryActivity.id)"
                showAlert = true
                startingEvent = false

                // 5. Arm the end-state trigger side-channel for offline methods.
                //    Both keep-alive variants share the same payload: run a
                //    timer to `endDate`, then directly push the final
                //    ContentState — which is the only way to punch through
                //    the Live Activity lock-screen render freeze offline.
                //    We also fire at the midpoint to flip warehouse → ✓
                //    in the widget (TimelineView alone can't be trusted to
                //    re-render on the lock screen, so we push ourselves).
                let activityID = deliveryActivity.id

                // Look up the activity fresh at fire time — capturing
                // `deliveryActivity` and reading its `.content` can return a
                // stale snapshot, which would revert the widget to the initial
                // driverName.
                func currentActivity() -> Activity<PizzaDeliveryAttributes>? {
                    Activity<PizzaDeliveryAttributes>
                        .activities
                        .first(where: { $0.id == activityID })
                }

                // EndDate fire: just re-push the current state to force the
                // lock-screen widget to flip into its delivered layout.
                let pushSnapshot: () -> Void = {
                    Task {
                        guard let activity = currentActivity() else { return }
                        let content = ActivityContent(
                            state: activity.content.state,
                            staleDate: nil
                        )
                        await activity.update(content)
                    }
                }

                // Midpoint fire: auto-reassign Tim → John. This is what makes
                // the "Apple reassigned John ..." caption appear and the avatar
                // swap. If the user already manually reassigned via the Update
                // button, we respect their choice and just re-push so the
                // warehouse → ✓ icon flips.
                let reassignAtMidpoint: () -> Void = {
                    Task {
                        guard let activity = currentActivity() else { return }
                        let current = activity.content.state
                        let nextState: PizzaDeliveryAttributes.ContentState
                        if current.driverName == "Tim" {
                            nextState = PizzaDeliveryAttributes.ContentState(
                                driverName: "John",
                                estimatedDeliveryTime: current.estimatedDeliveryTime,
                                method: current.method
                            )
                        } else {
                            nextState = current
                        }
                        let content = ActivityContent(state: nextState, staleDate: nil)
                        await activity.update(content)
                    }
                }

                let midpoint = Date().addingTimeInterval(duration / 2)
                switch method {
                case .keepAlive:
                    LocationKeepAlive.shared.requestAuthorizationIfNeeded()
                    LocationKeepAlive.shared.start(
                        until: endDate,
                        midpoint: midpoint,
                        midpointFire: reassignAtMidpoint,
                        fire: pushSnapshot
                    )
                case .audio:
                    AudioKeepAlive.shared.start(
                        until: endDate,
                        midpoint: midpoint,
                        midpointFire: reassignAtMidpoint,
                        fire: pushSnapshot
                    )
                }

                // 6. Observe the push token in the background, purely for log
                //    / server dispatch purposes. No longer blocks the UI.
                Task {
                    for await pushToken in deliveryActivity.pushTokenUpdates {
                        let pushTokenString = pushToken.reduce("") { $0 + String(format: "%02x", $1) }
                        print("Push token for \(deliveryActivity.id): \(pushTokenString)")
                    }
                }
            } catch (let error) {
                print("Error requesting pizza delivery Live Activity \(error.localizedDescription)")
                alertMsg = "Error requesting pizza delivery Live Activity \(error.localizedDescription)"
                showAlert = true
                startingEvent = false
            }
        }
    }
    func updateDeliveryPizza() {
        Task {
            let newEndDate = Date().addingTimeInterval(60 * 60)
            let updatedDeliveryStatus = PizzaDeliveryAttributes.PizzaDeliveryStatus(driverName: "John", estimatedDeliveryTime: Date()...newEndDate)
            let updatedContent = ActivityContent(state: updatedDeliveryStatus, staleDate: newEndDate)

            for activity in Activity<PizzaDeliveryAttributes>.activities{
                await activity.update(updatedContent)
            }

            print("Updated pizza delivery Live Activity")
            
            showAlert = true
            alertMsg = "Updated pizza delivery Live Activity"
        }
    }
    func stopDeliveryPizza() {
        Task {
            // Cancel any offline side-channels we set up for this delivery.
            LocationKeepAlive.shared.stop()
            AudioKeepAlive.shared.stop()

            // Per Apple guidance: always pass a final `ContentState` when ending
            // a Live Activity. Between `end()` and the system actually removing
            // the activity from the Lock Screen, the widget may still be rendered
            // — so we want it to show a sensible "cancelled / delivered" layout,
            // not the stale in-flight state.
            for activity in Activity<PizzaDeliveryAttributes>.activities {
                // Collapse `estimatedDeliveryTime` to "now" so `isDelivered(context)`
                // evaluates true and the widget renders the ✓ end-state.
                let now = Date()
                let finalState = PizzaDeliveryAttributes.PizzaDeliveryStatus(
                    driverName: activity.content.state.driverName,
                    estimatedDeliveryTime: now...now,
                    method: activity.content.state.method
                )
                let finalContent = ActivityContent(state: finalState, staleDate: nil)
                // `.after(now + 4)` keeps the final frame on-screen briefly so the
                // user sees the transition instead of a pop-out. Swap to `.immediate`
                // for instant removal, or `.default` to let the system decide.
                await activity.end(finalContent, dismissalPolicy: .after(now.addingTimeInterval(4)))
            }

            print("Cancelled all pizza delivery Live Activity")

            showAlert = true
            alertMsg = "Cancelled pizza delivery Live Activity"
        }
    }
    func showAllDeliveries() {
        Task {
            var orders = ""
            for activity in Activity<PizzaDeliveryAttributes>.activities {
                print("Pizza delivery details: \(activity.id) -> \(activity.attributes)")
                orders.append("\n\(activity.id) -> \(activity.attributes)\n")
            }

            showAlert = true
            alertMsg = orders
        }
    }
    
    @MainActor
    func startPizzaAd() {
        guard let url = URL(string: "https://public.blob.vercel-storage.com/MtEBZ7HZoYddbIbI/pizza-logo-design_9845-319%20copy-MOQkaZcYx5TshHVlRvIZsvl1tyXBuT.jpg") else {
            print("Invalid image URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching image data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            guard let image = UIImage(data: data), let jpegData = image.jpegData(compressionQuality: 1.0) else {
                print("Error converting image data")
                return
            }
            
            UserDefaults(suiteName: "group.io.startway.iOS16-Live-Activities")?.set(jpegData, forKey: "pizzaLogo")

            let pizzaAdAttributes = PizzaAdAttributes(discount: "$100")
            let initialContentState = PizzaAdAttributes.PizzaAdStatus(adName: "TIM 👨🏻‍🍳 's Pizza Offer", showTime: Date().addingTimeInterval(60 * 60))
            do {
                let deliveryActivity = try Activity<PizzaAdAttributes>.request(
                    attributes: pizzaAdAttributes,
                    contentState: initialContentState,
                    pushType: .token)   // Enable Push Notification Capability First (from pushType: nil)
                print("Requested a pizza ad Live Activity \(deliveryActivity.id)")
                alertMsg = "Requested a pizza ad Live Activity \(deliveryActivity.id)"
                showAlert = true
            } catch (let error) {
                print("Error requesting pizza ad Live Activity \(error.localizedDescription)")
                alertMsg = "Error requesting pizza ad Live Activity \(error.localizedDescription)"
                showAlert = true
            }
        }
        
        task.resume()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

private extension View {
    /// Applies `.toolbarTitleDisplayMode(.inlineLarge)` on iOS 17.1+ and
    /// leaves the view untouched on earlier versions — `inlineLarge` isn't
    /// available on iOS 16 / 17.0 so we can't just call the modifier.
    @ViewBuilder
    func inlineLargeTitleIfAvailable() -> some View {
        if #available(iOS 17.1, *) {
            self.toolbarTitleDisplayMode(.inlineLarge)
        } else {
            self
        }
    }
}
