import SwiftUI

/// Shown once, the first time the app launches — see `RafApp.swift`,
/// which decides whether to show this or `ContentView` based on an
/// `@AppStorage` flag, and passes `onFinish` so this view can flip
/// that flag once the user is done.
struct OnboardingView: View {
    /// Called when the user finishes the carousel or taps "Skip".
    var onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
        // `UIPageControl` is UIKit configuration that `TabView`'s
        // `.page` style still relies on under the hood for its dot
        // indicators — same pattern as `ContentView`'s `UITabBarAppearance`
        // setup. Without this, the dots use their default white/translucent
        // tint, which is invisible against our light `Palette.paper`
        // background.
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Palette.ink)
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(Palette.ink.opacity(0.25))
    }

    /// A private nested type — only `OnboardingView` needs to know the
    /// shape of a slide, so declaring it inside keeps it out of the
    /// rest of the app's namespace instead of adding another top-level
    /// type that nothing else uses.
    private struct Slide {
        let icon: String
        let title: String
        let subtitle: String
    }

    private let slides: [Slide] = [
        Slide(
            icon: "books.vertical",
            title: "Keep your books organized",
            subtitle: "Group every book by room and shelf so you always know where it lives."
        ),
        Slide(
            icon: "barcode.viewfinder",
            title: "Add a book in seconds",
            subtitle: "Scan a barcode and Raf looks up the title, author, and page count for you."
        ),
    ]

    // Drives which page the `TabView` below shows; "Next" increments it.
    @State private var page = 0

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("Skip", action: onFinish)
                    .font(AppFont.body(15))
                    .foregroundStyle(Palette.muted)
            }
            .padding()

            // `.page` turns a `TabView` into a swipeable carousel with
            // dot indicators drawn for free — no extra code needed for
            // the dots themselves.
            TabView(selection: $page) {
                // `slides.enumerated()` pairs each slide with its index
                // (0, 1, 2, ...); wrapping it in `Array(...)` gives
                // `ForEach` a concrete collection to work with. `Slide`
                // has no `id` property of its own, so `id: \.offset`
                // tells `ForEach` to use that index as each slide's
                // unique identifier instead.
                ForEach(Array(slides.enumerated()), id: \.offset) { index, slide in
                    slideView(slide).tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button(page == slides.count - 1 ? "Get Started" : "Next") {
                if page == slides.count - 1 {
                    onFinish()
                } else {
                    withAnimation { page += 1 }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding()
        }
        .background(Palette.paper)
    }

    private func slideView(_ slide: Slide) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Circle()
                .fill(Palette.peach)
                .frame(width: 220, height: 220)
                .overlay(
                    Image(systemName: slide.icon)
                        .font(.system(size: 72))
                        .foregroundStyle(Palette.ink)
                )
            Text(slide.title)
                .font(AppFont.title(26))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
            Text(slide.subtitle)
                .font(AppFont.body(15))
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}
