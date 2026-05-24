//
//  TrackPreviewHUDDesignPreview.swift
//  onraku
//

import SwiftUI

struct TrackPreviewHUDDesignPreview: View {
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
