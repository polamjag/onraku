//
//  LoadingCellView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/13.
//

import SwiftUI

struct LoadingCellView: View {
  var body: some View {
    HStack {
      Spacer()
      ProgressView()
      Spacer()
    }
  }
}

struct LoadingCellView_Previews: PreviewProvider {
  static var previews: some View {
    LoadingCellView()
  }
}
