//
//  LecturesView.swift
//  BearTracks
//
//  A lightweight front door to UC Berkeley's official course catalog. The
//  catalog (undergraduate.catalog.berkeley.edu) is a JavaScript app with no
//  public, key-free API, so instead of scraping it we hand the user's query to
//  the real catalog and show the results in an in-app Safari view. A full
//  WebKit browser runs the site's JavaScript, so this is always current and
//  never breaks when their markup changes — no undocumented endpoint to guess.
//

import SwiftUI
import SafariServices

struct LecturesView: View {
    @State private var query = ""
    @State private var searchURL: SearchURL?

    /// A few common subjects, so the tab is useful before typing anything.
    private let quickSubjects = ["Computer Science", "Data Science", "Economics",
                                 "Physics", "Psychology", "History"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    warningBanner
                    searchField
                    quickPicks
                }
                .padding(16)
            }
            .navigationTitle("Lectures")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $searchURL) { item in
                SafariView(url: item.url).ignoresSafeArea()
            }
        }
    }

    // MARK: Warning

    private var warningBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            VStack(alignment: .leading, spacing: 4) {
                Text("Before you drop in")
                    .font(.subheadline.weight(.semibold))
                Text("Class times are subject to change. Make sure the course allows auditing or drop-ins, and confirm the room and time with the department or instructor before attending.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.yellow.opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: Search

    private var searchField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Search the class catalog")
                .font(.headline)
                .foregroundStyle(Theme.heading)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Course name, number, or keyword", text: $query)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit(runSearch)
                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.primary.opacity(0.08)))

            Button(action: runSearch) {
                Label("Search catalog", systemImage: "graduationcap.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.control, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
            }
            .disabled(trimmedQuery.isEmpty)
            .opacity(trimmedQuery.isEmpty ? 0.5 : 1)
        }
    }

    private var quickPicks: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Popular subjects")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 8)], spacing: 8) {
                ForEach(quickSubjects, id: \.self) { subject in
                    Button {
                        query = subject
                        runSearch()
                    } label: {
                        Text(subject)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Theme.card, in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func runSearch() {
        let q = trimmedQuery
        guard !q.isEmpty else { return }
        var components = URLComponents(string: "https://undergraduate.catalog.berkeley.edu/courses")!
        components.queryItems = [URLQueryItem(name: "cq", value: q)]
        if let url = components.url {
            searchURL = SearchURL(url: url)
        }
    }
}

/// Wraps a URL so it can drive `.sheet(item:)`.
private struct SearchURL: Identifiable {
    let id = UUID()
    let url: URL
}

/// An in-app Safari browser, so catalog results open without leaving the app.
private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}

#Preview {
    LecturesView()
}
