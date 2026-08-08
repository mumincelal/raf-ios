import SwiftUI
import SwiftData
import VisionKit
// `internal import` is an access-scoped import: Vision's API is available to this
// module's own code, but the fact that we depend on Vision isn't re-exported to
// anything that imports Raf itself. Plain `import Vision` would work too, but
// wouldn't make that boundary explicit.
internal import Vision

struct AddBookView: View {
    @Environment(\.modelContext) private var context
    @Query private var books: [Book]

    enum Mode: String, CaseIterable, Identifiable {
        case scan = "Scan"
        case manual = "Manual"
        var id: String { rawValue }
    }

    enum ScanState: Equatable {
        case idle, loading
        // `duplicate` and `notFound` are cases with associated values: each time the
        // state becomes one of these, it carries its own extra data along with it
        // (the matched book's title/shelf, or the ISBN that failed to look up). You
        // unwrap that data with `if case`/`switch` pattern matching, as `resultCard` does below.
        case duplicate(title: String, shelf: String)
        case notFound(isbn: String)
    }

    @State private var mode: Mode = .scan
    @State private var state: ScanState = .idle
    @State private var draft: BookLookupService.Draft?
    @State private var lastIsbn: String?

    @State private var isbnInput = ""
    @State private var titleInput = ""
    @State private var authorInput = ""
    @State private var manualCoverURL: URL?
    @State private var lookupTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add a book")
                .font(AppFont.title(26))
                .foregroundStyle(Palette.ink)

            Picker("Mode", selection: $mode) {
                ForEach(Mode.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: mode) { _, _ in resetAll() }

            switch mode {
            case .scan:
                ScannerSection(onScan: handleScan)
            case .manual:
                ManualEntrySection(
                    isbn: $isbnInput,
                    title: $titleInput,
                    author: $authorInput,
                    coverURL: manualCoverURL,
                    onAdd: addManual
                )
                .onChange(of: isbnInput) { _, _ in scheduleManualLookup() }
            }

            resultCard

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.paper)
    }

    // `@ViewBuilder` on a computed property lets its body contain multiple statements
    // (like the `switch` below plus a trailing `if`) and have SwiftUI combine whichever
    // branches actually run into one view, instead of requiring a single `return`ed value.
    @ViewBuilder
    private var resultCard: some View {
        switch state {
        case .idle:
            if mode == .scan {
                Text("Continuous mode: keep scanning, each new barcode is looked up automatically.")
                    .font(AppFont.body(12.5))
                    .foregroundStyle(Palette.muted)
            }
        case .loading:
            card { Text("Looking up…").foregroundStyle(Palette.muted) }
        case .duplicate(let title, let shelf):
            card {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(AppFont.title(18)).foregroundStyle(Palette.ink)
                    Text("ALREADY OWNED")
                        .font(AppFont.body(12, weight: .bold))
                        .kerning(2).foregroundStyle(Palette.sunflower)
                    Text("Shelf: \(shelf)").font(AppFont.body(13)).foregroundStyle(Palette.muted)
                    Button("Scan next") { resetAll() }.tint(Palette.ink)
                }
            }
        case .notFound(let isbn):
            card {
                VStack(alignment: .leading, spacing: 6) {
                    Text("No match for \(isbn)").foregroundStyle(Palette.ink)
                    if mode == .scan {
                        Text("Add it manually from the Manual tab above.")
                            .font(AppFont.body(13)).foregroundStyle(Palette.muted)
                        Button("Scan next") { resetAll() }.tint(Palette.ink)
                    } else {
                        Text("Fill in the details below and add it by hand.")
                            .font(AppFont.body(13)).foregroundStyle(Palette.muted)
                    }
                }
            }
        }

        if let d = draft, mode == .scan {
            card {
                VStack(alignment: .leading, spacing: 6) {
                    Text(d.title).font(AppFont.title(18)).foregroundStyle(Palette.ink)
                    Text(d.author).font(AppFont.body(13)).foregroundStyle(Palette.muted)
                    Text("ISBN \(d.isbn)")
                        .font(AppFont.body(11))
                        .foregroundStyle(Palette.muted)
                    HStack(spacing: 10) {
                        Button("Add to shelf") { add(d) }
                            .buttonStyle(PrimaryButtonStyle())
                        Button("Skip") { resetAll() }
                            .buttonStyle(.bordered).tint(Palette.muted)
                    }
                    .padding(.top, 6)
                }
            }
        }
    }

    // A generic helper: `<Content: View>` lets this accept any SwiftUI view type as
    // its content, and `@ViewBuilder _ content: () -> Content` lets callers write
    // `card { ... }` with plain view statements inside the braces, the same way
    // you'd write the body of a View, rather than having to build the view manually.
    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 10))
    }

    private func normalize(_ isbn: String) -> String {
        isbn.filter { $0.isNumber }
    }

    private func localDuplicate(_ isbn: String) -> Book? {
        books.first(where: { $0.isbn == isbn })
    }

    private func handleScan(_ isbn: String) {
        guard isbn != lastIsbn, state != .loading else { return }
        guard isbn.count == 13 || isbn.count == 10 else { return }
        lastIsbn = isbn
        draft = nil

        if let existing = localDuplicate(isbn) {
            state = .duplicate(title: existing.title, shelf: existing.shelf)
            return
        }

        state = .loading
        // `Task { ... }` starts a new unit of concurrent work without blocking this
        // function's caller. Inside it, `await` pauses just that task (not the whole
        // app) until `byIsbn`'s network lookup finishes, then resumes and updates
        // `@State` back on the main actor so SwiftUI can redraw with the result.
        Task {
            if let found = await BookLookupService.byIsbn(isbn) {
                draft = found
                state = .idle
            } else {
                state = .notFound(isbn: isbn)
            }
        }
    }

    // Debounces manual ISBN entry: every keystroke or paste cancels the previous
    // pending lookup and schedules a new one, so a fast-typed or pasted ISBN only
    // fires one network request after the user pauses instead of one per character.
    private func scheduleManualLookup() {
        lookupTask?.cancel()
        manualCoverURL = nil
        let isbn = normalize(isbnInput)
        guard isbn.count == 13 || isbn.count == 10 else { return }

        lookupTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            handleManualLookup(isbn)
        }
    }

    private func handleManualLookup(_ isbn: String) {
        guard state != .loading else { return }
        draft = nil

        if let existing = localDuplicate(isbn) {
            state = .duplicate(title: existing.title, shelf: existing.shelf)
            return
        }

        state = .loading
        // Same pattern as in `handleScan`: hop off to an async `Task` so the lookup's
        // `await` doesn't freeze the UI, then write the result into `@State` once it resolves.
        Task {
            if let found = await BookLookupService.byIsbn(isbn) {
                guard normalize(isbnInput) == isbn else { return }
                draft = found
                titleInput = found.title
                authorInput = found.author
                manualCoverURL = found.coverURL
                state = .idle
            } else {
                state = .notFound(isbn: isbn)
            }
        }
    }

    private func add(_ d: BookLookupService.Draft) {
        let book = Book(title: d.title, author: d.author, isbn: d.isbn,
                        genre: d.genre, pages: d.pages)
        context.insert(book)
        resetAll()
    }

    private func addManual() {
        let isbn = normalize(isbnInput)
        let title = titleInput.trimmingCharacters(in: .whitespaces)
        let author = authorInput.trimmingCharacters(in: .whitespaces)
        guard !isbn.isEmpty, !title.isEmpty, !author.isEmpty else { return }

        if let existing = localDuplicate(isbn) {
            state = .duplicate(title: existing.title, shelf: existing.shelf)
            return
        }

        let book: Book
        if let d = draft, normalize(d.isbn) == isbn {
            book = Book(title: title, author: author, isbn: isbn, genre: d.genre, pages: d.pages)
        } else {
            book = Book(title: title, author: author, isbn: isbn)
        }
        context.insert(book)
        resetAll()
    }

    private func resetAll() {
        lookupTask?.cancel()
        state = .idle
        draft = nil
        lastIsbn = nil
        isbnInput = ""
        titleInput = ""
        authorInput = ""
        manualCoverURL = nil
    }
}

private struct ScannerSection: View {
    var onScan: (String) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                BarcodeScanner(onScan: onScan)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Palette.ink)
                    .overlay(
                        Text("Camera scanning isn't available on this device.")
                            .foregroundStyle(.white).padding()
                    )
            }
            Text("POINT AT THE ISBN BARCODE")
                .font(AppFont.body(11, weight: .medium))
                .kerning(1.5)
                .foregroundStyle(.white)
                .padding(12)
        }
        .frame(height: 300)
    }
}

private struct ManualEntrySection: View {
    @Binding var isbn: String
    @Binding var title: String
    @Binding var author: String
    var coverURL: URL?
    var onAdd: () -> Void

    private var canAdd: Bool {
        !isbn.trimmingCharacters(in: .whitespaces).isEmpty &&
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !author.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 10) {
                    TextField("ISBN", text: $isbn)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                    TextField("Title", text: $title)
                        .textFieldStyle(.roundedBorder)
                    TextField("Author", text: $author)
                        .textFieldStyle(.roundedBorder)
                }
                if let coverURL {
                    AsyncImage(url: coverURL) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fit)
                        } else {
                            Color.clear
                        }
                    }
                    .frame(width: 60, height: 90)
                    .background(Palette.paper, in: RoundedRectangle(cornerRadius: 6))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            Button("Add to shelf", action: onAdd)
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canAdd)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 10))
    }
}

/// Wraps VisionKit's DataScannerViewController (iOS 16+) for EAN-13 book barcodes.
///
/// `UIViewControllerRepresentable` is the bridge type for hosting an old-style
/// UIKit view controller inside SwiftUI. SwiftUI calls `makeUIViewController` once
/// and `updateUIViewController` on later refreshes; since UIKit delegates (like
/// `DataScannerViewControllerDelegate`) can't be a `struct`, the nested `Coordinator`
/// class below exists just to be that delegate and forward callbacks back into SwiftUI.
struct BarcodeScanner: UIViewControllerRepresentable {
    var onScan: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.ean13, .upce])],
            qualityLevel: .fast,
            recognizesMultipleItems: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ vc: DataScannerViewController, context: Context) {
        if !vc.isScanning { try? vc.startScanning() }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    // `NSObject` conformance is required here because UIKit delegate protocols like
    // `DataScannerViewControllerDelegate` are Objective-C based and expect their
    // conforming type to be an `NSObject`. `parent` lets this class call back into
    // the SwiftUI `BarcodeScanner` value that created it.
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let parent: BarcodeScanner
        init(_ parent: BarcodeScanner) { self.parent = parent }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didAdd addedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            // `for case let .barcode(barcode) in addedItems` walks the array and, for
            // each element, only enters the loop body if it matches the `.barcode` case
            // of the `RecognizedItem` enum (skipping other kinds like `.text`) — a
            // filtering loop and a pattern-match unwrap combined into one line.
            for case let .barcode(barcode) in addedItems {
                if let value = barcode.payloadStringValue {
                    parent.onScan(value)
                }
            }
        }
    }
}
