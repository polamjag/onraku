//
//  GoogleSearch.swift
//  onraku
//
//  Created by Codex on 2026/05/11.
//

import Foundation
import SwiftUI

enum GoogleSearch {
    static func url(for query: String?) -> URL? {
        guard let query = query?.trimmingCharacters(in: .whitespacesAndNewlines),
            !query.isEmpty
        else {
            return nil
        }

        var components = URLComponents(string: "https://www.google.com/search")
        components?.queryItems = [
            URLQueryItem(name: "q", value: query)
        ]
        return components?.url
    }
}

enum SpotifySearch {
    static func url(for query: String?) -> URL? {
        guard let query = query?.trimmingCharacters(in: .whitespacesAndNewlines),
            !query.isEmpty
        else {
            return nil
        }

        var allowedCharacters = CharacterSet.urlPathAllowed
        allowedCharacters.remove(charactersIn: "/?")

        guard
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
        else {
            return nil
        }

        return URL(string: "https://open.spotify.com/search/\(encodedQuery)")
    }
}

struct GoogleSearchButton: View {
    @Environment(\.openURL) private var openURL

    let query: String?

    var body: some View {
        if let url = GoogleSearch.url(for: query) {
            Button {
                openURL(url)
            } label: {
                Label("Search Google", systemImage: "magnifyingglass")
            }
        }
    }
}

struct SpotifySearchButton: View {
    @Environment(\.openURL) private var openURL

    let query: String?

    var body: some View {
        if let url = SpotifySearch.url(for: query) {
            Button {
                openURL(url)
            } label: {
                Label("Search on Spotify", systemImage: "music.note")
            }
        }
    }
}

struct GoogleSearchContextMenu: ViewModifier {
    let query: String?

    @ViewBuilder
    func body(content: Content) -> some View {
        if GoogleSearch.url(for: query) != nil || SpotifySearch.url(for: query) != nil {
            content.contextMenu {
                GoogleSearchButton(query: query)
                SpotifySearchButton(query: query)
            }
        } else {
            content
        }
    }
}

extension View {
    func googleSearchContextMenu(query: String?) -> some View {
        modifier(GoogleSearchContextMenu(query: query))
    }
}
