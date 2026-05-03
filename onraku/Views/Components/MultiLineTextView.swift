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
            Text(text)
                .padding()
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MultiLineTextView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MultiLineTextView(
                text: """
                    First line of the selected text.
                    Second line keeps wrapping behavior visible.

                    A longer paragraph checks that the scroll view stays aligned to the top \
                    and keeps text selection enabled for comments and lyrics.
                    """
            )
            .navigationTitle("Lyrics")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
