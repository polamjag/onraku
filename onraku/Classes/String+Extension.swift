//
//  File.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import Foundation

// https://betterprogramming.pub/remove-duplicates-from-an-array-get-unique-values-in-swift-7a477ef89260
extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}

extension String {
    public func intelligentlySplitIntoSubArtists() -> [String] {
        if self.isEmpty { return [] }
        return
            self
            .components(separatedBy: " x ")
            .flatMap { $0.components(separatedBy: " X ") }
            .flatMap { $0.components(separatedBy: " from ") }
            .flatMap { $0.components(separatedBy: " feat. ") }
            .flatMap { $0.components(separatedBy: " Feat. ") }
            .flatMap { $0.split { s in s == "(" || s == ")" } }
            .flatMap { $0.split { s in s == "," || s == "&" || s == "/" || s == "・" || s == "×" } }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .unique()
    }

    public func intelligentlySplitIntoSubGenres() -> [String] {
        if self.isEmpty { return [] }
        return
            self
            .split { s in s == "(" || s == ")" }
            .flatMap { s in s.split(separator: "/") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .unique()
    }
}
