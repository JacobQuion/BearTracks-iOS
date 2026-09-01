//
//  Theme.swift
//  BearTracks
//

import SwiftUI
import CoreLocation

// An independent dark-blue identity — deliberately not UC Berkeley's official navy +
// California-gold, so the app doesn't resemble official university branding.
// (Property names are historical; their values are the app's own palette.)
enum Theme {
    /// Deep blue, for strong fills that sit behind white text.
    static let berkeleyBlue = Color(red: 0.055, green: 0.102, blue: 0.290)

    /// The primary accent — carries headings, labels, and icons on the dark UI.
    static let californiaGold = Color(red: 0.243, green: 0.415, blue: 0.800)

    /// Mid blue. Readable on a dark background, so it drives buttons and controls.
    static let foundersRock = Color(red: 0.145, green: 0.259, blue: 0.588)

    /// The bright accent blue.
    static let lawrence = Color(red: 0.118, green: 0.400, blue: 0.850)

    /// A bright sky blue, used for the loading status bar above the nav bar.
    static let skyBlue = Color(red: 0.35, green: 0.72, blue: 1.0)

    // Semantic roles, so intent is obvious at the call site.
    static let heading = berkeleyBlue
    static let control = foundersRock

    /// A lighter, high-contrast blue for heading/label text that sits on the
    /// dark card surfaces (the game and gym tabs). Brightens in dark
    /// mode so the text reads clearly, and deepens in light mode to stay legible
    /// on the pale card gray — unlike `heading`, which is too dark on cards.
    static let readableBlue = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.45, green: 0.64, blue: 1.0, alpha: 1)
            : UIColor(red: 0.12, green: 0.30, blue: 0.75, alpha: 1)
    })

    /// Card surface that adapts to the chosen appearance: the original dark
    /// charcoal in dark mode, and a soft light gray in light mode so cards read
    /// as raised panels instead of black blocks on a white page.
    static let card = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.12, blue: 0.14, alpha: 1)
            : UIColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 1)
    })
}

enum Campus {
    /// Roughly the center of the UC Berkeley campus, near the Campanile.
    static let center = CLLocationCoordinate2D(latitude: 37.8719, longitude: -122.2585)
}
