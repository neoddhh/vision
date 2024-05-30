//
//  Accelerator.swift
//  Driving
//
//  Created by Nathan Mak on 2024/5/24.
//

import Foundation

enum Speed {
    case zero
    case first
    case second
    case third
    case fourth

    var text: String {
        switch self {
        case .zero:
            "0"
        case .first:
            "1"
        case .second:
            "2"
        case .third:
            "3"
        case .fourth:
            "4"
        }
    }

    var value: Float {
        switch self {
        case .zero:
            0
        case .first:
            0.5
        case .second:
            1
        case .third:
            1.5
        case .fourth:
            2
        }
    }
}
