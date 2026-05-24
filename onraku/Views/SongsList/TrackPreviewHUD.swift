//
//  TrackPreviewHUD.swift
//  onraku
//

import SwiftUI
import UIKit

/// Centered informational HUD shown while a track preview is active, including
/// artwork, title/artist, elapsed time, duration, and progress.
struct TrackPreviewHUD: View {
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

/// SwiftUI Preview fixture for tuning the preview HUD and seek guide without
/// needing a live song row or MediaPlayer state.
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

#Preview("Track Preview HUD + Seek Guide") {
    TrackPreviewHUDDesignPreview(touchPoint: CGPoint(x: 286, y: 128))
        .frame(width: 390, height: 260)
}

#Preview("Track Preview HUD Lower Touch") {
    TrackPreviewHUDDesignPreview(touchPoint: CGPoint(x: 92, y: 210))
        .frame(width: 390, height: 320)
}
