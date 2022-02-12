//
//  PlayableContentMenuView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import SwiftUI
import MediaPlayer

struct PlayableContentMenuView: View {
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
            Label(target.count > 1 ? "Prepend All to Queue" : "Prepend to Queue", systemImage: "arrow.turn.up.right")
        }
        Button(action: {
            appendMediaItems(items: target)
        }) {
            Label(target.count > 1 ? "Append All to Queue" : "Append to Queue", systemImage: "arrow.turn.down.right")
        }
    }
}

struct PlayableContentMenuView_Previews: PreviewProvider {
    static var previews: some View {
        PlayableContentMenuView(target: [])
    }
}
