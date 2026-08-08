import SwiftUI

/* ————— New flat palette (from the Figma style sheet) ————— */

/// Centralized design tokens for Raf's UI. Keeping colors and fonts
/// in one place means every screen stays visually consistent, and a
/// future re-theme only has to touch this file.
enum Palette {
    // `Color(red:green:blue:)` takes components from 0 to 1, not the
    // usual 0–255 you'd see in a hex color — so each value below is the
    // hex byte divided by 255. The hex is kept in the comment so it's
    // easy to check against the design file.
    static let ink       = Color(red: 0.075, green: 0.071, blue: 0.071) // #131212
    static let muted     = Color(red: 0.514, green: 0.514, blue: 0.533) // #838388
    static let sunflower = Color(red: 0.965, green: 0.757, blue: 0.176) // #F6C12D
    static let peach     = Color(red: 0.969, green: 0.859, blue: 0.722) // #F7DBB8
    static let sprout    = Color(red: 0.204, green: 0.780, blue: 0.349) // #34C759
    static let paper     = Color(red: 0.976, green: 0.976, blue: 0.976) // #F9F9F9
}

/// Font helpers so screens ask for "a title" or "body text" by name,
/// instead of repeating raw `.system(size:design:)` calls everywhere.
/// `enum` with no `case`s is a common Swift trick for a plain namespace —
/// it can't be instantiated, it just groups related static functions.
enum AppFont {
    /// Headline / title style. `design: .serif` makes SwiftUI render New
    /// York, the serif system font Apple ships alongside San Francisco —
    /// no custom font file needed.
    static func title(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// Body / label style. Plain `.system` with no `design:` argument
    /// renders as San Francisco, iOS's default UI font.
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
}
