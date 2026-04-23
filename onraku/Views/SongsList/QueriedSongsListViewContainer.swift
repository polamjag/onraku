//
//  QueriedSongsListViewContainer.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import MediaPlayer
import SwiftUI

private func getTertiaryInfo(of item: MPMediaItem, withHint: SongsSortKey)
  -> String?
{
  switch withHint {
  case .none, .title, .artist:
    return nil
  case .album:
    return item.albumTitle ?? "-"
  case .genre:
    return item.genre ?? "-"
  case .userGrouping:
    return item.userGrouping ?? "-"
  case .addedAt:
    return item.dateAdded.formatted(date: .abbreviated, time: .omitted)
  case .bpm:
    return item.beatsPerMinute == 0 ? "-" : String(item.beatsPerMinute)
  case .playCountAsc, .playCountDesc:
    return "\(item.playCount) plays"
  case .playCountPerDayDesc, .playCountPerDayAsc:
    return
      "\(item.playCount) / \(Int(item.dateAdded.distance(to: Date()) / 60 / 60 / 24))d = \(String(format: "%.4f", Double(item.playCount) / (item.dateAdded.distance(to: Date()) / 60 / 60 / 24)))"
  }
}

struct PredicateItemView: View {
  var predicate: MyMPMediaPropertyPredicate
  @State var resultCount: Int?

  var shouldBeDisabled: Bool {
    if let resultCount = resultCount {
      return resultCount == 0
    } else {
      return false
    }
  }

  var body: some View {
    if !shouldBeDisabled {
      NavigationLink {
        QueriedSongsListViewContainer(songsList: predicateToSongsList(predicate))
      } label: {
        SongsCollectionItemView(
          title: predicate.value as? String ?? "<unknown>",
          secondaryText: predicate.humanReadableForProperty,

          systemImage: predicate.systemImageNameForProperty,
          itemsCount: resultCount
        )
      }.disabled(shouldBeDisabled).task {
        let res = await getSongsByPredicate(predicate: predicate)
        resultCount = res.count
      }
    }
  }
}

struct QueriedSongsListViewContainer: View {
  var songsList: SongsList
  
  @State var sortOrder: SongsSortKey = .none
  
  @State var isSearchHintSectionExpanded: Bool = false

  init(songsList: SongsList) {
    self.songsList = songsList
  }

  init(
    title: String? = nil,
    songs: [MPMediaItem],
    predicates: [MyMPMediaPropertyPredicate] = []
  ) {
    self.songsList = SongsListLoaded(
      loadedSongs: songs,
      title: title ?? "Search Result",
      predicates: predicates
    )
  }

  init(filterPredicate: MyMPMediaPropertyPredicate, title: String? = nil) {
    self.songsList = SongsListFromPredicates(
      predicates: [filterPredicate],
      customTitle: title ?? (filterPredicate.value as? String)
    )
  }
  
  var body: some View {
    List {
      if songsList.shouldShowSearchCriteria {
        Section(
          content: {
            Button(action: {
              withAnimation { isSearchHintSectionExpanded.toggle() }
            }) {
              Text(
                isSearchHintSectionExpanded
                ? "Hide Search Criteria"
                : "Show \(songsList.searchCriteria()?.count ?? 0) Search Criteria"
              )
            }
            
            if isSearchHintSectionExpanded {
              ForEach(songsList.searchCriteria() ?? []) { predicate in
                PredicateItemView(predicate: predicate, resultCount: 0)
              }
            }
          })
      }
      
      if songsList.songs().isEmpty {
        LoadingCellView()
      } else {
        Section(footer: Text("\(songsList.songs().count) songs")) {
          ForEach(songsList.songs()) { song in
            NavigationLink {
              SongDetailView(song: song)
            } label: {
              SongItemView(
                title: song.title,
                secondaryText: song.artist,
                tertiaryText: getTertiaryInfo(of: song, withHint: sortOrder),
                artwork: song.artwork
              ).contextMenu {
                PlayableItemsMenuView(target: .one(song))
              }
            }
          }
        }
      }
    }.navigationTitle(songsList.title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          Menu {
            Divider()
            
            // todo: sort
            PlayableItemsMenuView(target: .array(songsList.songs()))
            
            Menu {
              Picker("sort by", selection: $sortOrder) {
                ForEach(SongsSortKey.allCases, id: \.self) { value in
                  Text(value.rawValue).tag(value)
                }
              }
            } label: {
              Label(
                "Sort Order: \(sortOrder.rawValue)",
                systemImage: "arrow.up.arrow.down")
            }
          } label: {
            Image(systemName: "ellipsis.circle")
          }
        }
      }
  }
}

struct QueriedSongsListViewContainer_Previews: PreviewProvider {
  static var previews: some View {
    QueriedSongsListViewContainer(
      songsList: SongsListFixed(fixedSongs: [], title: "dummy"),
    )
  }
}
