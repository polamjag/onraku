//
//  TrackPreviewHUDOverlay.swift
//  onraku
//

import SwiftUI
import UIKit

struct TrackPreviewHUDOverlay: View {
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
