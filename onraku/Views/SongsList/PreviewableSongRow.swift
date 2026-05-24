//
//  PreviewableSongRow.swift
//  onraku
//

import MediaPlayer
import SwiftUI

struct PreviewableSongRow: View {
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
