//
//  ContentView.swift
//  BearTracks
//
//  Created by Jacob Quion on 7/30/26.
//

import SwiftUI

struct ContentView: View {
    /// Shows the branded launch screen briefly on startup, then reveals the app.
    @State private var showingSplash = true

    /// App-wide appearance, toggled from the Dining tab's top-right menu.
    /// Defaults to dark; persisted across launches.
    @AppStorage("isDarkMode") private var isDarkMode = true

    /// Owned here (not inside LibraryView) so its hours can start fetching during
    /// the splash — the Library tab is then already loaded when the user opens it.
    @StateObject private var libraryModel = LibraryViewModel()

    /// The section currently on screen, chosen from the bottom drop-up menu.
    @State private var section: AppSection = .dining

    /// Whether the full-width section panel is expanded above the bottom bar.
    @State private var showMenu = false

    /// Drives the status bar above the bottom nav into its "loading" state for a
    /// short beat whenever the section changes, so switching tabs reads as the
    /// new screen spinning up.
    @State private var isTabLoading = false

    /// The status bar shows loading while a tab switch settles, or while the
    /// Library's hours are actually being fetched (its model lives here).
    private var isSectionLoading: Bool {
        isTabLoading || (section == .library && libraryModel.isLoading)
    }

    var body: some View {
        ZStack {
            main

            sectionPanelOverlay

            if showingSplash {
                SplashView()
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .task {
            // Prefetch library hours up front, independently of the splash timer.
            Task { await libraryModel.load() }
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(.easeOut(duration: 0.45)) { showingSplash = false }
        }
    }

    /// All sections are kept alive and stacked; only the chosen one is visible
    /// and interactive, so switching between them preserves each screen's state
    /// (scroll position, loaded data) the way the old tab bar did. The drop-up
    /// menu lives in a bottom safe-area inset so it never covers content.
    private var main: some View {
        ZStack {
            ForEach(AppSection.allCases) { item in
                view(for: item)
                    .opacity(section == item ? 1 : 0)
                    .allowsHitTesting(section == item)
                    .zIndex(section == item ? 1 : 0)
            }
        }
        .safeAreaInset(edge: .bottom) {
            sectionMenu
        }
        .onChange(of: section) { _, _ in
            isTabLoading = true
            Task {
                try? await Task.sleep(for: .milliseconds(750))
                isTabLoading = false
            }
        }
    }

    @ViewBuilder
    private func view(for section: AppSection) -> some View {
        switch section {
        case .dining: DiningView()
        case .library: LibraryView(model: libraryModel)
        case .gym: GymView()
        case .events: EventsView()
        case .game: GameView()
        }
    }

    /// The bottom bar that replaces the tab bar: a full-width gray strip showing
    /// the current section. Tapping it toggles the full-width section panel.
    private var sectionMenu: some View {
        Button {
            withAnimation(.easeOut(duration: 0.22)) { showMenu.toggle() }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: section.icon)
                Text(section.title)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "chevron.up")
                    .font(.subheadline.weight(.semibold))
                    .rotationEffect(.degrees(showMenu ? 180 : 0))
            }
            .font(.headline)
            .foregroundStyle(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray5),
                        in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            // Seat the status bar on the flat top edge of the nav bar, inset
            // past the corner radius so it never rides over the rounding.
            .overlay(alignment: .top) {
                TabLoadingBar(isLoading: isSectionLoading)
                    .padding(.horizontal, 22)
            }
            // Held a touch narrower than the screen content so the bar reads as
            // a floating pill rather than a full-width strip.
            .padding(.horizontal, 28)
            .padding(.bottom, 4)
        }
        .buttonStyle(.plain)
    }

    /// A dimming scrim plus a full-width panel that rises from the bottom bar and
    /// lists every section. Built by hand because a SwiftUI `Menu` popover is
    /// system-sized and can't be forced to span the full screen width.
    @ViewBuilder
    private var sectionPanelOverlay: some View {
        if showMenu {
            ZStack(alignment: .bottom) {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { closeMenu() }
                    .transition(.opacity)

                VStack(spacing: 0) {
                    ForEach(AppSection.allCases) { item in
                        Button {
                            section = item
                            closeMenu()
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: item.icon)
                                    .frame(width: 26)
                                Text(item.title)
                                Spacer(minLength: 0)
                                if section == item {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Theme.heading)
                                }
                            }
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if item != AppSection.allCases.last {
                            Divider().padding(.leading, 24)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color(.systemGray5),
                            in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(.horizontal, 28)
                .padding(.bottom, 4)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .zIndex(5)
        }
    }

    private func closeMenu() {
        withAnimation(.easeOut(duration: 0.22)) { showMenu = false }
    }
}

/// The app's top-level sections, surfaced through the bottom drop-up menu.
enum AppSection: String, CaseIterable, Identifiable {
    case dining, library, gym, events, game

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dining: "Dining"
        case .library: "Library"
        case .gym: "Gym"
        case .events: "Events"
        case .game: "Easter Egg Game"
        }
    }

    var icon: String {
        switch self {
        case .dining: "fork.knife"
        case .library: "books.vertical"
        case .gym: "dumbbell"
        case .events: "calendar"
        case .game: "gamecontroller.fill"
        }
    }
}

/// A slim status bar pinned just above the bottom nav. At rest it "breathes" —
/// a faint light rule gently pulsing its opacity. While a tab is loading it
/// turns into a sky-blue segment that sweeps left → right on a loop, reading
/// as busy without a spinner.
struct TabLoadingBar: View {
    let isLoading: Bool

    /// Drives the idle breathing pulse (opacity), running while not loading.
    @State private var breathe = false

    /// Drives the loading sweep (horizontal offset), running while loading.
    @State private var sweep = false

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let segment = width * 0.35
            ZStack(alignment: .leading) {
                // The idle/track rule, a subtle sky blue that breathes when
                // not loading.
                Capsule()
                    .fill(Theme.skyBlue)
                    .opacity(isLoading ? 0.28 : (breathe ? 0.55 : 0.18))

                // The travelling sky-blue segment shown only while loading.
                if isLoading {
                    Capsule()
                        .fill(Theme.skyBlue.opacity(0.7))
                        .frame(width: segment)
                        .offset(x: sweep ? width : -segment)
                }
            }
            .clipShape(Capsule())
        }
        .frame(height: 3)
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .onAppear { restartAnimation() }
        .onChange(of: isLoading) { _, _ in restartAnimation() }
    }

    /// Kicks off whichever looping animation matches the current state: the
    /// left-to-right sweep while loading, or the gentle breathing pulse at rest.
    private func restartAnimation() {
        if isLoading {
            sweep = false
            withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: false)) {
                sweep = true
            }
        } else {
            breathe = false
            withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }
}

/// The branded launch screen: the BearTracks logo centered on the app's dark
/// blue, with a small "not affiliated" disclaimer pinned to the bottom.
struct SplashView: View {
    var body: some View {
        ZStack {
            Theme.berkeleyBlue.ignoresSafeArea()

            VStack {
                Spacer()
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 260)
                Spacer()
                Text("This app is not affiliated with UC Berkeley.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    ContentView()
}

