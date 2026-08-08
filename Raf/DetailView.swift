import SwiftUI
import SwiftData

struct DetailView: View {
    // `@Bindable` is a SwiftData/Observation property wrapper that lets
    // this view read and (if we wanted to) two-way-bind to `book`'s
    // properties directly. Changes we make below
    // are written straight back to the database automatically.
    @Bindable var book: Book
    // `@Environment(\.modelContext)` reaches into the environment SwiftUI
    // threads down the view hierarchy and pulls out the shared SwiftData
    // context — the object that actually saves/deletes `Book`s to disk.
    @Environment(\.modelContext) private var context
    // `@Environment(\.dismiss)` hands us an action that closes this view
    // and pops back to whichever screen pushed it; we call it below after
    // deleting the book so we're not left staring at a now-gone book.
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                cover
                header
                statusLabel
                infoCard
                // `role: .destructive` marks this as a dangerous,
                // hard-to-undo action; SwiftUI tints it red automatically
                // so we don't have to pick a warning color ourselves.
                Button("Remove from library", role: .destructive) {
                    // Dismiss first, then delete on the next run-loop
                    // turn. `DetailView` is pushed via `.navigationDestination
                    // (for: Book.self)`, so deleting `book` before the pop
                    // finishes risks this view's body re-evaluating against
                    // an already-invalidated `Book` — dispatching the
                    // delete to `.main` lets the pop complete first.
                    dismiss()
                    DispatchQueue.main.async {
                        context.delete(book)
                    }
                }
                .font(AppFont.body(13))
                .padding(.top, 4)
            }
            .padding(20)
        }
        .background(Palette.paper)
        .navigationTitle("")
        .toolbarBackground(Palette.paper, for: .navigationBar)
    }

    /// Large cover art, replacing the old flat genre-color rectangle.
    /// `variant: "L"` asks `BookCoverView` for the large Open Library
    /// image size, since this is the hero image on the whole screen.
    private var cover: some View {
        BookCoverView(book: book, width: 180, height: 260, variant: "L")
            .shadow(color: .black.opacity(0.15), radius: 12, y: 8)
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text(book.title)
                .font(AppFont.title(24))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
            Text(book.author)
                .font(AppFont.body(14))
                .foregroundStyle(Palette.muted)
            Text("ISBN \(book.isbn)")
                .font(AppFont.body(11))
                .foregroundStyle(Palette.muted)
                .padding(.top, 2)
        }
    }

    /// Small status line where the mockup had its "8 In Stock" bar.
    /// Raf books aren't stock, so this just states plain
    /// availability: green when the book is on the shelf, yellow when
    /// it's out with someone. `Label` is a SwiftUI view that pairs an
    /// SF Symbol with text and lays them out correctly for free.
    private var statusLabel: some View {
        // `Group` doesn't add any layout of its own — it's a plain
        // container. What it does here is give this `if`/`else` a
        // view-builder context, so its two branches (which are different
        // concrete view types under the hood) can combine into the single
        // `some View` this computed property has to return.
        Group {
            Label("On your shelf", systemImage: "checkmark.circle.fill")
                .foregroundStyle(Palette.sprout)
        }
        .font(AppFont.body(13, weight: .medium))
    }

    private var infoCard: some View {
        VStack(spacing: 0) {
            infoRow("Location", book.shelf)
            infoRow("Genre", book.genre)
            infoRow("Pages", book.pages > 0 ? "\(book.pages)" : "—")
            infoRow("Status", book.status)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 10))
    }

    private func infoRow(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).foregroundStyle(Palette.muted)
            Spacer()
            Text(v).foregroundStyle(Palette.ink)
        }
        .font(AppFont.body(14))
        .padding(.vertical, 8)
    }
}
