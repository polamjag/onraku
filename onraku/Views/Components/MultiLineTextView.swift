//
//  MultiLineTextView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import SwiftUI

struct MultiLineTextView: View {
    enum LinkMode {
        case plain
        case comments
    }

    var text: String
    var linkMode: LinkMode = .plain

    var body: some View {
        ScrollView {
            Text(displayText)
                .padding()
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .multilineTextAlignment(.leading)
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
                let url = GoogleSearch.url(for: String(text[queryRange]))
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
