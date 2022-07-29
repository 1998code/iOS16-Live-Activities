//
//  ContentView.swift
//  iOS16-Live-Activities
//
//  Created by Ming on 28/7/2022.
//

import SwiftUI
import ActivityKit

struct ContentView: View {
    
    // MARK: - Layout
    var body: some View {
        NavigationView {
            ZStack {
                bgImage
                actionButtons
            }
            .onTapGesture {
                showAllDeliveries()
            }
            .navigationTitle("SwiftPizza 🍕")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Text("For Apple Developers").bold()
                }
            }
            .preferredColorScheme(.dark)
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
            
            HStack(spacing:0) {
                Button(action: { startDeliveryPizza() }) {
                    HStack {
                        Spacer()
                        Text("Start Ordering 👨🏻‍🍳").font(.headline)
                        Spacer()
                    }.frame(height: 60)
                }.tint(.blue)
                Button(action: { updateDeliveryPizza() }) {
                    HStack {
                        Spacer()
                        Text("Update Order 🫠").font(.headline)
                        Spacer()
                    }.frame(height: 60)
                }.tint(.purple)
            }.frame(maxWidth: UIScreen.main.bounds.size.width)
            
            Button(action: { stopDeliveryPizza() }) {
                HStack {
                    Spacer()
                    Text("Cancel Order 😞").font(.headline)
                    Spacer()
                }.frame(height: 60)
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
