import SwiftUI

/// A book cover thumbnail, loaded from Open Library's free cover API
/// (no API key required) using the book's ISBN. Used in three places:
/// Home's "New arrivals" scroller, Home's "My books" list rows, and
/// Detail's hero image — pulling it into one component means all three
/// share the same loading/placeholder behavior automatically.
struct BookCoverView: View {
    let book: Book
    var width: CGFloat
    var height: CGFloat
    /// Open Library image size code: "M" (medium) for thumbnails,
    /// "L" (large) for the Detail screen's hero image.
    var variant: String = "M"

    private var coverURL: URL? {
        // `?default=false` tells Open Library to respond with a real 404
        // when it has no cover for this ISBN, instead of a "200 OK" 1×1
        // transparent placeholder GIF. Without it, `AsyncImage` sees a
        // successful (if invisible) image load and never falls through
        // to our own `placeholder` view below.
        URL(string: "https://covers.openlibrary.org/b/isbn/\(book.isbn)-\(variant).jpg?default=false")
    }

    var body: some View {
        // `AsyncImage` is SwiftUI's built-in view for loading an image
        // from a URL. The `phase` closure fires again every time the
        // load's state changes, so we can show something sensible at
        // every stage instead of just success/failure.
        AsyncImage(url: coverURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            default:
                // Covers both `.empty` (still loading) and `.failure`
                // (404 or offline) — in both cases we'd rather show a
                // calm placeholder than a broken-image icon or nothing.
                placeholder
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Palette.peach)
            .overlay(
                Image(systemName: "book.closed")
                    .foregroundStyle(Palette.ink.opacity(0.4))
            )
    }
}

/// Full-width black "primary action" button, matching the mockup's
/// solid "Get the Book" bar. `ButtonStyle` is a protocol SwiftUI uses so
/// any `Button` can opt into a shared look with
/// `.buttonStyle(PrimaryButtonStyle())`, instead of copy-pasting the
/// same modifiers onto every button.
struct PrimaryButtonStyle: ButtonStyle {
    // `@Environment(\.isEnabled)` reads whether SwiftUI has disabled
    // this button (e.g. via `.disabled(true)` on the call site). A
    // custom `ButtonStyle` doesn't dim automatically like the built-in
    // styles do, so we read this ourselves to fake that behavior.
    @Environment(\.isEnabled) private var isEnabled

    // `makeBody` is the one method `ButtonStyle` requires: it's handed
    // a `configuration` (the button's label plus its current press
    // state) and returns the view to actually draw.
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.body(16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Palette.ink, in: RoundedRectangle(cornerRadius: 14))
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.35)
    }
}

/// One number + label tile, e.g. "128" over "PAGES". Used three times in
/// a row on the Stats screen.
struct StatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AppFont.title(24))
                .foregroundStyle(Palette.ink)
            Text(label)
                .font(AppFont.body(10, weight: .medium))
                .kerning(1.5)
                .foregroundStyle(Palette.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 10))
    }
}
