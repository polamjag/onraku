//
//  TrackPreviewScreenSeekMapper.swift
//  onraku
//

import SwiftUI

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
