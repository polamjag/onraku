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

public extension String {
    func intelligentlySplitIntoSubArtists() -> [String] {
        if self.isEmpty { return [] }
        return self
            .components(separatedBy: " from ")
            .flatMap { $0.split { s in s == "(" || s == ")" } }
            .flatMap { $0.split { s in s == "," || s == "&" || s == "/" || s == "・" } }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .unique()
    }
    
    func intelligentlySplitIntoSubGenres() -> [String] {
        if self.isEmpty { return [] }
        return self
            .split { s in s == "(" || s == ")" }
            .flatMap { s in s.split(separator: "/") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .unique()
    }
}
