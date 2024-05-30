//
//  DriveAction.swift
//  Driving
//
//  Created by Nathan Mak on 2024/5/24.
//

import Foundation

enum DriveAction: CaseIterable {
    case dGrade
    case rGrade
    case pGrade
    case brake
    case firstSpeed
    case secondSpeed
    case thirdSpeed
    case fouthSpeed
    case toggleHighAndLowBeams
    case toggleTurnSignals
    case toggleDoubleFlashingLights
    case resetSteeringWheelAndInstructmentPanel
    case none

    var text: String {
        switch self {
        case .dGrade:
            "D 档"
        case .rGrade:
            "R 档"
        case .pGrade:
            "P 档"
        case .brake:
            "刹车"
        case .firstSpeed:
            "一档油门"
        case .secondSpeed:
            "二档油门"
        case .thirdSpeed:
            "三档油门"
        case .fouthSpeed:
            "四档油门"
        case .toggleHighAndLowBeams:
            "开关远近光灯"
        case .toggleTurnSignals:
            "开关转向灯"
        case .toggleDoubleFlashingLights:
            "开关双闪灯"
        case .resetSteeringWheelAndInstructmentPanel:
            ""
        case .none:
            "未知"
        }
    }
}
