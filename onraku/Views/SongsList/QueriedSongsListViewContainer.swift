//
//  QueriedSongsListViewContainer.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import Foundation
import MediaPlayer
import SwiftUI
import UIKit

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
                    itemsCount: resultCount,
                    itemsCountDisplayMode: .reservingSpace(maxDigits: 5)
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
    @EnvironmentObject private var trackPreviewController: TrackPreviewController

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
                        PreviewableSongRow(
                            song: song,
                            tertiaryText: viewModel.tertiaryInfo(for: song)
                        )
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
        .scrollDisabled(trackPreviewController.previewingItemID != nil)
        .onDisappear {
            if trackPreviewController.previewingItemID != nil {
                trackPreviewController.stopPreview()
            }
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
        .overlay {
            TrackPreviewHUDOverlay()
        }
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

private struct PreviewableSongRow: View {
    @EnvironmentObject private var trackPreviewController: TrackPreviewController

    let song: MPMediaItem
    let tertiaryText: String?

    var body: some View {
        HStack(spacing: 8) {
            NavigationLink {
                SongDetailView(song: song)
            } label: {
                SongItemView(
                    title: song.title,
                    secondaryText: song.artist,
                    tertiaryText: tertiaryText,
                    artwork: song.artwork
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .background(
                    TrackPreviewTouchRecognizer(
                        onBegan: { location, screenWidth in
                            updatePreviewLocation(location)
                            startPreviewIfNeeded()
                            seekPreview(at: location, screenWidth: screenWidth)
                        },
                        onChanged: { location, screenWidth in
                            seekPreview(at: location, screenWidth: screenWidth)
                        },
                        onEnded: {
                            stopPreviewIfNeeded()
                        }
                    )
                )
            }

            Menu {
                PlayableItemsMenuView(item: song)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .imageScale(.large)
                    .foregroundColor(.secondary)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Playback Options")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            Color.accentColor
                .opacity(isPreviewing ? 0.13 : 0)
                .animation(.easeInOut(duration: 0.15), value: isPreviewing)
        }
    }

    private var isPreviewing: Bool {
        trackPreviewController.previewingItemID == song.persistentID
    }

    private func startPreviewIfNeeded() {
        guard !isPreviewing else { return }
        trackPreviewController.startPreview(item: song)
    }

    private func stopPreviewIfNeeded() {
        guard isPreviewing else { return }
        trackPreviewController.stopPreview()
    }

    private func updatePreviewLocation(_ location: CGPoint) {
        trackPreviewController.updateTouchLocation(location)
    }

    private func seekPreview(at location: CGPoint, screenWidth: CGFloat) {
        guard isPreviewing, screenWidth > 0 else { return }
        trackPreviewController.seekPreview(
            toFraction: TrackPreviewScreenSeekMapper.fraction(
                forX: location.x,
                screenWidth: screenWidth
            )
        )
    }
}

enum TrackPreviewScreenSeekMapper {
    // UI tuning: positions inside this distance from either edge map to
    // the beginning/end of the preview, so the finger does not need to
    // reach the physical screen edge.
    static let defaultEdgeMargin: CGFloat = 84

    static func fraction(
        forX x: CGFloat,
        screenWidth: CGFloat,
        edgeMargin: CGFloat = defaultEdgeMargin
    ) -> CGFloat {
        guard screenWidth > 0 else { return 0 }

        let usableMargin = min(max(0, edgeMargin), screenWidth / 2)
        let usableWidth = max(1, screenWidth - usableMargin * 2)
        let fraction = (x - usableMargin) / usableWidth
        return min(max(0, fraction), 1)
    }
}

enum TrackPreviewHUDLayout {
    // Main HUD width. Keep this in sync with the center clamping expectation in previews.
    static let hudWidth: CGFloat = 320
    static let hudVerticalOffset: CGFloat = 105
    static let hudVerticalInset: CGFloat = 80

    // Seek guide tuning. The horizontal margin intentionally mirrors the seek mapper.
    static let seekGuideVerticalInset: CGFloat = 32
    static let seekGuideTrackHeight: CGFloat = 7
    static let seekGuideMarkerWidth: CGFloat = 3
    static let seekGuideMarkerHeight: CGFloat = 38
    static let seekGuideKnobSize: CGFloat = 22

    static func hudPosition(
        containerSize: CGSize,
        containerGlobalFrame: CGRect,
        touchLocation: CGPoint?
    ) -> CGPoint {
        let fallbackTouch = CGPoint(
            x: containerGlobalFrame.midX,
            y: containerGlobalFrame.midY
        )
        let touchLocation = touchLocation ?? fallbackTouch
        let localY = touchLocation.y - containerGlobalFrame.minY
        let yOffset = localY > 180 ? -hudVerticalOffset : hudVerticalOffset
        let y = min(
            max(localY + yOffset, hudVerticalInset),
            max(hudVerticalInset, containerSize.height - hudVerticalInset)
        )
        return CGPoint(x: containerSize.width / 2, y: y)
    }

    static func seekGuideMargin(containerWidth: CGFloat) -> CGFloat {
        min(TrackPreviewScreenSeekMapper.defaultEdgeMargin, containerWidth / 2)
    }

    static func seekGuideWidth(containerWidth: CGFloat) -> CGFloat {
        let margin = seekGuideMargin(containerWidth: containerWidth)
        return max(1, containerWidth - margin * 2)
    }

    static func seekGuideX(
        containerSize: CGSize,
        containerGlobalFrame: CGRect,
        touchLocation: CGPoint?
    ) -> CGFloat {
        let margin = seekGuideMargin(containerWidth: containerSize.width)
        let fallbackX = containerGlobalFrame.midX
        let globalX = touchLocation?.x ?? fallbackX
        let localX = globalX - containerGlobalFrame.minX
        return min(
            max(localX, margin),
            max(margin, containerSize.width - margin)
        )
    }

    static func seekGuideY(
        containerSize: CGSize,
        containerGlobalFrame: CGRect,
        touchLocation: CGPoint?
    ) -> CGFloat {
        let fallbackY = containerGlobalFrame.midY
        let globalY = touchLocation?.y ?? fallbackY
        let localY = globalY - containerGlobalFrame.minY
        return min(
            max(localY, seekGuideVerticalInset),
            max(seekGuideVerticalInset, containerSize.height - seekGuideVerticalInset)
        )
    }
}

private struct TrackPreviewTouchRecognizer: UIViewRepresentable {
    let onBegan: (CGPoint, CGFloat) -> Void
    let onChanged: (CGPoint, CGFloat) -> Void
    let onEnded: () -> Void

    func makeUIView(context: Context) -> TouchAttachmentView {
        let view = TouchAttachmentView(frame: .zero)
        view.backgroundColor = .clear
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: TouchAttachmentView, context: Context) {
        context.coordinator.onBegan = onBegan
        context.coordinator.onChanged = onChanged
        context.coordinator.onEnded = onEnded
        uiView.coordinator = context.coordinator
        context.coordinator.installRecognizer(from: uiView)
    }

    static func dismantleUIView(_ uiView: TouchAttachmentView, coordinator: Coordinator) {
        coordinator.uninstallRecognizer()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onBegan: onBegan, onChanged: onChanged, onEnded: onEnded)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onBegan: (CGPoint, CGFloat) -> Void
        var onChanged: (CGPoint, CGFloat) -> Void
        var onEnded: () -> Void

        private weak var sourceView: UIView?
        private weak var attachedView: UIView?
        private weak var scrollView: UIScrollView?
        private weak var navigationController: UINavigationController?
        private var previousScrollEnabled: Bool?
        private var disabledBackGestureStates: [GestureEnabledState] = []
        private var initialTouchLocation: CGPoint?
        private var isSeekingWithTouch = false
        private var recognizer: UILongPressGestureRecognizer?

        private let seekActivationDistance: CGFloat = 80

        init(
            onBegan: @escaping (CGPoint, CGFloat) -> Void,
            onChanged: @escaping (CGPoint, CGFloat) -> Void,
            onEnded: @escaping () -> Void
        ) {
            self.onBegan = onBegan
            self.onChanged = onChanged
            self.onEnded = onEnded
        }

        func installRecognizer(from sourceView: UIView) {
            guard let targetView = sourceView.previewGestureAttachmentTarget else {
                return
            }

            self.sourceView = sourceView
            guard attachedView !== targetView else {
                return
            }

            uninstallRecognizer()

            let recognizer = UILongPressGestureRecognizer(
                target: self,
                action: #selector(handleLongPress(_:))
            )
            recognizer.minimumPressDuration = 0.45
            recognizer.allowableMovement = 24
            recognizer.cancelsTouchesInView = true
            recognizer.delaysTouchesBegan = false
            recognizer.delaysTouchesEnded = false
            recognizer.delegate = self
            targetView.addGestureRecognizer(recognizer)

            self.attachedView = targetView
            self.scrollView = targetView.enclosingScrollView
            self.navigationController = targetView.enclosingNavigationController
            self.recognizer = recognizer
        }

        func uninstallRecognizer() {
            restoreBackNavigation()
            restoreScrolling()
            if let recognizer, let attachedView {
                attachedView.removeGestureRecognizer(recognizer)
            }
            recognizer = nil
            attachedView = nil
            scrollView = nil
            navigationController = nil
        }

        @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
            guard let view = recognizer.view else { return }
            let window = view.window
            let location = recognizer.location(in: window)
            let screenWidth = window?.windowScene?.screen.bounds.width
                ?? window?.bounds.width
                ?? 1

            switch recognizer.state {
            case .began:
                navigationController = navigationController ?? view.enclosingNavigationController
                suspendScrolling()
                suspendBackNavigation()
                onBegan(location, screenWidth)
                initialTouchLocation = location
                isSeekingWithTouch = false
            case .changed:
                if shouldSeek(with: location) {
                    onChanged(location, screenWidth)
                }
            case .ended, .cancelled, .failed:
                onEnded()
                restoreBackNavigation()
                restoreScrolling()
                initialTouchLocation = nil
                isSeekingWithTouch = false
            default:
                break
            }
        }

        private func shouldSeek(with location: CGPoint) -> Bool {
            if isSeekingWithTouch {
                return true
            }

            guard let initialTouchLocation else {
                return false
            }

            let horizontalDistance = abs(location.x - initialTouchLocation.x)
            guard horizontalDistance >= seekActivationDistance else {
                return false
            }

            isSeekingWithTouch = true
            return true
        }

        private func suspendScrolling() {
            guard previousScrollEnabled == nil, let scrollView else {
                return
            }
            previousScrollEnabled = scrollView.isScrollEnabled
            scrollView.isScrollEnabled = false
        }

        private func restoreScrolling() {
            guard let previousScrollEnabled else {
                return
            }
            scrollView?.isScrollEnabled = previousScrollEnabled
            self.previousScrollEnabled = nil
        }

        private func suspendBackNavigation() {
            guard disabledBackGestureStates.isEmpty else {
                return
            }

            let window = attachedView?.window ?? sourceView?.window
            let candidates =
                ([navigationController?.interactivePopGestureRecognizer].compactMap { $0 }
                    + (window?.leftEdgePanGestureRecognizers ?? []))
                .reduce(into: [UIGestureRecognizer]()) { result, recognizer in
                    guard !result.contains(where: { $0 === recognizer }) else {
                        return
                    }
                    result.append(recognizer)
                }

            disabledBackGestureStates = candidates.map { recognizer in
                let state = GestureEnabledState(recognizer: recognizer)
                recognizer.isEnabled = false
                return state
            }
        }

        private func restoreBackNavigation() {
            for state in disabledBackGestureStates {
                state.recognizer?.isEnabled = state.wasEnabled
            }
            disabledBackGestureStates = []
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldReceive touch: UITouch
        ) -> Bool {
            guard let sourceView else {
                return true
            }

            let location = touch.location(in: sourceView)
            if !sourceView.bounds.isEmpty {
                return sourceView.bounds.contains(location)
            }

            guard let attachedView else {
                return true
            }
            let attachedLocation = touch.location(in: attachedView)
            return attachedLocation.x < attachedView.bounds.maxX - 52
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            if otherGestureRecognizer is UIScreenEdgePanGestureRecognizer {
                return false
            }

            return true
        }

        private final class GestureEnabledState {
            weak var recognizer: UIGestureRecognizer?
            let wasEnabled: Bool

            init(recognizer: UIGestureRecognizer) {
                self.recognizer = recognizer
                self.wasEnabled = recognizer.isEnabled
            }
        }
    }

    final class TouchAttachmentView: UIView {
        weak var coordinator: Coordinator?

        override func didMoveToSuperview() {
            super.didMoveToSuperview()
            coordinator?.installRecognizer(from: self)
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            coordinator?.installRecognizer(from: self)
        }
    }
}

private extension UIView {
    var previewGestureAttachmentTarget: UIView? {
        var currentView = superview
        while let view = currentView {
            if view is UITableViewCell || view is UICollectionViewCell {
                return view
            }
            currentView = view.superview
        }

        return superview
    }

    var enclosingScrollView: UIScrollView? {
        var currentView: UIView? = self
        while let view = currentView {
            if let scrollView = view as? UIScrollView {
                return scrollView
            }
            currentView = view.superview
        }

        return nil
    }

    var enclosingNavigationController: UINavigationController? {
        var currentResponder: UIResponder? = self
        while let responder = currentResponder {
            if let navigationController = responder as? UINavigationController {
                return navigationController
            }

            if let viewController = responder as? UIViewController,
                let navigationController = viewController.navigationController
            {
                return navigationController
            }

            currentResponder = responder.next
        }

        return nil
    }

    var leftEdgePanGestureRecognizers: [UIScreenEdgePanGestureRecognizer] {
        let ownRecognizers =
            (gestureRecognizers ?? []).compactMap { recognizer in
                recognizer as? UIScreenEdgePanGestureRecognizer
            }
            .filter { $0.edges.contains(.left) }

        return ownRecognizers + subviews.flatMap(\.leftEdgePanGestureRecognizers)
    }
}

private struct TrackPreviewHUDOverlay: View {
    @EnvironmentObject private var trackPreviewController: TrackPreviewController

    @State private var displayedHUD: TrackPreviewHUDSnapshot?
    @State private var isHUDVisible = false
    @State private var hideTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { proxy in
            if let displayedHUD {
                TrackPreviewSeekGuide(
                    touchLocation: displayedHUD.touchLocation,
                    containerSize: proxy.size,
                    containerGlobalFrame: proxy.frame(in: .global)
                )
                .opacity(isHUDVisible ? 1 : 0)
                .scaleEffect(x: 1, y: isHUDVisible ? 1 : 0.82, anchor: .center)

                TrackPreviewHUD(
                    title: displayedHUD.title,
                    artist: displayedHUD.artist,
                    artworkImage: displayedHUD.artworkImage,
                    progress: displayedHUD.progress,
                    location: hudLocation(
                        in: proxy,
                        touchLocation: displayedHUD.touchLocation
                    )
                )
                .opacity(isHUDVisible ? 1 : 0)
                .scaleEffect(isHUDVisible ? 1 : 0.94, anchor: .center)
            }
        }
        .onChange(of: trackPreviewController.previewingItemID) { _, itemID in
            if itemID != nil {
                showHUD()
            } else {
                hideHUD()
            }
        }
        .animation(
            .easeInOut(duration: 0.16),
            value: isHUDVisible
        )
    }

    private func showHUD() {
        guard let previewingItem = trackPreviewController.previewingItem else { return }
        hideTask?.cancel()
        displayedHUD = TrackPreviewHUDSnapshot(
            title: previewingItem.title,
            artist: previewingItem.artist,
            artworkImage: trackPreviewController.previewArtworkImage,
            progress: trackPreviewController.previewProgress,
            touchLocation: trackPreviewController.previewTouchLocation
        )
        isHUDVisible = true
    }

    private func hideHUD() {
        isHUDVisible = false
        hideTask?.cancel()
        hideTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 180_000_000)
            guard !Task.isCancelled else { return }
            displayedHUD = nil
            hideTask = nil
        }
    }

    private func hudLocation(
        in proxy: GeometryProxy,
        touchLocation: CGPoint?
    ) -> CGPoint {
        TrackPreviewHUDLayout.hudPosition(
            containerSize: proxy.size,
            containerGlobalFrame: proxy.frame(in: .global),
            touchLocation: touchLocation ?? trackPreviewController.previewTouchLocation
        )
    }
}

private struct TrackPreviewHUDSnapshot {
    let title: String?
    let artist: String?
    let artworkImage: UIImage?
    let progress: TrackPreviewProgress
    let touchLocation: CGPoint?
}

private struct TrackPreviewSeekGuide: View {
    let touchLocation: CGPoint?
    let containerSize: CGSize
    let containerGlobalFrame: CGRect

    var body: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .frame(
                    width: guideWidth,
                    height: TrackPreviewHUDLayout.seekGuideTrackHeight
                )
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(Color.white.opacity(0.34), lineWidth: 0.7)
                }
                .shadow(color: .black.opacity(0.10), radius: 10, y: 4)
                .position(x: containerSize.width / 2, y: guideY)

            Capsule(style: .continuous)
                .fill(Color.accentColor.opacity(0.92))
                .frame(
                    width: TrackPreviewHUDLayout.seekGuideMarkerWidth,
                    height: TrackPreviewHUDLayout.seekGuideMarkerHeight
                )
                .shadow(color: Color.accentColor.opacity(0.35), radius: 8, y: 2)
                .position(x: guideX, y: guideY)

            Circle()
                .fill(.regularMaterial)
                .frame(
                    width: TrackPreviewHUDLayout.seekGuideKnobSize,
                    height: TrackPreviewHUDLayout.seekGuideKnobSize
                )
                .overlay {
                    Circle()
                        .strokeBorder(Color.accentColor.opacity(0.55), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.14), radius: 8, y: 3)
                .position(x: guideX, y: guideY)
        }
        .allowsHitTesting(false)
    }

    private var guideWidth: CGFloat {
        TrackPreviewHUDLayout.seekGuideWidth(containerWidth: containerSize.width)
    }

    private var guideX: CGFloat {
        TrackPreviewHUDLayout.seekGuideX(
            containerSize: containerSize,
            containerGlobalFrame: containerGlobalFrame,
            touchLocation: touchLocation
        )
    }

    private var guideY: CGFloat {
        TrackPreviewHUDLayout.seekGuideY(
            containerSize: containerSize,
            containerGlobalFrame: containerGlobalFrame,
            touchLocation: touchLocation
        )
    }
}

private struct TrackPreviewHUD: View {
    @ObservedObject var progress: TrackPreviewProgress

    let title: String?
    let artist: String?
    let artworkImage: UIImage?
    let location: CGPoint

    init(
        title: String?,
        artist: String?,
        artworkImage: UIImage?,
        progress: TrackPreviewProgress,
        location: CGPoint
    ) {
        self.title = title
        self.artist = artist
        self.artworkImage = artworkImage
        self.progress = progress
        self.location = location
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                artworkView

                VStack(alignment: .leading, spacing: 3) {
                    Text(title ?? "Unknown Title")
                        .font(.headline)
                        .lineLimit(1)
                    Text(artist ?? "Unknown Artist")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            ProgressView(
                value: progress.elapsedTime,
                total: max(progress.duration, 1)
            )
            .progressViewStyle(.linear)

            HStack {
                Text(formatTime(progress.elapsedTime))
                    .contentTransition(.numericText())
                Spacer()
                Image(systemName: "arrow.left.and.right")
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatTime(progress.duration))
                    .contentTransition(.numericText())
            }
            .font(.caption.monospacedDigit())
            .foregroundColor(.secondary)
        }
        .padding(14)
        .frame(width: TrackPreviewHUDLayout.hudWidth)
        .background {
            hudShape
                .fill(Color.white.opacity(0.08))
        }
        // Visual tuning: keep the Liquid Glass recipe local to this HUD so
        // future UI tweaks can happen without touching gesture/playback code.
        .glassEffect(
            .regular.tint(Color.white.opacity(0.10)),
            in: hudShape
        )
        .overlay {
            hudShape
                .strokeBorder(Color.white.opacity(0.28), lineWidth: 0.8)
        }
        .overlay(alignment: .topLeading) {
            Capsule()
                .fill(Color.white.opacity(0.45))
                .frame(width: 74, height: 2)
                .padding(.top, 8)
                .padding(.leading, 22)
        }
        .shadow(color: .black.opacity(0.18), radius: 26, y: 12)
        .shadow(color: Color.accentColor.opacity(0.12), radius: 18, y: 4)
        .position(location)
        .allowsHitTesting(false)
    }

    private var hudShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
    }

    @ViewBuilder
    private var artworkView: some View {
        if let image = artworkImage {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 54, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.secondary.opacity(0.18))
                .frame(width: 54, height: 54)
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite, time > 0 else { return "0:00" }
        let totalSeconds = Int(time)
        return "\(totalSeconds / 60):\(String(format: "%02d", totalSeconds % 60))"
    }
}

private struct TrackPreviewHUDDesignPreview: View {
    @StateObject private var progress = TrackPreviewProgress()

    let touchPoint: CGPoint

    var body: some View {
        GeometryReader { proxy in
            let frame = proxy.frame(in: .global)
            let touchLocation = CGPoint(
                x: frame.minX + touchPoint.x,
                y: frame.minY + touchPoint.y
            )

            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                TrackPreviewSeekGuide(
                    touchLocation: touchLocation,
                    containerSize: proxy.size,
                    containerGlobalFrame: frame
                )

                TrackPreviewHUD(
                    title: "Supernova Drive (Kohei Remix)",
                    artist: "Mika River feat. Duskline",
                    artworkImage: nil,
                    progress: progress,
                    location: TrackPreviewHUDLayout.hudPosition(
                        containerSize: proxy.size,
                        containerGlobalFrame: frame,
                        touchLocation: touchLocation
                    )
                )
            }
        }
        .onAppear {
            progress.update(elapsedTime: 74, duration: 246)
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
        .environmentObject(TrackPreviewController())
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
        .environmentObject(TrackPreviewController())
        .previewDisplayName("Search Criteria")

        TrackPreviewHUDDesignPreview(touchPoint: CGPoint(x: 286, y: 128))
            .frame(width: 390, height: 260)
            .previewDisplayName("Track Preview HUD + Seek Guide")

        TrackPreviewHUDDesignPreview(touchPoint: CGPoint(x: 92, y: 210))
            .frame(width: 390, height: 320)
            .previewDisplayName("Track Preview HUD Lower Touch")
    }

    private static let previewPredicates = [
        MyMPMediaPropertyPredicate(
            value: "House", forProperty: MPMediaItemPropertyGenre),
        MyMPMediaPropertyPredicate(
            value: "Mika River", forProperty: MPMediaItemPropertyArtist,
            comparisonType: .contains),
    ]
}

#Preview("Track Preview HUD + Seek Guide") {
    TrackPreviewHUDDesignPreview(touchPoint: CGPoint(x: 286, y: 128))
        .frame(width: 390, height: 260)
        .environmentObject(TrackPreviewController())
}
