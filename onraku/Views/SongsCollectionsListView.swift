//
//  SongsListViewContainer.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import MediaPlayer
import SwiftUI

enum LoadingState {
    case initial, loading, loaded, loadingByPullToRefresh
}

struct SongsCollectionsListView: View {
    @State @MainActor var collections: [SongsCollection] = []
    @State var loadState: LoadingState = .initial

    var type: CollectionType
    var title: String

    func loadCollections() async {
        await MainActor.run {
            loadState = .loading
        }
        let gotCollections = await loadSongsCollectionsOf(type)
        await MainActor.run {
            collections = gotCollections
            loadState = .loaded
        }
    }

    var body: some View {
        List {
            if loadState == .loading || loadState == .initial {
                LoadingCellView()
            }

            ForEach(collections) { collection in
                NavigationLink {
                    QueriedSongsListViewContainer(
                        filterPredicate: collection.getFilterPredicate(),
                        songs: collection.items
                    )
                } label: {
                    HStack {
                        SongsCollectionItemView(
                            title: collection.name,
                            itemsCount: collection.items.count,
                            isLoading: false
                        )
                    }.lineLimit(1).contextMenu {
                        PlayableItemsMenuView(
                            target: .array(collection.items))
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }.task {
            if collections.isEmpty {
                await loadCollections()
            }
        }.refreshable {
            await loadCollections()
        }
    }
}

//struct SongsListViewContainer_Previews: PreviewProvider {
//    static var previews: some View {
//        SongsListViewContainer(loader: ()  -> [Playlist] {  [] })
//    }
//}
