//
//  PlayableContentMenuView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import MediaPlayer
import SwiftUI

struct PlayableItemsMenuView: View {
    var target: [MPMediaItem]
    var body: some View {
        Button(action: {
            playMediaItems(items: target)
        }) {
            Label(target.count > 1 ? "Play All Now" : "Play Now", systemImage: "play")
        }
        Divider()
        Button(action: {
            prependMediaItems(items: target)
        }) {
            Label(
                target.count > 1 ? "Prepend All to Queue" : "Prepend to Queue",
                systemImage: "text.insert")
        }
        Button(action: {
            appendMediaItems(items: target)
        }) {
            Label(
                target.count > 1 ? "Append All to Queue" : "Append to Queue",
                systemImage: "text.append")
        }
    }
}

struct PlayableContentMenuView_Previews: PreviewProvider {
    static var previews: some View {
        PlayableItemsMenuView(target: [])
    }
}
