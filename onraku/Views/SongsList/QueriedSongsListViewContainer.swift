//
//  QueriedSongsListViewContainer.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import MediaPlayer
import SwiftUI

struct PredicateItemView: View {
    var predicate: MyMPMediaPropertyPredicate
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    var resultCountLoader: (MyMPMediaPropertyPredicate) async -> Int = loadPredicateResultCount

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
            }.task {
                resultCount = await resultCountLoader(predicate)
            }.swipeActions {
                if let onDelete {
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                }

                if let onEdit {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }.contextMenu {
                if let onEdit {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                }

                if let onDelete {
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
}

private func loadPredicateResultCount(_ predicate: MyMPMediaPropertyPredicate) async -> Int {
    (await getSongsByPredicate(predicate: predicate)).count
}

private struct PredicatePropertyChoice: Identifiable {
    let property: String
    let title: String
    let systemImage: String?

    var id: String {
        property
    }
}

private let editablePredicateProperties: [PredicatePropertyChoice] = [
    PredicatePropertyChoice(
        property: MPMediaItemPropertyTitle,
        title: "Title",
        systemImage: "music.note"
    ),
    PredicatePropertyChoice(
        property: MPMediaItemPropertyArtist,
        title: "Artist",
        systemImage: "music.microphone"
    ),
    PredicatePropertyChoice(
        property: MPMediaItemPropertyAlbumArtist,
        title: "Album Artist",
        systemImage: "music.microphone"
    ),
    PredicatePropertyChoice(
        property: MPMediaItemPropertyAlbumTitle,
        title: "Album",
        systemImage: "square.stack"
    ),
    PredicatePropertyChoice(
        property: MPMediaItemPropertyGenre,
        title: "Genre",
        systemImage: "guitars"
    ),
    PredicatePropertyChoice(
        property: MPMediaItemPropertyComposer,
        title: "Composer",
        systemImage: "music.quarternote.3"
    ),
    PredicatePropertyChoice(
        property: MPMediaItemPropertyUserGrouping,
        title: "User Grouping",
        systemImage: "latch.2.case"
    ),
]

private struct PredicateComparisonChoice: Identifiable {
    let comparison: MPMediaPredicateComparison
    let title: String

    var id: Int {
        comparison.hashValue
    }
}

private let editablePredicateComparisons: [PredicateComparisonChoice] = [
    PredicateComparisonChoice(comparison: .equalTo, title: "Equals"),
    PredicateComparisonChoice(comparison: .contains, title: "Contains"),
]

private struct PredicateEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let predicate: MyMPMediaPropertyPredicate
    let onSave: (MyMPMediaPropertyPredicate) -> Void

    @State private var valueText: String
    @State private var selectedProperty: String
    @State private var selectedComparison: MPMediaPredicateComparison

    init(
        predicate: MyMPMediaPropertyPredicate,
        onSave: @escaping (MyMPMediaPropertyPredicate) -> Void
    ) {
        self.predicate = predicate
        self.onSave = onSave
        _valueText = State(initialValue: Self.valueText(from: predicate.value))
        _selectedProperty = State(initialValue: predicate.forProperty)
        _selectedComparison = State(initialValue: predicate.comparisonType)
    }

    private var trimmedValueText: String {
        valueText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Value", text: $valueText)
                        .textInputAutocapitalization(.never)
                }

                Section {
                    Picker("Property", selection: $selectedProperty) {
                        ForEach(editablePredicateProperties) { property in
                            Label(
                                property.title,
                                systemImage: property.systemImage ?? "line.3.horizontal"
                            )
                            .tag(property.property)
                        }
                    }

                    Picker("Match", selection: $selectedComparison) {
                        ForEach(editablePredicateComparisons) { comparison in
                            Text(comparison.title).tag(comparison.comparison)
                        }
                    }
                }
            }
            .navigationTitle("Edit Criterion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(
                            MyMPMediaPropertyPredicate(
                                value: trimmedValueText,
                                forProperty: selectedProperty,
                                comparisonType: selectedComparison
                            )
                        )
                        dismiss()
                    }
                    .disabled(trimmedValueText.isEmpty)
                }
            }
        }
    }

    private static func valueText(from value: Any?) -> String {
        if let value = value as? String {
            return value
        }

        if let value {
            return "\(value)"
        }

        return ""
    }
}

struct QueriedSongsListViewContainer: View {
    @Environment(\.editMode) private var editMode

    @StateObject private var viewModel: QueriedSongsListViewModel
    private let predicateResultCountLoader: (MyMPMediaPropertyPredicate) async -> Int

    @State var isSearchHintSectionExpanded: Bool = false
    @State private var editingPredicate: MyMPMediaPropertyPredicate?

    init(
        songsList: SongsList,
        isSearchHintSectionExpanded: Bool = false,
        predicateResultCountLoader: @escaping (MyMPMediaPropertyPredicate) async -> Int =
            loadPredicateResultCount
    ) {
        _viewModel = StateObject(
            wrappedValue: QueriedSongsListViewModel(songsList: songsList)
        )
        self.predicateResultCountLoader = predicateResultCountLoader
        _isSearchHintSectionExpanded = State(initialValue: isSearchHintSectionExpanded)
    }

    init(
        title: String? = nil,
        songs: [MPMediaItem],
        predicates: [MyMPMediaPropertyPredicate] = []
    ) {
        self.init(
            songsList: SongsListLoaded(
                loadedSongs: songs,
                title: title ?? "Search Result",
                predicates: predicates
            )
        )
    }

    init(filterPredicate: MyMPMediaPropertyPredicate, title: String? = nil) {
        self.init(
            songsList: SongsListFromPredicates(
                predicates: [filterPredicate],
                customTitle: title ?? (filterPredicate.value as? String)
            )
        )
    }

    private var searchCriteriaToggleTitle: String {
        if isSearchHintSectionExpanded {
            return "Hide Search Criteria"
        }

        let count = viewModel.searchCriteria.count
        let noun = count == 1 ? "Criterion" : "Criteria"
        return "Show \(count) Search \(noun)"
    }

    private var isEditingSearchCriteria: Bool {
        editMode?.wrappedValue.isEditing == true
    }

    var body: some View {
        List {
            if viewModel.shouldShowSearchCriteria {
                Section(
                    content: {
                        Button(action: {
                            withAnimation { isSearchHintSectionExpanded.toggle() }
                        }) {
                            Text(searchCriteriaToggleTitle)
                        }

                        if isSearchHintSectionExpanded {
                            if isEditingSearchCriteria {
                                Button {
                                    Task {
                                        await viewModel.restoreSearchCriteria()
                                    }
                                } label: {
                                    Label(
                                        "Restore All Criteria",
                                        systemImage: "arrow.counterclockwise")
                                }
                                .disabled(!viewModel.canRestoreSearchCriteria)
                            }

                            ForEach(viewModel.searchCriteria) { predicate in
                                PredicateItemView(
                                    predicate: predicate,
                                    onEdit: {
                                        editingPredicate = predicate
                                    },
                                    onDelete: {
                                        Task {
                                            await viewModel.removeSearchCriterion(predicate)
                                        }
                                    },
                                    resultCountLoader: predicateResultCountLoader
                                )
                            }
                            .onDelete { offsets in
                                Task {
                                    await viewModel.removeSearchCriteria(atOffsets: offsets)
                                }
                            }
                        }
                    })
            }

            if viewModel.loadingState == .initial || viewModel.loadingState.isLoading {
                LoadingCellView()
            } else {
                Section(footer: Text("\(viewModel.songs.count) songs")) {
                    ForEach(viewModel.displayedSongs) { song in
                        NavigationLink {
                            SongDetailView(song: song)
                        } label: {
                            SongItemView(
                                title: song.title,
                                secondaryText: song.artist,
                                tertiaryText: viewModel.tertiaryInfo(for: song),
                                artwork: song.artwork
                            )
                        }
                        .contextMenu {
                            PlayableItemsMenuView(item: song)
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
        .refreshable {
            await viewModel.reload()
        }
        .onChange(of: isEditingSearchCriteria) { _, isEditing in
            guard isEditing, viewModel.shouldShowSearchCriteria, !isSearchHintSectionExpanded else {
                return
            }

            withAnimation {
                isSearchHintSectionExpanded = true
            }
        }
        .sheet(item: $editingPredicate) { predicate in
            PredicateEditorView(predicate: predicate) { updated in
                Task {
                    await viewModel.updateSearchCriterion(predicate, with: updated)
                }
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if viewModel.shouldShowSearchCriteria {
                    EditButton()
                }

                Menu {
                    Divider()

                    PlayableItemsMenuView(itemsCount: viewModel.songs.count) {
                        viewModel.songs
                    }

                    Menu {
                        Picker(
                            "sort by",
                            selection: Binding(
                                get: { viewModel.sortOrder },
                                set: { viewModel.setSortOrder($0) }
                            )
                        ) {
                            ForEach(SongsSortKey.allCases, id: \.self) { value in
                                Text(value.rawValue).tag(value)
                            }
                        }
                    } label: {
                        Label(
                            "Sort Order: \(viewModel.sortOrder.rawValue)",
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
        NavigationView {
            QueriedSongsListViewContainer(
                songsList: SongsListFixed(fixedSongs: [], title: "Recently Added")
            )
        }
        .previewDisplayName("Empty Songs")

        NavigationView {
            QueriedSongsListViewContainer(
                songsList: SongsListLoaded(
                    loadedSongs: [],
                    title: "Quick Dig",
                    predicates: previewPredicates
                ),
                isSearchHintSectionExpanded: true,
                predicateResultCountLoader: { _ in 12 }
            )
        }
        .previewDisplayName("Search Criteria")
    }

    private static let previewPredicates = [
        MyMPMediaPropertyPredicate(
            value: "House", forProperty: MPMediaItemPropertyGenre),
        MyMPMediaPropertyPredicate(
            value: "Mika River", forProperty: MPMediaItemPropertyArtist,
            comparisonType: .contains),
    ]
}
