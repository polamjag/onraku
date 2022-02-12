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
            Label("Play All Now", systemImage: "play")
        }
        Divider()
        Button(action: {
            prependMediaItems(items: target)
        }) {
            Label("Prepend All to Queue", systemImage: "arrow.turn.up.right")
        }
        Button(action: {
            appendMediaItems(items: target)
        }) {
            Label("Append All to Queue", systemImage: "arrow.turn.down.right")
        }
    }
}

struct PlayableContentMenuView_Previews: PreviewProvider {
    static var previews: some View {
        PlayableContentMenuView(target: [])
    }
}
