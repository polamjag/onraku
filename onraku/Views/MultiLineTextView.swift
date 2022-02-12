//
//  MultiLineTextView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import SwiftUI

struct MultiLineTextView: View {
    var text: String

    var body: some View {
        ScrollView {
            Text(text).padding().textSelection(.enabled)
        }
        .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: UIScreen.main.bounds.height)

    }
}

struct MultiLineTextView_Previews: PreviewProvider {
    static var previews: some View {
        MultiLineTextView(text: "Lolem ipsum\ndot sitor\namet")
    }
}
