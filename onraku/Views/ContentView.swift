//
//  ContentView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/11.
//

import MediaPlayer
import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            TabView {
                NavigationView {
                    List {
                        ForEach(CollectionType.allCases, id: \.self) { type in
                            NavigationLink {
                                SongsCollectionsListView(type: type, title: type.rawValue)
                            } label: {
                                Label(type.rawValue, systemImage: type.systemImageName)
                            }
                        }
                    }.navigationTitle("Library")
                        .navigationBarTitleDisplayMode(.inline)
                        .listStyle(.insetGrouped)
                }.tabItem {
                    Image(systemName: "music.quarternote.3")
                    Text("Library")
                }

                NavigationView {
                    NowPlayingViewContainer()
                        .navigationBarTitleDisplayMode(.inline)
                        .listStyle(.insetGrouped)
                }.tabItem {
                    Image(systemName: "play")
                    Text("Now Playing")
                }
            }
            ToastView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
