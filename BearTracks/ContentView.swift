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

    var body: some View {
        ZStack {
            main

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
    }

    @ViewBuilder
    private func view(for section: AppSection) -> some View {
        switch section {
        case .dining: DiningView()
        case .library: LibraryView(model: libraryModel)
        case .gym: GymView()
        case .events: EventsView()
        case .lectures: LecturesView()
        case .game: GameView()
        }
    }

    /// A single control that replaces the tab bar: it shows the current section
    /// and, when tapped, opens a menu upward listing every section.
    private var sectionMenu: some View {
        Menu {
            Picker("Section", selection: $section) {
                ForEach(AppSection.allCases) { item in
                    Label(item.title, systemImage: item.icon).tag(item)
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: section.icon)
                Text(section.title)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "chevron.up")
                    .font(.subheadline.weight(.semibold))
            }
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Theme.control, in: Capsule())
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
    }
}

/// The app's top-level sections, surfaced through the bottom drop-up menu.
enum AppSection: String, CaseIterable, Identifiable {
    case dining, library, gym, events, lectures, game

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dining: "Dining"
        case .library: "Library"
        case .gym: "Gym"
        case .events: "Events"
        case .lectures: "Lectures"
        case .game: "Easter Egg Game"
        }
    }

    var icon: String {
        switch self {
        case .dining: "fork.knife"
        case .library: "books.vertical"
        case .gym: "dumbbell"
        case .events: "calendar"
        case .lectures: "graduationcap"
        case .game: "gamecontroller.fill"
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

