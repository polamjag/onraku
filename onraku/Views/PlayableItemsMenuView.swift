//
//  PlayableContentMenuView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import MediaPlayer
import SwiftUI

enum PlayableItems {
    case one(MPMediaItem)
    case array([MPMediaItem])
    case enumSeq([EnumeratedSequence<[MPMediaItem]>.Element])

    func asArray() -> [MPMediaItem] {
        switch self {
        case .one(let item):
            return [item]
        case .array(let arr):
            return arr
        case .enumSeq(let en):
            return en.map { _, x in x }
        }
    }

    var count: Int {
        switch self {
        case .one:
            return 1
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
            Task.detached {
                let items = target.asArray()
                playMediaItems(items: items)
                await showToastWithMessage("\(items.count) Items Playing", systemImage: "play.fill")
            }
        }) {
            Label(target.count > 1 ? "Play All Now" : "Play Now", systemImage: "play")
        }
        if target.count > 1 {
            Button(action: {
                Task.detached {
                    let items = target.asArray().shuffled()
                    playMediaItems(items: items)
                    await showToastWithMessage(
                        "\(items.count) Items Shuffing", systemImage: "shuffle")
                }
            }) {
                Label("Shuffle All Now", systemImage: "shuffle")
            }
        }
        Divider()
        Button(action: {
            Task.detached {
                let items = target.asArray()
                prependMediaItems(items: items)
                await showToastWithMessage(
                    "\(items.count) Items Playing Next", systemImage: "text.insert")

            }
        }) {
            Label(
                target.count > 1 ? "Play All Next" : "Play Next",
                systemImage: "text.insert")
        }
        Button(action: {
            Task.detached {
                let items = target.asArray()
                appendMediaItems(items: items)
                await showToastWithMessage(
                    "\(items.count) Items Playing Last", systemImage: "text.append")
            }
        }) {
            Label(
                target.count > 1 ? "Play All Last" : "Play Last",
                systemImage: "text.append")
        }
    }
}

struct PlayableContentMenuView_Previews: PreviewProvider {
    static var previews: some View {
        PlayableItemsMenuView(target: .array([]))
    }
}
