//
//  iOS16_Live_ActivitiesApp.swift
//  iOS16-Live-Activities
//
//  Created by Ming on 28/7/2022.
//

import SwiftUI

@main
struct iOS16_Live_ActivitiesApp: App {
    init() {
        // Set toolbar and navigation title text color white
        let coloredAppearance = UINavigationBarAppearance()
        coloredAppearance.configureWithOpaqueBackground()
        coloredAppearance.backgroundColor = .clear
        coloredAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        coloredAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        coloredAppearance.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = coloredAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
