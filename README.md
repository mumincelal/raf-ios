# Raf

A personal book-shelf tracker for iOS. Scan or type an ISBN, Raf looks up the
title/author/cover automatically and files it on your shelf.

## Features

- **Scan to add** — point the camera at a barcode (VisionKit `DataScannerViewController`)
  and each recognized ISBN is looked up automatically, one after another.
- **Manual entry** — type or paste an ISBN; lookup fires automatically after a
  short debounce, filling in title/author and a cover preview from Open Library.
- **Duplicate detection** — books already on a shelf are flagged instead of
  added twice.
- **Home** — new arrivals and the full library, grouped and searchable by title.
- **Stats** — total books/pages and a breakdown by genre.
- **Offline-friendly storage** — books persist locally via SwiftData; only the
  lookup step needs network access.

## Requirements

- Xcode 16+
- iOS 17+ (device recommended for camera scanning; the simulator falls back to
  manual entry only)

## Getting started

```sh
open Raf.xcodeproj
```

Build and run the `Raf` scheme on a simulator or device.

## Project layout

- `Raf/RafApp.swift` — app entry point, onboarding gate, SwiftData container
- `Raf/AddBookView.swift` — scan + manual add flow
- `Raf/BookLookupService.swift` — Open Library metadata/cover lookup
- `Raf/HomeView.swift`, `StatsView.swift`, `DetailView.swift` — browsing views
- `Raf/Book.swift` — SwiftData model
- `Raf/Theme.swift`, `Components.swift` — shared palette, fonts, reusable views

## Data source

Book metadata and cover art come from the [Open Library API](https://openlibrary.org/dev/docs/api/books) — no API key required.
