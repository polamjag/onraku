//
//  PlayableContentMenuView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import MediaPlayer
import SwiftUI

enum PlayableItems {
    case array([MPMediaItem])
    case enumSeq([EnumeratedSequence<[MPMediaItem]>.Element])

    func asArray() -> [MPMediaItem] {
        switch self {
        case .array(let arr):
            return arr
        case .enumSeq(let en):
            return en.map { _, x in x }
        }
    }

    var count: Int {
        switch self {
        case .array(let arr):
            return arr.count
        case .enumSeq(let en):
            return en.count
        }
    }
}

struct PlayableItemsMenuView: View {
    var target: PlayableItems
    var body: some View {
        Button(action: {
            playMediaItems(items: target.asArray())
        }) {
            Label(target.count > 1 ? "Play All Now" : "Play Now", systemImage: "play")
        }
        if target.count > 1 {
            Button(action: {
                playMediaItems(items: target.asArray().shuffled())
            }) {
                Label("Shuffle All Now", systemImage: "shuffle")
            }
        }
        Divider()
        Button(action: {
            prependMediaItems(items: target.asArray())
        }) {
            Label(
                target.count > 1 ? "Play All Next" : "Play Next",
                systemImage: "text.insert")
        }
        Button(action: {
            appendMediaItems(items: target.asArray())
        }) {
            Label(
                target.count > 1 ? "Play All Last" : "Play Last",
                systemImage: "text.append")
        }
    }
}

struct PlayableItemsAboveAndBelowMenuView: View {
    var target: [EnumeratedSequence<[MPMediaItem]>.Element]
    var currentIndex: Int

    private enum OperationPatterns: String, CaseIterable, Identifiable {
        case thisAndAbove, thisAndBelow

        func getTargets(target: [EnumeratedSequence<[MPMediaItem]>.Element], currentIndex: Int)
            -> [MPMediaItem]
        {
            switch self {
            case .thisAndAbove:
                return target.map { _, x in x }.thisAndAbove(at: currentIndex)
            case .thisAndBelow:
                return target.map { _, x in x }.thisAndBelow(at: currentIndex)
            }
        }

        var id: String { rawValue }

        var menuLabel: (String, String) {
            switch self {
            case .thisAndAbove:
                return ("This and Above...", "rectangle.portrait.topthird.inset.filled")
            case .thisAndBelow:
                return ("This and Below...", "rectangle.portrait.bottomthird.inset.filled")
            }
        }
    }

    var body: some View {
        if currentIndex != 0 && target.count != currentIndex - 1 {
            ForEach(OperationPatterns.allCases) { pattern in
                Menu {
                    PlayableItemsMenuView(
                        target: .array(
                            pattern.getTargets(target: target, currentIndex: currentIndex)))
                } label: {
                    Label(pattern.menuLabel.0, systemImage: pattern.menuLabel.1)
                }
            }
        }
    }
}

struct PlayableContentMenuView_Previews: PreviewProvider {
    static var previews: some View {
        PlayableItemsMenuView(target: .array([]))
    }
}
