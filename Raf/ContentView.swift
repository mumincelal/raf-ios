import SwiftUI

struct ContentView: View {
    init() {
        // `UITabBarAppearance` is UIKit configuration that SwiftUI's
        // `TabView` still relies on under the hood for the tab bar's
        // chrome — this is how the tab bar background gets recolored
        // to match the new light palette.
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Palette.paper)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            AddBookView()
                .tabItem { Label("Add", systemImage: "barcode.viewfinder") }
            HomeView()
                .tabItem { Label("Home", systemImage: "books.vertical") }
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar") }
        }
        .tint(Palette.sunflower)
    }
}
