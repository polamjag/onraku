//
//  SongListIGroupItemView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import SwiftUI

struct SongAssortmentItemView: View {
    var title: String
    var itemsCount: Int
    
    var body: some View {
        HStack {
            title.isEmpty ?
                Text("(no value)").foregroundColor(.secondary) :
                Text(title)
            Spacer()
            Text("\(itemsCount)").monospacedDigit().font(.footnote).foregroundColor(.secondary)
        }
    }
}

struct SongGroupItemView_Previews: PreviewProvider {
    static var previews: some View {
        SongAssortmentItemView(title: "Gorgeous Label", itemsCount: 42)
    }
}