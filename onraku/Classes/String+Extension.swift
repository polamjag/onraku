//
//  File.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import Foundation

public extension String {
    func intelligentlySplitIntoSubArtists() -> [String] {
        if self.isEmpty { return [] }
        return self
            .split { s in s == "," || s == "&" || s == "/" }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    func intelligentlySplitIntoSubGenres() -> [String] {
        if self.isEmpty { return [] }
        return self
            .split { s in s == "(" || s == ")" }
            .flatMap { s in s.split(separator: "/") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
