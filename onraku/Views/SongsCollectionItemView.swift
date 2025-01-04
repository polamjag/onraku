//
//  SongsCollectionItemView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import SwiftUI

struct SongsCollectionItemView: View {
  var title: String
  var secondaryText: String?
  var systemImage: String?
  var itemsCount: Int?
  var showLoading: Bool = false

  var body: some View {
    HStack {
      Label {
        if title.isEmpty {
          Text("(no value)").foregroundStyle(.secondary)
        } else {
          Text(title)
        }

        if let secondaryText {
          Text(secondaryText)
            .foregroundColor(.secondary)
            .font(.footnote)
            .lineLimit(1)
        }
      } icon: {
        if let systemImage {
          Image(systemName: systemImage)
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
      SongsCollectionItemView(
        title: "", itemsCount: nil, showLoading: false)

      SongsCollectionItemView(
        title: "", secondaryText: "Secondary Text",
        itemsCount: nil,
        showLoading: false)

      SongsCollectionItemView(
        title: "Gorgeous Label", itemsCount: nil, showLoading: false)
      SongsCollectionItemView(
        title: "Gorgeous Label", itemsCount: 42, showLoading: false)
      SongsCollectionItemView(
        title: "Gorgeous Label", secondaryText: "Secondary Text",
        itemsCount: 42, showLoading: false)

      SongsCollectionItemView(
        title: "Gorgeous Label", secondaryText: "Secondary Text",
        systemImage: "car.side.rear.and.exclamationmark.and.car.side.front.off",
        itemsCount: 42, showLoading: false)

      SongsCollectionItemView(
        title: "Gorgeous Label", systemImage: "checkmark.seal", itemsCount: 42,
        showLoading: false)

      SongsCollectionItemView(
        title: "Gorgeous Label", itemsCount: nil, showLoading: true)
    }
  }
}
