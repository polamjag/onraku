//
//  LoadingState.swift
//  onraku
//
//  Created by Satoru Abe on 2022/11/20.
//

import Foundation

enum LoadingState: String {
  case initial, loading, loaded, loadingByPullToRefresh
  
  public var isLoading: Bool {
    self == .loading
  }
}
