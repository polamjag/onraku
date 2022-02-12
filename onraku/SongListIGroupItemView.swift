//
//  SongListIGroupItemView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import SwiftUI

struct SongListIGroupItemView: View {
    var title: String
    var itemsCount: Int
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(itemsCount)").monospacedDigit().font(.footnote).foregroundColor(.secondary)
        }
    }
}

struct SongListIGroupItemView_Previews: PreviewProvider {
    static var previews: some View {
        SongListIGroupItemView(title: "Gorgeous Label", itemsCount: 42)
    }
}
