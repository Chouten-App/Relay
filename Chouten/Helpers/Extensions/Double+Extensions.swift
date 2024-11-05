//
//  Double+Extensions.swift
//  Chouten
//
//  Created by Cel on 27/10/2024.
//

import Foundation

extension Double {
    func removeTrailingZeros() -> String {
        String(format: "%g", self)
    }
}
