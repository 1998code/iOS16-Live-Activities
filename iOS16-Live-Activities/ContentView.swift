//
//  ContentView.swift
//  iOS16-Live-Activities
//
//  Created by Ming on 28/7/2022.
//

import SwiftUI
import ActivityKit

struct ContentView: View {
    
    @State var showDeepLinkAction: Bool = false
    @State var driver: String = ""
    @State var showAlert: Bool = false
    @State var alertMsg: String = ""
    
    // MARK: - Layout
    var body: some View {
        NavigationView {
            ZStack {
                bgImage
                actionButtons
            }
            .navigationTitle("SwiftPizza 🍕")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Text("For  Developers")
                        .bold()
                }
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
            .preferredColorScheme(.dark)
            .onOpenURL(perform: { url in
                // MARK: Handle Widgets
                driver = url.absoluteString.replacingOccurrences(of: "pizza://", with: "")
                showDeepLinkAction = true
            })
            .confirmationDialog("Call Driver", isPresented: $showDeepLinkAction)
            {
                Link("(800)442–4000", destination: URL(string: "tel:8004424000")!)
                Button("Cancel", role: .cancel) {
                    showDeepLinkAction = false
                }
            } message: {
                Text("Are you sure to call \(driver)?")
            }
            .alert(isPresented: $showAlert, content: {
                Alert(title: Text("Pizza Order Event"), message: Text(alertMsg), dismissButton: .default(Text("OK")))
            })
        }
    }
    var bgImage: some View {
        AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1513104890138-7c749659a591?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=3540&q=80"))
        { image in
            image.resizable().scaledToFill()
        } placeholder: {
            ProgressView()
        }.ignoresSafeArea(.all)
    }
    var actionButtons: some View {
        VStack(spacing:0) {
            Spacer()
            
            Button(action: { showAllDeliveries() }) {
                HStack {
                    Spacer()
                    Text("Show All Orders 🍕").font(.headline)
                    Spacer()
                }.frame(height: 50)
            }.tint(.brown)
            
            HStack(spacing:0) {
                Button(action: { startDeliveryPizza() }) {
                    HStack {
                        Spacer()
                        Text("Start Ordering 👨🏻‍🍳").font(.headline)
                        Spacer()
                    }.frame(height: 50)
                }.tint(.blue)
                Button(action: { updateDeliveryPizza() }) {
                    HStack {
                        Spacer()
                        Text("Update Order 🫠").font(.headline)
                        Spacer()
                    }.frame(height: 50)
                }.tint(.purple)
            }.frame(maxWidth: UIScreen.main.bounds.size.width)
            
            Button(action: { stopDeliveryPizza() }) {
                HStack {
                    Spacer()
                    Text("Cancel Order 😞").font(.headline)
                    Spacer()
                }.frame(height: 50)
                .padding(.bottom)
            }.tint(.pink)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: 0))
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Functions
    func startDeliveryPizza() {
        let pizzaDeliveryAttributes = PizzaDeliveryAttributes(numberOfPizzas: 1, totalAmount:"$99")

        let initialContentState = PizzaDeliveryAttributes.PizzaDeliveryStatus(driverName: "TIM 👨🏻‍🍳", estimatedDeliveryTime: Date()...Date().addingTimeInterval(15 * 60))
                                                  
        do {
            let deliveryActivity = try Activity<PizzaDeliveryAttributes>.request(
                attributes: pizzaDeliveryAttributes,
                contentState: initialContentState,
                pushType: nil)
            
            print("Requested a pizza delivery Live Activity \(deliveryActivity.id)")
            
            showAlert = true
            alertMsg = "Requested a pizza delivery Live Activity \(deliveryActivity.id)"
            
        } catch (let error) {
            print("Error requesting pizza delivery Live Activity \(error.localizedDescription)")
        }
    }
    func updateDeliveryPizza() {
        Task {
            let updatedDeliveryStatus = PizzaDeliveryAttributes.PizzaDeliveryStatus(driverName: "TIM 👨🏻‍🍳", estimatedDeliveryTime: Date()...Date().addingTimeInterval(60 * 60))
            
            for activity in Activity<PizzaDeliveryAttributes>.activities{
                await activity.update(using: updatedDeliveryStatus)
            }

            print("Updated pizza delivery Live Activity")
            
            showAlert = true
            alertMsg = "Updated pizza delivery Live Activity"
        }
    }
    func stopDeliveryPizza() {
        Task {
            for activity in Activity<PizzaDeliveryAttributes>.activities{
                await activity.end(dismissalPolicy: .immediate)
            }

            print("Cancelled pizza delivery Live Activity")

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
                    pushType: nil)
                print("Requested a pizza ad Live Activity \(deliveryActivity.id)")
            } catch (let error) {
                print("Error requesting pizza ad Live Activity \(error.localizedDescription)")
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
