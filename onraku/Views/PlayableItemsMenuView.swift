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

    var thisAndAbove: [MPMediaItem] {
        target.map { _, x in x }.thisAndAbove(at: currentIndex)
    }

    var thisAndBelow: [MPMediaItem] {
        target.map { _, x in x }.thisAndBelow(at: currentIndex)
    }

    var body: some View {
        Menu {
            Button(action: {
                playMediaItems(items: thisAndAbove)
            }) {
                Label("Play These Songs", systemImage: "play")
            }
            Button(action: {
                prependMediaItems(items: thisAndAbove)
            }) {
                Label(
                    "Play These Songs Next",
                    systemImage: "text.insert")
            }
            Button(action: {
                appendMediaItems(items: thisAndAbove)
            }) {
                Label(
                    "Play These Songs Last",
                    systemImage: "text.append")
            }
        } label: {
            Label("This and Above...", systemImage: "arrow.down.to.line")
        }

        Menu {
            Button(action: {
                playMediaItems(items: thisAndBelow)
            }) {
                Label("Play These Songs", systemImage: "play")
            }
            Button(action: {
                prependMediaItems(items: thisAndBelow)
            }) {
                Label(
                    "Play These Songs Next",
                    systemImage: "text.insert")
            }
            Button(action: {
                appendMediaItems(items: thisAndBelow)
            }) {
                Label(
                    "Play These Songs Last",
                    systemImage: "text.append")
            }
        } label: {
            Label("This and Below...", systemImage: "arrow.down")
        }
    }
}

struct PlayableContentMenuView_Previews: PreviewProvider {
    static var previews: some View {
        PlayableItemsMenuView(target: .array([]))
    }
}
