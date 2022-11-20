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
    var showLoading: Bool = false

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
            if showLoading {
                ProgressView()
            } else if let itemsCount = itemsCount {
                Text(String(itemsCount))
                    .monospacedDigit()
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SongsCollectionItemView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            SongsCollectionItemView(title: "Gorgeous Label", itemsCount: nil, showLoading: false)
            SongsCollectionItemView(title: "Gorgeous Label", itemsCount: 42, showLoading: false)
            SongsCollectionItemView(title: "Gorgeous Label", itemsCount: nil, showLoading: true)
        }
    }
}
