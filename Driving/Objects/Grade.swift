//
//  Grade.swift
//  Driving
//
//  Created by Nathan Mak on 2024/5/24.
//

import Foundation

enum Grade {
    case d
    case r
    case p

    var text: String {
        switch self {
        case .d:
            "D 档"
        case .r:
            "R 档"
        case .p:
            "P 档"
        }
    }
}
