import Foundation
import SwiftData

@Model
final class Book {
    @Attribute(.unique) var isbn: String
    var title: String
    var author: String
    var genre: String
    var pages: Int
    var shelf: String
    var status: String          // To read | Reading | Finished
    var addedAt: Date

    init(title: String, author: String, isbn: String,
         genre: String = "Fiction", pages: Int = 0,
         shelf: String = "Unsorted", status: String = "To read") {
        self.title = title
        self.author = author
        self.isbn = isbn
        self.genre = genre
        self.pages = pages
        self.shelf = shelf
        self.status = status
        self.addedAt = Date()
    }
}
