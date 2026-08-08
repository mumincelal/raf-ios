import SwiftUI
import SwiftData

struct StatsView: View {
    // `@Query` is a SwiftData property wrapper: it runs a live database
    // query and keeps `books` automatically up to date whenever the
    // underlying data changes — no manual refresh code needed.
    @Query private var books: [Book]

    private var byGenre: [(genre: String, count: Int)] {
        Dictionary(grouping: books, by: \.genre)
            .map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Your collection")
                    .font(AppFont.title(26))
                    .foregroundStyle(Palette.ink)

                HStack(spacing: 12) {
                    StatTile(value: "\(books.count)", label: "BOOKS")
                    StatTile(value: "\(books.reduce(0) { $0 + $1.pages })", label: "PAGES")
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("BY GENRE")
                        .font(AppFont.body(11, weight: .medium))
                        .kerning(2)
                        .foregroundStyle(Palette.muted)

                    ForEach(byGenre, id: \.genre) { item in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(item.genre)
                                    .font(AppFont.body(13))
                                    .foregroundStyle(Palette.ink)
                                Spacer()
                                Text("\(item.count)")
                                    .font(AppFont.body(11))
                                    .foregroundStyle(Palette.muted)
                            }
                            // `GeometryReader` hands us the actual size
                            // SwiftUI gave this view, so the filled part
                            // of the bar can be a percentage of it.
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Palette.muted.opacity(0.2))
                                    // One accent color for every bar now,
                                    // instead of the old per-genre colors —
                                    // genre color-coding was removed when
                                    // real cover art replaced it as the
                                    // way to visually tell books apart.
                                    Capsule().fill(Palette.sunflower)
                                        .frame(width: geo.size.width * CGFloat(item.count) / CGFloat(max(books.count, 1)))
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 10))
            }
            .padding(20)
        }
        .background(Palette.paper)
    }
}
