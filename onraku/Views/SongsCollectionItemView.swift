//
//  SongsCollectionItemView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import SwiftUI

struct SongsCollectionItemView: View {
    var title: String
    var systemImage: String?
    var itemsCount: Int?
    var isLoading: Bool

    var body: some View {
        HStack {
            if title.isEmpty {
                Group {
                    if let systemImage = systemImage {
                        Label("(no value)", systemImage: systemImage)
                    } else {
                        Text("(no value)")
                    }
                }.foregroundColor(.secondary)

            } else {
                if let systemImage = systemImage {
                    Label(title, systemImage: systemImage)
                } else {
                    Text(title)
                }
            }
            Spacer()
            if let itemsCount = itemsCount {
                Text(String(itemsCount))
                    .monospacedDigit()
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } else if isLoading {
                ProgressView()
            }
        }
    }
}

struct SongsCollectionItemView_Previews: PreviewProvider {
    static var previews: some View {
        SongsCollectionItemView(title: "Gorgeous Label", itemsCount: 42, isLoading: false)
    }
}
