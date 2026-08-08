import Foundation

/// Fetches book metadata from the Open Library API by ISBN. No API key required.
enum BookLookupService {

    struct Draft {
        var title: String
        var author: String
        var isbn: String
        var genre: String
        var pages: Int

        var coverURL: URL? {
            URL(string: "https://covers.openlibrary.org/b/isbn/\(isbn)-M.jpg")
        }
    }

    static func byIsbn(_ isbn: String) async -> Draft? {
        guard let url = URL(string: "https://openlibrary.org/api/books?bibkeys=ISBN:\(isbn)&format=json&jscmd=data") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard
                let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let info = root["ISBN:\(isbn)"] as? [String: Any]
            else { return nil }

            let authorNames = (info["authors"] as? [[String: Any]])?.compactMap { $0["name"] as? String } ?? []
            let authors = authorNames.isEmpty ? "Unknown author" : authorNames.joined(separator: ", ")
            let subjects = (info["subjects"] as? [[String: Any]])?.compactMap { $0["name"] as? String } ?? []

            return Draft(
                title: info["title"] as? String ?? "Untitled",
                author: authors,
                isbn: isbn,
                genre: subjects.first ?? "Fiction",
                pages: info["number_of_pages"] as? Int ?? 0
            )
        } catch {
            return nil
        }
    }
}
