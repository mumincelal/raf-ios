import SwiftUI
import SwiftData

@main
struct RafApp: App {
    // `@AppStorage` reads and writes a value straight to `UserDefaults`
    // and re-renders this view whenever it changes — a lightweight way
    // to persist one small flag ("has this user seen onboarding?")
    // without needing a full database model for it. `false` is the
    // default the very first time the app ever runs.
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some Scene {
        WindowGroup {
            // `.preferredColorScheme` is a `View` modifier, not a `Scene`
            // one, so it can't go directly on `WindowGroup` — wrapping
            // the two branches in a plain `Group` gives us a single view
            // to hang it on. Raf's palette (see `Theme.swift`) is one
            // fixed light theme by design, not an adaptive light/dark
            // theme — it has no dark-mode colors defined. Pinning this
            // stops system Dark Mode from flipping UIKit-backed controls
            // (TextField, Picker, Divider, ...) to dark styling while our
            // own white/paper surfaces stay light, which otherwise breaks
            // contrast all over the app.
            Group {
                if hasOnboarded {
                    ContentView()
                } else {
                    OnboardingView { hasOnboarded = true }
                }
            }
            .preferredColorScheme(.light)
        }.modelContainer(for: Book.self)
    }
}
