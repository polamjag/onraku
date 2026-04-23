//
//  PlayableContentMenuView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import MediaPlayer
import SwiftUI

struct PlayableItemsMenuView: View {
  let itemsCount: Int
  let itemsProvider: () -> [MPMediaItem]

  init(item: MPMediaItem) {
    itemsCount = 1
    itemsProvider = { [item] }
  }

  init(itemsCount: Int, itemsProvider: @escaping () -> [MPMediaItem]) {
    self.itemsCount = itemsCount
    self.itemsProvider = itemsProvider
  }

  init(enumeratedItems: [EnumeratedSequence<[MPMediaItem]>.Element]) {
    itemsCount = enumeratedItems.count
    itemsProvider = { enumeratedItems.map { _, item in item } }
  }

  var body: some View {
    Button(action: {
      let items = itemsProvider()
      Task.detached {
        playMediaItems(items: items)
        await showToastWithMessage(
          "Playing \(items.count) Songs", systemImage: "play.fill")
      }
    }) {
      Label(itemsCount > 1 ? "Play All Now" : "Play Now", systemImage: "play")
      Color.clear
    }
    if itemsCount > 1 {
      Button(action: {
        let items = itemsProvider().shuffled()
        Task.detached {
          playMediaItems(items: items)
          await showToastWithMessage(
            "Shuffing \(items.count) Songs", systemImage: "shuffle")
        }
      }) {
        Label("Shuffle All Now", systemImage: "shuffle")
      }
    }
    Divider()
    Button(action: {
      let items = itemsProvider()
      Task.detached {
        prependMediaItems(items: items)
        await showToastWithMessage(
          "Playing \(items.count) Songs Next", systemImage: "text.insert")

      }
    }) {
      Label(
        itemsCount > 1 ? "Play All Next" : "Play Next",
        systemImage: "text.insert")
    }
    Button(action: {
      let items = itemsProvider()
      Task.detached {
        appendMediaItems(items: items)
        await showToastWithMessage(
          "Playing \(items.count) Songs Last", systemImage: "text.append")
      }
    }) {
      Label(
        itemsCount > 1 ? "Play All Last" : "Play Last",
        systemImage: "text.append")
    }
  }
}

struct PlayableContentMenuView_Previews: PreviewProvider {
  static var previews: some View {
    PlayableItemsMenuView(itemsCount: 0) { [] }
  }
}
