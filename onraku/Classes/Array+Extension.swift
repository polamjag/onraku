//
//  Array+Extension.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/13.
//

import Foundation

extension Array {
    func thisAndAbove(at: Int) -> Array {
        return Array(self[0...at])
    }

    func thisAndBelow(at: Int) -> Array {
        return Array(self[at...])
    }
}
