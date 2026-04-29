//
//  SongsListViewContainer.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import MediaPlayer
import SwiftUI

struct SongsCollectionsListView: View {
  var title: String
  @StateObject private var viewModel: SongsCollectionsListViewModel

  init(
    type: CollectionTypes,
    title: String,
    viewModel: SongsCollectionsListViewModel? = nil
  ) {
    self.title = title
    _viewModel = StateObject(
      wrappedValue: viewModel ?? SongsCollectionsListViewModel(type: type)
    )
  }

  var body: some View {
    List {
      if viewModel.loadState == .loading || viewModel.loadState == .initial {
        LoadingCellView()
      }

      ForEach(viewModel.collections) { collection in
        NavigationLink {
          QueriedSongsListViewContainer(songsList: collection.songsList())
        } label: {
          HStack {
            SongsCollectionItemView(
              title: collection.name,
              showLoading: false
            )
          }.lineLimit(1)
        }
      }
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
    }.task {
      await viewModel.loadIfNeeded()
    }.refreshable {
      await viewModel.reload()
    }
  }
}

//struct SongsListViewContainer_Previews: PreviewProvider {
//    static var previews: some View {
//        SongsListViewContainer(loader: ()  -> [Playlist] {  [] })
//    }
//}
