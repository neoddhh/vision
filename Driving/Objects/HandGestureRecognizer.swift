//
//  HandGestureRecognizer.swift
//  Driving
//
//  Created by Nathan Mak on 2024/5/24.
//

import ARKit
import Foundation

class HandGestureRecognizer {
    var handTrackingProvider: HandTrackingProvider?
    weak var delegate: (any HandGestureRecognizerDelegate)?
    var recognizedRightHandDriveActionCounts: [DriveAction: Int]
    var recognizedLeftHandDriveActionCounts: [DriveAction: Int]
    var detectHandGestureTask: Task<Void,Never>?

    init() {
        recognizedRightHandDriveActionCounts = [:]
        recognizedLeftHandDriveActionCounts = [:]
        recognizedRightHandDriveActionCounts[.dGrade] = 0
        recognizedRightHandDriveActionCounts[.rGrade] = 0
        recognizedRightHandDriveActionCounts[.pGrade] = 0
        recognizedRightHandDriveActionCounts[.brake] = 0
        recognizedRightHandDriveActionCounts[.firstSpeed] = 0
        recognizedRightHandDriveActionCounts[.secondSpeed] = 0
        recognizedRightHandDriveActionCounts[.thirdSpeed] = 0
        recognizedRightHandDriveActionCounts[.fouthSpeed] = 0
        recognizedRightHandDriveActionCounts[.toggleHighAndLowBeams] = 0
        recognizedRightHandDriveActionCounts[.toggleTurnSignals] = 0
        recognizedRightHandDriveActionCounts[.toggleDoubleFlashingLights] = 0
        recognizedLeftHandDriveActionCounts = recognizedRightHandDriveActionCounts
        recognizedLeftHandDriveActionCounts[.resetSteeringWheelAndInstructmentPanel] = 0
    }

    func detectHandGesture() {
       detectHandGestureTask = Task.detached {
           guard let handTrackingProvider = self.handTrackingProvider else { return }
            for await update in handTrackingProvider.anchorUpdates {
                switch update.event {
                case .updated:
                    let handAnchor = update.anchor
                    guard handAnchor.isTracked else { continue }
                    let action = self.recognize(for: handAnchor)
                    await self.delegate?.didDetect(for: action)
                default:
                    break
                }
            }
        }
    }
    
    func stopDetectHandGesture() {
        detectHandGestureTask?.cancel()
        resetLeftHandActionCounts()
        resetRightHandActionCounts()
    }

    private func checkRightHandDriveActionCount(for action: DriveAction) -> DriveAction {
        let value = recognizedRightHandDriveActionCounts[action] ?? 0
        resetRightHandActionCounts(except: action)
        if value == 5 {
            return action
        } else {
            recognizedRightHandDriveActionCounts[action] = value + 1
            return .none
        }
    }

    // -MARK: 识别的实现
    private func recognize(for handAnchor: HandAnchor) -> DriveAction {
        guard let handSkeleton = handAnchor.handSkeleton else { return .none }
        switch handAnchor.chirality {
        case .left:
            if isUp(rotation: extractRotation(matrix: handAnchor.originFromAnchorTransform)) {
                if isLeftMiddleFingerTipAndThumbTipTap(for: handSkeleton) {
                    let value = recognizedLeftHandDriveActionCounts[.resetSteeringWheelAndInstructmentPanel] ?? 0
                    recognizedLeftHandDriveActionCounts[.resetSteeringWheelAndInstructmentPanel] = value + 1
                    resetLeftHandActionCounts(except: .resetSteeringWheelAndInstructmentPanel)
                    if value == 1 {
                        return .resetSteeringWheelAndInstructmentPanel
                    } else {
                        return .none
                    }
                }
            }
            resetLeftHandActionCounts()
            return .none
        case .right:
            if isRightPanPalm(for: handSkeleton) {
                let rotation = extractRotation(matrix: handAnchor.originFromAnchorTransform)
                if isUp(rotation: rotation) {
                    return checkRightHandDriveActionCount(for: .dGrade)
                } else if isDown(rotation: rotation) {
                    return checkRightHandDriveActionCount(for: .rGrade)
                } else {
                    resetRightHandActionCounts()
                    return .none
                }
            }
            if isRightFist(for: handSkeleton) {
                let rotation = extractRotation(matrix: handAnchor.originFromAnchorTransform)
                if isUp(rotation: rotation) {
                    return checkRightHandDriveActionCount(for: .pGrade)
                } else if isDown(rotation: rotation) {
                    return checkRightHandDriveActionCount(for: .brake)
                } else {
                    resetRightHandActionCounts()
                    return .none
                }
            }
            if isRightOnlyIndexFingerUp(for: handSkeleton) {
                return checkRightHandDriveActionCount(for: .firstSpeed)
            }
            if areRightOnlyIndexFingerAndMiddleFingerUp(for: handSkeleton) {
                return checkRightHandDriveActionCount(for: .secondSpeed)
            }
            if areRightOnlyIndexFingerAndMiddleFingerAndRingFingerUp(for: handSkeleton) {
                return checkRightHandDriveActionCount(for: .thirdSpeed)
            }
            if areRightFingersUp(for: handSkeleton) {
                return checkRightHandDriveActionCount(for: .fouthSpeed)
            }
            if isDown(rotation: extractRotation(matrix: handAnchor.originFromAnchorTransform)) {
                if isRightMiddleFingerTipAndThumbTipTap(for: handSkeleton) {
                    let value = recognizedRightHandDriveActionCounts[.toggleHighAndLowBeams] ?? 0
                    recognizedRightHandDriveActionCounts[.toggleHighAndLowBeams] = value + 1
                    resetRightHandActionCounts(except: .toggleHighAndLowBeams)
                    if value == 1 {
                        return .toggleHighAndLowBeams
                    } else {
                        return .none
                    }
                }
                if isRightRingFingerTipAndThumbTipTap(for: handSkeleton) {
                    let value = recognizedRightHandDriveActionCounts[.toggleTurnSignals] ?? 0
                    recognizedRightHandDriveActionCounts[.toggleTurnSignals] = value + 1
                    resetRightHandActionCounts(except: .toggleTurnSignals)
                    if value == 1 {
                        return .toggleTurnSignals
                    } else {
                        return .none
                    }
                }
                if isRightLittleFingerTipAndThumbTipTap(for: handSkeleton) {
                    let value = recognizedRightHandDriveActionCounts[.toggleDoubleFlashingLights] ?? 0
                    recognizedRightHandDriveActionCounts[.toggleDoubleFlashingLights] = value + 1
                    resetRightHandActionCounts(except: .toggleDoubleFlashingLights)
                    if value == 1 {
                        return .toggleDoubleFlashingLights
                    } else {
                        return .none
                    }
                }
            }
            resetRightHandActionCounts()
            return .none
        }
    }

    private func resetRightHandActionCounts(except action: DriveAction = .none) {
        for it in recognizedRightHandDriveActionCounts.keys {
            guard it != action else { continue }
            recognizedRightHandDriveActionCounts[it] = 0
        }
    }

    private func resetLeftHandActionCounts(except action: DriveAction = .none) {
        for it in recognizedLeftHandDriveActionCounts.keys {
            guard it != action else { continue }
            recognizedLeftHandDriveActionCounts[it] = 0
        }
    }
}

// -MARK: 手势识别计算
extension HandGestureRecognizer {
    private func isLeftMiddleFingerTipAndThumbTipTap(for handSkeleton: HandSkeleton) -> Bool {
        let thumbTip = handSkeleton.joint(.thumbTip)
        let middleFingerTip = handSkeleton.joint(.middleFingerTip)
        let thumbTipTranslation = extractTranslation(matrix: thumbTip.anchorFromJointTransform)
        let middleFingerTipTranslation = extractTranslation(matrix: middleFingerTip.anchorFromJointTransform)
        let middleFingerTipRotation = extractRotation(matrix: middleFingerTip.anchorFromJointTransform)
        let degrees = getZYawDegreesFromQuaternion(middleFingerTipRotation)
        return simd_distance(thumbTipTranslation, middleFingerTipTranslation) < 0.015
            && degrees < 130
            && degrees > 0
    }

    private func isRightMiddleFingerTipAndThumbTipTap(for handSkeleton: HandSkeleton) -> Bool {
        let thumbTip = handSkeleton.joint(.thumbTip)
        let middleFingerTip = handSkeleton.joint(.middleFingerTip)
        let thumbTipTranslation = extractTranslation(matrix: thumbTip.anchorFromJointTransform)
        let middleFingerTipTranslation = extractTranslation(matrix: middleFingerTip.anchorFromJointTransform)
        let middleFingerTipRotation = extractRotation(matrix: middleFingerTip.anchorFromJointTransform)
        let degrees = getZYawDegreesFromQuaternion(middleFingerTipRotation)
        return simd_distance(thumbTipTranslation, middleFingerTipTranslation) < 0.015
            && degrees < 130
            && degrees > 0
    }

    private func isRightRingFingerTipAndThumbTipTap(for handSkeleton: HandSkeleton) -> Bool {
        let thumbTip = handSkeleton.joint(.thumbTip)
        let ringFingerTip = handSkeleton.joint(.ringFingerTip)
        let thumbTipTranslation = extractTranslation(matrix: thumbTip.anchorFromJointTransform)
        let ringFingerTipTranslation = extractTranslation(matrix: ringFingerTip.anchorFromJointTransform)
        let ringFingerTipRotation = extractRotation(matrix: ringFingerTip.anchorFromJointTransform)
        let degrees = getZYawDegreesFromQuaternion(ringFingerTipRotation)
        return simd_distance(thumbTipTranslation, ringFingerTipTranslation) < 0.015
            && degrees < 130
            && degrees > 0
    }

    private func isRightLittleFingerTipAndThumbTipTap(for handSkeleton: HandSkeleton) -> Bool {
        let thumbTip = handSkeleton.joint(.thumbTip)
        let littleFingerTip = handSkeleton.joint(.littleFingerTip)
        let thumbTipTranslation = extractTranslation(matrix: thumbTip.anchorFromJointTransform)
        let littleFingerTipTranslation = extractTranslation(matrix: littleFingerTip.anchorFromJointTransform)
        let littleFingerTipRotation = extractRotation(matrix: littleFingerTip.anchorFromJointTransform)
        let degrees = getZYawDegreesFromQuaternion(littleFingerTipRotation)
        return simd_distance(thumbTipTranslation, littleFingerTipTranslation) < 0.01
            && degrees < 100
            && degrees > 0
    }

    private func isRightOnlyIndexFingerUp(for handSkeleton: HandSkeleton) -> Bool {
        let thumbIntermediateTip = handSkeleton.joint(.thumbIntermediateTip)

        let indexFingerTip = handSkeleton.joint(.indexFingerTip)

        let middleFingerTip = handSkeleton.joint(.middleFingerTip)
        let middleFingerIntermediateTip = handSkeleton.joint(.middleFingerIntermediateTip)
        let middleFingerKnuckle = handSkeleton.joint(.middleFingerKnuckle)

        let ringFingerTip = handSkeleton.joint(.ringFingerTip)
        let ringFingerKnuckle = handSkeleton.joint(.ringFingerKnuckle)

        let littleFingerTip = handSkeleton.joint(.littleFingerTip)
        let littleFingerKnuckle = handSkeleton.joint(.littleFingerKnuckle)

        let thumbIntermediateTipTranslation = extractTranslation(matrix: thumbIntermediateTip.anchorFromJointTransform)

        let indexFingerTipTranslation = extractTranslation(matrix: indexFingerTip.anchorFromJointTransform)

        let middleFingerTipTranslation = extractTranslation(matrix: middleFingerTip.anchorFromJointTransform)
        let middleFingerIntermediateTipTranslation = extractTranslation(matrix: middleFingerIntermediateTip.anchorFromJointTransform)
        let middleFingerKnuckleTranslation = extractTranslation(matrix: middleFingerKnuckle.anchorFromJointTransform)

        let ringFingerTipTranslation = extractTranslation(matrix: ringFingerTip.anchorFromJointTransform)
        let ringFingerKnuckleTranslation = extractTranslation(matrix: ringFingerKnuckle.anchorFromJointTransform)

        let littleFingerTipTranslation = extractTranslation(matrix: littleFingerTip.anchorFromJointTransform)
        let littleFingerKnuckleTranslation = extractTranslation(matrix: littleFingerKnuckle.anchorFromJointTransform)

        let indexFingerTipRotation = extractRotation(matrix: indexFingerTip.anchorFromJointTransform)

        let distance1 = simd_distance(middleFingerTipTranslation, middleFingerKnuckleTranslation)
        let distance2 = simd_distance(ringFingerTipTranslation, ringFingerKnuckleTranslation)
        let distance3 = simd_distance(littleFingerTipTranslation, littleFingerKnuckleTranslation)
        let distance4 = simd_distance(thumbIntermediateTipTranslation, middleFingerIntermediateTipTranslation)

        return (abs(indexFingerTipTranslation.y) < 0.035
            && abs(getZYawDegreesFromQuaternion(indexFingerTipRotation)) < 30
            && distance1 < 0.06
            && distance2 < 0.06
            && distance3 < 0.06
            && distance4 < 0.04)
    }

    private func areRightOnlyIndexFingerAndMiddleFingerUp(for handSkeleton: HandSkeleton) -> Bool {
        let thumbIntermediateTip = handSkeleton.joint(.thumbIntermediateTip)

        let indexFingerTip = handSkeleton.joint(.indexFingerTip)

        let middleFingerTip = handSkeleton.joint(.middleFingerTip)

        let ringFingerTip = handSkeleton.joint(.ringFingerTip)
        let ringFingerIntermediateTip = handSkeleton.joint(.ringFingerIntermediateTip)
        let ringFingerKnuckle = handSkeleton.joint(.ringFingerKnuckle)

        let littleFingerTip = handSkeleton.joint(.littleFingerTip)
        let littleFingerKnuckle = handSkeleton.joint(.littleFingerKnuckle)

        let thumbIntermediateTipTranslation = extractTranslation(matrix: thumbIntermediateTip.anchorFromJointTransform)

        let indexFingerTipTranslation = extractTranslation(matrix: indexFingerTip.anchorFromJointTransform)

        let middleFingerTipTranslation = extractTranslation(matrix: middleFingerTip.anchorFromJointTransform)

        let ringFingerTipTranslation = extractTranslation(matrix: ringFingerTip.anchorFromJointTransform)
        let ringFingerIntermediateTipTranslation = extractTranslation(matrix: ringFingerIntermediateTip.anchorFromJointTransform)
        let ringFingerKnuckleTranslation = extractTranslation(matrix: ringFingerKnuckle.anchorFromJointTransform)

        let littleFingerTipTranslation = extractTranslation(matrix: littleFingerTip.anchorFromJointTransform)
        let littleFingerKnuckleTranslation = extractTranslation(matrix: littleFingerKnuckle.anchorFromJointTransform)

        let indexFingerTipRotation = extractRotation(matrix: indexFingerTip.anchorFromJointTransform)

        let middleFingerTipRotation = extractRotation(matrix: middleFingerTip.anchorFromJointTransform)

        let distance1 = simd_distance(ringFingerTipTranslation, ringFingerKnuckleTranslation)
        let distance2 = simd_distance(littleFingerTipTranslation, littleFingerKnuckleTranslation)
        let distance3 = simd_distance(thumbIntermediateTipTranslation, ringFingerIntermediateTipTranslation)

        return (abs(indexFingerTipTranslation.y) < 0.035
            && abs(middleFingerTipTranslation.y) < 0.035
            && abs(getZYawDegreesFromQuaternion(indexFingerTipRotation)) < 30
            && abs(getZYawDegreesFromQuaternion(middleFingerTipRotation)) < 30
            && distance1 < 0.08
            && distance2 < 0.07
            && distance3 < 0.06)
    }

    private func areRightOnlyIndexFingerAndMiddleFingerAndRingFingerUp(for handSkeleton: HandSkeleton) -> Bool {
        let thumbIntermediateTip = handSkeleton.joint(.thumbIntermediateTip)

        let indexFingerTip = handSkeleton.joint(.indexFingerTip)

        let middleFingerTip = handSkeleton.joint(.middleFingerTip)

        let ringFingerTip = handSkeleton.joint(.ringFingerTip)

        let littleFingerTip = handSkeleton.joint(.littleFingerTip)
        let littleFingerIntermediateTip = handSkeleton.joint(.littleFingerIntermediateTip)
        let littleFingerKnuckle = handSkeleton.joint(.littleFingerKnuckle)

        let thumbIntermediateTipTranslation = extractTranslation(matrix: thumbIntermediateTip.anchorFromJointTransform)

        let indexFingerTipTranslation = extractTranslation(matrix: indexFingerTip.anchorFromJointTransform)

        let middleFingerTipTranslation = extractTranslation(matrix: middleFingerTip.anchorFromJointTransform)

        let ringFingerTipTranslation = extractTranslation(matrix: ringFingerTip.anchorFromJointTransform)

        let littleFingerTipTranslation = extractTranslation(matrix: littleFingerTip.anchorFromJointTransform)
        let littleFingerIntermediateTipTranslation = extractTranslation(matrix: littleFingerIntermediateTip.anchorFromJointTransform)
        let littleFingerKnuckleTranslation = extractTranslation(matrix: littleFingerKnuckle.anchorFromJointTransform)

        let indexFingerTipRotation = extractRotation(matrix: indexFingerTip.anchorFromJointTransform)
        let middleFingerTipRotation = extractRotation(matrix: middleFingerTip.anchorFromJointTransform)
        let ringFingerTipRotation = extractRotation(matrix: ringFingerTip.anchorFromJointTransform)

        let distance1 = simd_distance(littleFingerTipTranslation, littleFingerKnuckleTranslation)
        let distance2 = simd_distance(thumbIntermediateTipTranslation, littleFingerIntermediateTipTranslation)

        return (abs(indexFingerTipTranslation.y) < 0.035
            && abs(middleFingerTipTranslation.y) < 0.035
            && abs(ringFingerTipTranslation.y) < 0.04
            && abs(getZYawDegreesFromQuaternion(indexFingerTipRotation)) < 30
            && abs(getZYawDegreesFromQuaternion(middleFingerTipRotation)) < 30
            && abs(getZYawDegreesFromQuaternion(ringFingerTipRotation)) < 40
            && distance1 < 0.07
            && distance2 < 0.05)
    }

    private func areRightFingersUp(for handSkeleton: HandSkeleton) -> Bool {
        let thumbTip = handSkeleton.joint(.thumbTip) // TODO:
        let indexFingerTip = handSkeleton.joint(.indexFingerTip)
        let middleFingerTip = handSkeleton.joint(.middleFingerTip)
        let ringFingerTip = handSkeleton.joint(.ringFingerTip)
        let littleFingerTip = handSkeleton.joint(.littleFingerTip)

        let indexFingerTipTranslation = extractTranslation(matrix: indexFingerTip.anchorFromJointTransform)
        let middleFingerTipTranslation = extractTranslation(matrix: middleFingerTip.anchorFromJointTransform)
        let ringFingerTipTranslation = extractTranslation(matrix: ringFingerTip.anchorFromJointTransform)
        let littleFingerTipTranslation = extractTranslation(matrix: littleFingerTip.anchorFromJointTransform)

        let thumbTipRotation = extractRotation(matrix: thumbTip.anchorFromJointTransform)
        let indexFingerTipRotation = extractRotation(matrix: indexFingerTip.anchorFromJointTransform)
        let middleFingerTipRotation = extractRotation(matrix: middleFingerTip.anchorFromJointTransform)
        let ringFingerTipRotation = extractRotation(matrix: ringFingerTip.anchorFromJointTransform)
        let littleFingerTipRotation = extractRotation(matrix: littleFingerTip.anchorFromJointTransform)

        let b1 = abs(indexFingerTipTranslation.y) < 0.035
            && abs(middleFingerTipTranslation.y) < 0.035
            && abs(ringFingerTipTranslation.y) < 0.035
            && abs(littleFingerTipTranslation.y) < 0.035
        let b2 = abs(getZYawDegreesFromQuaternion(indexFingerTipRotation)) < 30
            && abs(getZYawDegreesFromQuaternion(middleFingerTipRotation)) < 30
            && abs(getZYawDegreesFromQuaternion(ringFingerTipRotation)) < 30
            && abs(getZYawDegreesFromQuaternion(littleFingerTipRotation)) < 30
            && abs(getXYawDegreesFromQuaternion(thumbTipRotation)) > 100
        return b1 && b2
    }

    // 拳头
    private func isRightFist(for handSkeleton: HandSkeleton) -> Bool {
        let thumbIntermediateTip = handSkeleton.joint(.thumbIntermediateTip)

        let indexFingerTip = handSkeleton.joint(.indexFingerTip)
        let indexFingerIntermediateTip = handSkeleton.joint(.indexFingerIntermediateTip)
        let indexFingerKnuckle = handSkeleton.joint(.indexFingerKnuckle)

        let middleFingerTip = handSkeleton.joint(.middleFingerTip)
        let middleFingerKnuckle = handSkeleton.joint(.middleFingerKnuckle)

        let ringFingerTip = handSkeleton.joint(.ringFingerTip)
        let ringFingerKnuckle = handSkeleton.joint(.ringFingerKnuckle)

        let littleFingerTip = handSkeleton.joint(.littleFingerTip)
        let littleFingerKnuckle = handSkeleton.joint(.littleFingerKnuckle)

        let thumbIntermediateTipTranslation = extractTranslation(matrix: thumbIntermediateTip.anchorFromJointTransform)

        let indexFingerTipTranslation = extractTranslation(matrix: indexFingerTip.anchorFromJointTransform)
        let indexFingerIntermediateTipTranslation = extractTranslation(matrix: indexFingerIntermediateTip.anchorFromJointTransform)
        let indexFingerKnuckleTranslation = extractTranslation(matrix: indexFingerKnuckle.anchorFromJointTransform)

        let middleFingerTipTranslation = extractTranslation(matrix: middleFingerTip.anchorFromJointTransform)
        let middleFingerKnuckleTranslation = extractTranslation(matrix: middleFingerKnuckle.anchorFromJointTransform)

        let ringFingerTipTranslation = extractTranslation(matrix: ringFingerTip.anchorFromJointTransform)
        let ringFingerKnuckleTranslation = extractTranslation(matrix: ringFingerKnuckle.anchorFromJointTransform)

        let littleFingerTipTranslation = extractTranslation(matrix: littleFingerTip.anchorFromJointTransform)
        let littleFingerKnuckleTranslation = extractTranslation(matrix: littleFingerKnuckle.anchorFromJointTransform)

        let distance1 = simd_distance(indexFingerTipTranslation, indexFingerKnuckleTranslation)
        let distance2 = simd_distance(middleFingerTipTranslation, middleFingerKnuckleTranslation)
        let distance3 = simd_distance(ringFingerTipTranslation, ringFingerKnuckleTranslation)
        let distance4 = simd_distance(littleFingerTipTranslation, littleFingerKnuckleTranslation)
        let distance5 = simd_distance(thumbIntermediateTipTranslation, indexFingerIntermediateTipTranslation)

        return (distance1 < 0.04
            && distance2 < 0.04
            && distance3 < 0.04
            && distance4 < 0.04
            && distance5 < 0.04)
    }

    // 平掌
    private func isRightPanPalm(for handSkeleton: HandSkeleton) -> Bool {
        let thumbTip = handSkeleton.joint(.thumbTip)
        let indexFingerTip = handSkeleton.joint(.indexFingerTip)
        let middleFingerTip = handSkeleton.joint(.middleFingerTip)
        let ringFingerTip = handSkeleton.joint(.ringFingerTip)
        let littleFingerTip = handSkeleton.joint(.littleFingerTip)

        let thumbTipTranslation = extractTranslation(matrix: thumbTip.anchorFromJointTransform)
        let indexFingerTipTranslation = extractTranslation(matrix: indexFingerTip.anchorFromJointTransform)
        let middleFingerTipTranslation = extractTranslation(matrix: middleFingerTip.anchorFromJointTransform)
        let ringFingerTipTranslation = extractTranslation(matrix: ringFingerTip.anchorFromJointTransform)
        let littleFingerTipTranslation = extractTranslation(matrix: littleFingerTip.anchorFromJointTransform)

        let thumbTipRotation = extractRotation(matrix: thumbTip.anchorFromJointTransform)
        let indexFingerTipRotation = extractRotation(matrix: indexFingerTip.anchorFromJointTransform)
        let middleFingerTipRotation = extractRotation(matrix: middleFingerTip.anchorFromJointTransform)
        let ringFingerTipRotation = extractRotation(matrix: ringFingerTip.anchorFromJointTransform)
        let littleFingerTipRotation = extractRotation(matrix: littleFingerTip.anchorFromJointTransform)

        let b1 = abs(thumbTipTranslation.y) < 0.035
            && abs(indexFingerTipTranslation.y) < 0.035
            && abs(middleFingerTipTranslation.y) < 0.035
            && abs(ringFingerTipTranslation.y) < 0.035
            && abs(littleFingerTipTranslation.y) < 0.035
        let b2 = abs(getZYawDegreesFromQuaternion(indexFingerTipRotation)) < 30
            && abs(getZYawDegreesFromQuaternion(middleFingerTipRotation)) < 30
            && abs(getZYawDegreesFromQuaternion(ringFingerTipRotation)) < 30
            && abs(getZYawDegreesFromQuaternion(littleFingerTipRotation)) < 30
            && abs(getXYawDegreesFromQuaternion(thumbTipRotation)) < 80
        return b1 && b2
    }

    private func isUp(rotation: simd_quatf) -> Bool {
        let rotationMatrix = matrix_float3x3(rotation)
        let yAxisDirection = rotationMatrix.columns.1
        let yAxis = SIMD3<Float>(0, 1, 0)
        let dotProduct = dot(yAxisDirection, yAxis)
        let tolerance: Float = 0.25
        return (abs(dotProduct - 1) < tolerance)
    }

    private func isDown(rotation: simd_quatf) -> Bool {
        let rotationMatrix = matrix_float3x3(rotation)
        let yAxisDirection = rotationMatrix.columns.1
        let yAxis = SIMD3<Float>(0, -1, 0)
        let dotProduct = dot(yAxisDirection, yAxis)

        let tolerance: Float = 0.25
        return (abs(dotProduct - 1) < tolerance)
    }

    private func extractTranslation(matrix: simd_float4x4) -> SIMD3<Float> {
        return SIMD3<Float>(matrix.columns.3.x, matrix.columns.3.y, matrix.columns.3.z)
    }

    private func extractRotation(matrix: simd_float4x4) -> simd_quatf {
        // Extract the scale factors
        let scaleX = length(SIMD3<Float>(matrix.columns.0.x, matrix.columns.0.y, matrix.columns.0.z))
        let scaleY = length(SIMD3<Float>(matrix.columns.1.x, matrix.columns.1.y, matrix.columns.1.z))
        let scaleZ = length(SIMD3<Float>(matrix.columns.2.x, matrix.columns.2.y, matrix.columns.2.z))
        var rotationMatrix = matrix
        rotationMatrix.columns.0 /= scaleX
        rotationMatrix.columns.1 /= scaleY
        rotationMatrix.columns.2 /= scaleZ
        let rotation = simd_quatf(rotationMatrix)
        return rotation
    }

    private func getYYawDegreesFromQuaternion(_ quat: simd_quatf) -> Float {
        // 计算所需的中间变量
        let siny_cosp = 2 * (quat.real * quat.imag.y + quat.imag.z * quat.imag.x)
        let cosy_cosp = 1 - 2 * (quat.imag.y * quat.imag.y + quat.imag.z * quat.imag.z)

        // 计算 yaw 角（绕 y 轴的旋转角度）
        let yaw = atan2(siny_cosp, cosy_cosp)

        return yaw * (180 / .pi)
    }

    private func getXYawDegreesFromQuaternion(_ quat: simd_quatf) -> Float {
        // 计算所需的中间变量
        let sinr_cosp = 2 * (quat.real * quat.imag.x + quat.imag.y * quat.imag.z)
        let cosr_cosp = 1 - 2 * (quat.imag.x * quat.imag.x + quat.imag.y * quat.imag.y)

        // 计算 yaw 角（绕 x 轴的旋转角度）
        let yaw = atan2(sinr_cosp, cosr_cosp)

        return yaw * (180 / .pi)
    }

    private func getZYawDegreesFromQuaternion(_ quat: simd_quatf) -> Float {
        // 计算所需的中间变量
        let siny_cosp = 2 * (quat.real * quat.imag.z + quat.imag.x * quat.imag.y)
        let cosy_cosp = 1 - 2 * (quat.imag.z * quat.imag.z + quat.imag.x * quat.imag.x)

        // 计算 yaw 角（绕 z 轴的旋转角度）
        let yaw = atan2(siny_cosp, cosy_cosp)

        return yaw * (180 / .pi)
    }
}
