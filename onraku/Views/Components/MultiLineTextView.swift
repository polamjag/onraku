//
//  MultiLineTextView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import MediaPlayer
import SwiftUI

struct MultiLineTextView: View {
    enum LinkMode {
        case plain
        case comments
    }

    var text: String
    var linkMode: LinkMode = .plain
    @State private var selectedCommentSearch: CommentSearchLink?

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(displayText)
                    .padding()
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .multilineTextAlignment(.leading)
            }
            .environment(\.openURL, OpenURLAction { url in
                guard let commentSearch = CommentSearchLink(url: url) else {
                    return .systemAction
                }

                selectedCommentSearch = commentSearch
                return .handled
            })
            .navigationDestination(item: $selectedCommentSearch) { commentSearch in
                QueriedSongsListViewContainer(
                    songsList: commentSearch.songsList
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var displayText: AttributedString {
        switch linkMode {
        case .plain:
            AttributedString(text)
        case .comments:
            MultiLineTextLinkifier.attributedString(for: text)
        }
    }
}

struct MultiLineTextLink: Equatable {
    let range: NSRange
    let url: URL
}

struct CommentSearchLink: Hashable, Identifiable {
    static let scheme = "onraku-comment-search"

    let query: String

    var id: String { query }

    var title: String {
        "Comments: \(query)"
    }

    var predicate: MyMPMediaPropertyPredicate {
        songsList.predicate
    }

    var songsList: SongsListFromCommentsSearch {
        SongsListFromCommentsSearch(query: query, title: title)
    }

    init?(query: String?) {
        guard let query = query?.trimmingCharacters(in: .whitespacesAndNewlines),
            !query.isEmpty
        else {
            return nil
        }
        self.query = query
    }

    init?(url: URL) {
        guard url.scheme == Self.scheme,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let query = components.queryItems?.first(where: { $0.name == "query" })?.value
        else {
            return nil
        }
        self.init(query: query)
    }

    var url: URL? {
        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = "search"
        components.queryItems = [
            URLQueryItem(name: "query", value: query)
        ]
        return components.url
    }
}

enum MultiLineTextLinkifier {
    private static let urlDetector = try! NSDataDetector(
        types: NSTextCheckingResult.CheckingType.link.rawValue)

    private static let bracketRegex = try! NSRegularExpression(
        pattern: #"\[([^\[\]\r\n]+)\]"#)

    static func attributedString(for text: String) -> AttributedString {
        var attributedText = AttributedString(text)

        detectLinks(in: text).forEach { link in
            guard let stringRange = Range(link.range, in: text),
                let attributedRange = Range(stringRange, in: attributedText)
            else {
                return
            }
            attributedText[attributedRange].link = link.url
        }

        return attributedText
    }

    static func detectLinks(in text: String) -> [MultiLineTextLink] {
        let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)
        var links = urlLinks(in: text, fullRange: fullRange)

        bracketSearchLinks(in: text, fullRange: fullRange).forEach { link in
            let overlapsURL = links.contains {
                NSIntersectionRange($0.range, link.range).length > 0
            }
            guard !overlapsURL else {
                return
            }
            links.append(link)
        }

        return links.sorted { $0.range.location < $1.range.location }
    }

    private static func urlLinks(in text: String, fullRange: NSRange) -> [MultiLineTextLink] {
        urlDetector.matches(in: text, options: [], range: fullRange).compactMap { match in
            guard let url = match.url else { return nil }
            return MultiLineTextLink(range: match.range, url: url)
        }
    }

    private static func bracketSearchLinks(in text: String, fullRange: NSRange)
        -> [MultiLineTextLink]
    {
        bracketRegex.matches(in: text, options: [], range: fullRange).compactMap { match in
            guard match.numberOfRanges > 1,
                let queryRange = Range(match.range(at: 1), in: text),
                let url = CommentSearchLink(query: String(text[queryRange]))?.url
            else {
                return nil
            }

            return MultiLineTextLink(range: match.range, url: url)
        }
    }
}

struct MultiLineTextView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MultiLineTextView(
                text: """
                    First line of the selected text.
                    Second line keeps wrapping behavior visible.

                    https://example.com
                    [anime:foobar]

                    A longer paragraph checks that the scroll view stays aligned to the top \
                    and keeps text selection enabled for comments and lyrics.
                    """,
                linkMode: .comments
            )
            .navigationTitle("Lyrics")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
