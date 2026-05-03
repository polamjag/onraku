//
//  FiveStarsImageView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/14.
//

import SwiftUI

struct FiveStarsImageView: View {
    var rating: Int
    var body: some View {
        HStack(spacing: 2) {
            if 0 < rating && rating <= 5 {
                ForEach(1...rating, id: \.self) { _ in
                    Image(systemName: "star.fill")
                }
                if rating < 5 {
                    ForEach(1...(5 - rating), id: \.self) { _ in
                        Image(systemName: "star")
                    }
                }
            }
        }.accessibilityLabel("\(rating) stars")
    }
}

struct FiveStarsImageView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ForEach(0...5, id: \.self) { rating in
                HStack {
                    Text("\(rating)")
                        .foregroundColor(.secondary)
                    Spacer()
                    FiveStarsImageView(rating: rating)
                }
            }
        }
        .previewDisplayName("Ratings")
    }
}
