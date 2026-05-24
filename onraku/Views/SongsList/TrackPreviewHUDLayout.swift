//
//  TrackPreviewHUDLayout.swift
//  onraku
//

import SwiftUI

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
