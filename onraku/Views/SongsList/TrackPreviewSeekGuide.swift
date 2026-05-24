//
//  TrackPreviewSeekGuide.swift
//  onraku
//

import SwiftUI

struct TrackPreviewSeekGuide: View {
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
