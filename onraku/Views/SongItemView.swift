//
//  SongItemView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import MediaPlayer
import SwiftUI

private let artworkSize: CGFloat = 42

struct SongItemView: View {
    var title: String?
    var secondaryText: String?
    var tertiaryText: String?
    var artwork: MPMediaItemArtwork?

    var body: some View {
        HStack {
            if let image = artwork?.image(at: CGSize(width: artworkSize, height: artworkSize)) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: artworkSize, height: artworkSize)
                    .cornerRadius(4)
            } else {
                Rectangle().opacity(0).frame(width: artworkSize, height: artworkSize)
            }

            VStack(alignment: .leading, spacing: tertiaryText == nil ? 2 : 1) {
                Text(title ?? "").lineLimit(1)

                Text((secondaryText ?? ""))
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                if let tertiaryText = tertiaryText {
                    Text(tertiaryText)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                }
            }
        }
    }
}

struct SongItemView_Previews: PreviewProvider {
    static var previews: some View {
        SongItemView(
            title: "Super song 超いい曲",
            secondaryText: "Lolem ipsum"
        )
    }
}
