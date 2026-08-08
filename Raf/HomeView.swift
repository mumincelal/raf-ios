import SwiftUI
import SwiftData

struct HomeView: View {
    // Sorted alphabetically by title — this powers the flat "My books"
    // list further down. `@Query`'s `sort:` parameter takes a key path
    // straight into the SwiftData model.
    @Query(sort: \Book.title) private var books: [Book]

    /// The 6 most recently added books, for "New arrivals". `addedAt`
    /// is stamped once when a `Book` is created and never changes, so
    /// sorting by it descending gives "newest first". `.prefix(6)`
    /// returns an `ArraySlice`, so `.map { $0 }` turns it back into a
    /// plain `[Book]` that `ForEach` below can use directly.
    private var newArrivals: [Book] {
        books.sorted { $0.addedAt > $1.addedAt }.prefix(6).map { $0 }
    }

    var body: some View {
        // `NavigationStack` is SwiftUI's container for push-style
        // navigation: anything inside it that pushes a new screen (like
        // the `NavigationLink`s below) slides in on top with a back
        // button provided automatically — no manual navigation stack
        // management needed.
        NavigationStack {
            // `ScrollViewReader` gives us a `proxy` that can scroll to
            // any view carrying a matching `.id(...)` — that's what
            // makes the "View all" link below jump down to "My books".
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        header

                        if books.isEmpty {
                            Text("Your shelves are empty.\nTap Add to scan a barcode or enter a book by hand.")
                                .font(AppFont.body(14))
                                .foregroundStyle(Palette.muted)
                                .padding(.top, 40)
                        } else {
                            newArrivalsSection(scrollProxy: proxy)
                            myBooksSection
                        }
                    }
                    .padding(20)
                }
                .background(Palette.paper)
            }
            // `.navigationDestination(for:)` registers, once per value
            // type, which view to push when a `NavigationLink(value:)`
            // carrying that type is tapped anywhere inside this
            // `NavigationStack` — here, tapping a `Book` pushes `DetailView`.
            .navigationDestination(for: Book.self) { DetailView(book: $0) }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("My Library")
                .font(AppFont.title(30))
                .foregroundStyle(Palette.ink)
            Spacer()
            Text("\(books.count) vols.")
                .font(AppFont.body(12))
                .foregroundStyle(Palette.muted)
        }
        .padding(.top, 8)
    }

    private func newArrivalsSection(scrollProxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("New arrivals")
                    .font(AppFont.title(18))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Button("View all") {
                    // `withAnimation` wraps the scroll so the list glides
                    // to "My books" instead of jumping there instantly.
                    withAnimation {
                        scrollProxy.scrollTo("myBooksSection", anchor: .top)
                    }
                }
                .font(AppFont.body(13, weight: .medium))
                .foregroundStyle(Palette.sunflower)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(newArrivals) { book in
                        // `NavigationLink(value:)` doesn't say what screen
                        // to push directly — it just hands the tapped
                        // `Book` up to the nearest matching
                        // `.navigationDestination(for:)`, which is the one
                        // registered on the `NavigationStack` above.
                        NavigationLink(value: book) {
                            VStack(alignment: .leading, spacing: 4) {
                                BookCoverView(book: book, width: 110, height: 160)
                                Text(book.title)
                                    .font(AppFont.body(12, weight: .medium))
                                    .foregroundStyle(Palette.ink)
                                    .lineLimit(1)
                                Text(book.author)
                                    .font(AppFont.body(11))
                                    .foregroundStyle(Palette.muted)
                                    .lineLimit(1)
                            }
                            .frame(width: 110)
                        }
                        // `.plain` stops NavigationLink from tinting the
                        // whole card blue like a normal list row would.
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var myBooksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("My books")
                .font(AppFont.title(18))
                .foregroundStyle(Palette.ink)
                // The id `ScrollViewProxy.scrollTo("myBooksSection")`
                // above looks for — this is what makes that call work.
                .id("myBooksSection")

            VStack(spacing: 0) {
                ForEach(books) { book in
                    // Same push-navigation pattern as "New arrivals" above.
                    NavigationLink(value: book) {
                        HStack(spacing: 14) {
                            BookCoverView(book: book, width: 44, height: 64)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(book.title)
                                    .font(AppFont.body(15, weight: .medium))
                                    .foregroundStyle(Palette.ink)
                                Text(book.author)
                                    .font(AppFont.body(12))
                                    .foregroundStyle(Palette.muted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(Palette.muted)
                        }
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    Divider()
                }
            }
            .padding(16)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 10))
        }
    }
}
