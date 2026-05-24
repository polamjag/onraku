//
//  PreviewableSongRow.swift
//  onraku
//

import MediaPlayer
import SwiftUI

/// Song list row that wires normal navigation and playback menu actions to
/// long-press track preview start, seek, and stop behavior.
struct PreviewableSongRow: View {
    @EnvironmentObject private var trackPreviewController: TrackPreviewController

    private let song: MPMediaItem?
    private let previewIsPreviewing: Bool?
    let tertiaryText: String?
    private let title: String?
    private let artist: String?
    private let artwork: MPMediaItemArtwork?

    init(song: MPMediaItem, tertiaryText: String?) {
        self.song = song
        self.previewIsPreviewing = nil
        self.tertiaryText = tertiaryText
        self.title = song.title
        self.artist = song.artist
        self.artwork = song.artwork
    }

    fileprivate init(
        title: String?,
        artist: String?,
        tertiaryText: String?,
        isPreviewing: Bool
    ) {
        self.song = nil
        self.previewIsPreviewing = isPreviewing
        self.tertiaryText = tertiaryText
        self.title = title
        self.artist = artist
        self.artwork = nil
    }

    var body: some View {
        let row = HStack(spacing: 8) {
            rowContent

            playbackOptionsButton
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        if isPreviewing {
            row.listRowBackground(
                Color.accentColor.opacity(0.1)
            )
        } else {
            row
        }
    }

    private var isPreviewing: Bool {
        if let previewIsPreviewing {
            return previewIsPreviewing
        }

        guard let song else { return false }
        return trackPreviewController.previewingItemID == song.persistentID
    }

    @ViewBuilder
    private var rowContent: some View {
        if let song {
            NavigationLink {
                SongDetailView(song: song)
            } label: {
                rowLabel
                    .background(previewTouchRecognizer)
            }
        } else {
            rowLabel
        }
    }

    private var rowLabel: some View {
        SongItemView(
            title: title,
            secondaryText: artist,
            tertiaryText: tertiaryText,
            artwork: artwork
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var previewTouchRecognizer: some View {
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
    }

    @ViewBuilder
    private var playbackOptionsButton: some View {
        if let song {
            Menu {
                PlayableItemsMenuView(item: song)
            } label: {
                playbackOptionsIcon
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Playback Options")
        } else {
            playbackOptionsIcon
                .accessibilityLabel("Playback Options")
        }
    }

    private var playbackOptionsIcon: some View {
        Image(systemName: "ellipsis.circle")
            .imageScale(.large)
            .foregroundColor(.secondary)
            .frame(width: 36, height: 36)
    }

    private func startPreviewIfNeeded() {
        guard let song, !isPreviewing else { return }
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
        guard song != nil, isPreviewing, screenWidth > 0 else { return }
        trackPreviewController.seekPreview(
            toFraction: TrackPreviewScreenSeekMapper.fraction(
                forX: location.x,
                screenWidth: screenWidth
            )
        )
    }
}

#Preview("Previewable Song Row") {
    List {
        PreviewableSongRow(
            title: "Supernova Drive (Kohei Remix)",
            artist: "Mika River feat. Duskline",
            tertiaryText: "City Lights After Midnight",
            isPreviewing: false
        )

        PreviewableSongRow(
            title: "Midnight Transfer",
            artist: "Night Transit Orchestra",
            tertiaryText: "Previewing",
            isPreviewing: true
        )
    }
    .environmentObject(TrackPreviewController())
}
