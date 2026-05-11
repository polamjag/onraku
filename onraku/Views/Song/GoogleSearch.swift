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

struct GoogleSearchContextMenu: ViewModifier {
    let query: String?

    @ViewBuilder
    func body(content: Content) -> some View {
        if GoogleSearch.url(for: query) != nil {
            content.contextMenu {
                GoogleSearchButton(query: query)
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
