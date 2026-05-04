//
//  SongsCollectionItemView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import SwiftUI

struct SongsCollectionItemView: View {
    enum ItemsCountDisplayMode {
        case visibleWhenAvailable
        case reservingSpace(maxDigits: Int)

        var reservedDigits: Int? {
            switch self {
            case .visibleWhenAvailable:
                return nil
            case let .reservingSpace(maxDigits):
                return maxDigits
            }
        }
    }

    var title: String
    var secondaryText: String?
    var systemImage: String?
    var itemsCount: Int?
    var showLoading: Bool = false
    var itemsCountDisplayMode: ItemsCountDisplayMode = .visibleWhenAvailable

    private var shouldShowCountArea: Bool {
        showLoading || itemsCount != nil || itemsCountDisplayMode.reservedDigits != nil
    }

    private var countAreaPlaceholder: String {
        let digits = itemsCountDisplayMode.reservedDigits ?? String(itemsCount ?? 0).count
        return String(repeating: "0", count: max(digits, 1))
    }

    var body: some View {
        HStack {
            Label {
                VStack(alignment: .leading) {
                    if title.isEmpty {
                        Text("(no value)").foregroundStyle(.secondary)
                    } else {
                        Text(title)
                    }

                    if let secondaryText {
                        Text(secondaryText)
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }
            } icon: {
                if let systemImage {
                    Image(systemName: systemImage)
                }
            }

            Spacer()

            if shouldShowCountArea {
                ZStack(alignment: .trailing) {
                    Text(countAreaPlaceholder)
                        .monospacedDigit()
                        .font(.footnote)
                        .hidden()

                    if showLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else if let itemsCount = itemsCount {
                        Text(String(itemsCount))
                            .monospacedDigit()
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

struct SongsCollectionItemView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            SongsCollectionItemView(
                title: "", itemsCount: nil)

            SongsCollectionItemView(
                title: "", secondaryText: "Missing metadata", itemsCount: nil)

            SongsCollectionItemView(
                title: "Night Drive", itemsCount: nil)
            SongsCollectionItemView(
                title: "Night Drive", itemsCount: 42)
            SongsCollectionItemView(
                title: "Night Drive", secondaryText: "4 playlists", itemsCount: 42)

            SongsCollectionItemView(
                title: "DJ Sets", secondaryText: "2 playlists",
                systemImage: "folder",
                itemsCount: 42)

            SongsCollectionItemView(
                title: "Favorites", systemImage: "checkmark.seal", itemsCount: 42)

            SongsCollectionItemView(
                title: "Loading playlist", itemsCount: nil, showLoading: true)
        }
        .previewDisplayName("Songs Collection Rows")
    }
}
