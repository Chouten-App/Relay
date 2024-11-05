//
//  SeekBarDelegate.swift
//  Chouten
//
//  Created by Cel on 04/11/2024.
//

import Foundation

protocol SeekBarDelegate: AnyObject {
    func seekBar(_ seekBar: SeekBar, didChangeProgress progress: Double)
}
