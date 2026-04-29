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

      if viewModel.type == .playlist {
        ForEach(viewModel.visibleCollectionRows) { row in
          collectionRow(for: row)
        }
      } else {
        ForEach(viewModel.collections) { collection in
          collectionRow(for: collection)
        }
      }
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await viewModel.loadIfNeeded()
    }
    .refreshable {
      await viewModel.reload()
    }
  }

  @ViewBuilder
  private func collectionRow(for row: SongsCollectionTreeRow) -> some View {
    HStack(spacing: 8) {
      NavigationLink {
        QueriedSongsListViewContainer(songsList: row.node.songsList())
      } label: {
        if row.hasChildren {
          Button {
            withAnimation {
              viewModel.toggleExpansion(of: row.id)
            }
          } label: {
            Image(systemName: "chevron.right")
              .frame(width: 32, height: 32)
          }
          .buttonStyle(.borderless)
          .accessibilityLabel(
            row.isExpanded
            ? "Collapse \(row.node.collection.name)"
            : "Expand \(row.node.collection.name)"
          ).rotationEffect(.degrees(row.isExpanded ? 90 : 0))
        }
        SongsCollectionItemView(
          title: row.node.collection.name,
          secondaryText: secondaryText(for: row.node),
          systemImage: row.node.collection.isFolder ? "folder" : nil,
          showLoading: false
        )
      }
      .padding(.leading, CGFloat(row.depth) * 16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .lineLimit(1)
    }
  }

  private func secondaryText(for node: SongsCollectionTreeNode) -> String? {
    guard node.hasChildren else { return nil }
    let count = node.playableCollections.count
    return count == 1 ? "1 playlist" : "\(count) playlists"
  }

  private func collectionRow(for collection: SongsCollection) -> some View {
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
}

//struct SongsListViewContainer_Previews: PreviewProvider {
//    static var previews: some View {
//        SongsListViewContainer(loader: ()  -> [Playlist] {  [] })
//    }
//}
