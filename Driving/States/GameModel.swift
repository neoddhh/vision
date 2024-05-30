//
//  GameModel.swift
//  Driving
//
//  Created by Nathan Mak on 2024/5/22.
//

import ARKit
import Combine
import Foundation
import Observation
import RealityKit
import SwiftUI

@Observable
class GameModel: NSObject {
    var status: GameStatus = .isStopped

    // 仪表盘数据
    var speed = Speed.zero // 速度
    var grade = Grade.p // 档位
    var areHighAndLowBeamsOn = false // 是否开启远近光灯
    var areTurnSignalsOn = false // 是否开启转向灯
    var areDoubleFlashingLightsOn = false // 是否开启双闪灯
    var fuelPercent = 100 // 油量
    @ObservationIgnored
    var fuel: Float = 100 {
        didSet {
            fuelPercent = Int(fuel)
            if fuelPercent == 0 && fuel != 0 {
                fuelPercent = 1
            }
        }
    }

    // Entities
    @ObservationIgnored
    let headAnchorEntity = AnchorEntity(.head)
    @ObservationIgnored
    var car = Entity()
    @ObservationIgnored
    var light1 = ModelEntity()
    @ObservationIgnored
    var light2 = ModelEntity()
    @ObservationIgnored
    var light3 = ModelEntity()
    @ObservationIgnored
    var light1Material: [any RealityKit.Material] = []
    @ObservationIgnored
    var light2Material: [any RealityKit.Material] = []
    @ObservationIgnored
    var light3Material: [any RealityKit.Material] = []

    @ObservationIgnored
    var canGoForward = 0
    @ObservationIgnored
    var canGoBack = 0
    @ObservationIgnored
    var eventSubscriptions: Array<EventSubscription> = []

    @ObservationIgnored
    let session = ARKitSession()
    @ObservationIgnored
    var handTracking = HandTrackingProvider()

    @ObservationIgnored
    let handGestureRecognizer = HandGestureRecognizer()

    @ObservationIgnored
    var lightFlag = true
    @ObservationIgnored
    var timer: Timer?
    @ObservationIgnored
    var audioResource: AudioFileResource
    @ObservationIgnored
    var audioPlaybackController: AudioPlaybackController?

    override init() {
        audioResource = try! AudioFileResource.load(named: "Car", configuration: .init(shouldLoop: true))
        super.init()
        handGestureRecognizer.delegate = self
    }

    @MainActor
    func startGame() async {
        do {
            if HandTrackingProvider.isSupported {
                try await session.run([handTracking])
                status = .isRunning
                handGestureRecognizer.handTrackingProvider = handTracking
                handGestureRecognizer.detectHandGesture()
            }
        } catch {
            print("ARKitSession error:", error)
        }
    }

    func stopGame() {
        session.stop()
        status = .isStopped
        handGestureRecognizer.stopDetectHandGesture()
        resetGame()
    }

    func swerveCar(angle: Angle) {
        car.orientation = simd_quatf(angle: Float(angle.radians), axis: [0, 1, 0])
    }

    func shiftCarSpeed(by speed: Speed) {
        guard (grade == .d && canGoForward == 0) || (grade == .r && canGoBack == 0) || speed == .zero else {
            return
        }
        self.speed = speed
    }

    func changeCarGrade(for grade: Grade) {
        guard speed == .zero else { return }
        self.grade = grade
        if grade == .p {
            if let audioPlaybackController {
                audioPlaybackController.stop()
            }
        } else {
            if let audioPlaybackController {
                if !audioPlaybackController.isPlaying {
                    audioPlaybackController.play()
                }
            } else {
                audioPlaybackController = car.prepareAudio(audioResource)
                audioPlaybackController!.play()
            }
        }
    }

    func pauseCarGoForward() {
        canGoForward += 1
        shiftCarSpeed(by: .zero)
    }

    func pauseCarGoBack() {
        canGoBack += 1
        shiftCarSpeed(by: .zero)
    }

    func resetCarGoForward() {
        canGoForward -= 1
    }

    func resetCarGoBack() {
        canGoBack -= 1
    }

    func resetSteeringWheelAndInstructmentPanel() {
        headAnchorEntity.anchoring.trackingMode = headAnchorEntity.anchoring.trackingMode == .once ? .continuous : .once
    }

    func toggleHighAndLowBeams() {
        resetLights()
        areHighAndLowBeamsOn.toggle()
        areTurnSignalsOn = false
        areDoubleFlashingLightsOn = false
        if areHighAndLowBeamsOn {
            timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                if self.lightFlag {
                    self.light1.model?.materials = [UnlitMaterial(color: .yellow)]
                    self.light2.model?.materials = [UnlitMaterial(color: .yellow)]
                } else {
                    self.light1.model?.materials = [UnlitMaterial(color: .black)]
                    self.light2.model?.materials = [UnlitMaterial(color: .black)]
                }
                self.lightFlag.toggle()
            }
        }
    }

    func toggleTurnSignals() {
        resetLights()
        areTurnSignalsOn.toggle()
        areHighAndLowBeamsOn = false
        areDoubleFlashingLightsOn = false
        if areTurnSignalsOn {
            timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                if self.lightFlag {
                    self.light3.model?.materials = [UnlitMaterial(color: .red)]
                } else {
                    self.light3.model?.materials = [UnlitMaterial(color: .black)]
                }
                self.lightFlag.toggle()
            }
        }
    }

    func toggleDoubleFlashingLights() {
        resetLights()
        areDoubleFlashingLightsOn.toggle()
        areHighAndLowBeamsOn = false
        areTurnSignalsOn = false
        if areDoubleFlashingLightsOn {
            timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                if self.lightFlag {
                    self.light1.model?.materials = [UnlitMaterial(color: .yellow)]
                    self.light2.model?.materials = [UnlitMaterial(color: .yellow)]
                    self.light3.model?.materials = [UnlitMaterial(color: .yellow)]
                } else {
                    self.light1.model?.materials = [UnlitMaterial(color: .black)]
                    self.light2.model?.materials = [UnlitMaterial(color: .black)]
                    self.light3.model?.materials = [UnlitMaterial(color: .black)]
                }
                self.lightFlag.toggle()
            }
        }
    }

    func resetGame() {
        speed = .zero
        grade = .p
        areTurnSignalsOn = false
        areHighAndLowBeamsOn = false
        areDoubleFlashingLightsOn = false
        fuel = 100
        canGoForward = 0
        canGoBack = 0
        headAnchorEntity.children.forEach({ headAnchorEntity.removeChild($0) })
        eventSubscriptions.forEach({ $0.cancel() })
        eventSubscriptions = []
        lightFlag = true
        timer?.invalidate()
        timer = nil
        audioPlaybackController?.stop()
        audioPlaybackController = nil
        handTracking = HandTrackingProvider()
    }

    private func resetLights() {
        timer?.invalidate()
        lightFlag = true
        light1.model?.materials = light1Material
        light2.model?.materials = light2Material
        light3.model?.materials = light3Material
    }
}

extension GameModel: HandGestureRecognizerDelegate {
    func didDetect(for action: DriveAction) {
        switch action {
        case .dGrade:
            changeCarGrade(for: .d)
        case .rGrade:
            changeCarGrade(for: .r)
        case .pGrade:
            changeCarGrade(for: .p)
        case .brake:
            shiftCarSpeed(by: .zero)
        case .firstSpeed:
            shiftCarSpeed(by: .first)
        case .secondSpeed:
            shiftCarSpeed(by: .second)
        case .thirdSpeed:
            shiftCarSpeed(by: .third)
        case .fouthSpeed:
            shiftCarSpeed(by: .fourth)
        case .toggleHighAndLowBeams:
            toggleHighAndLowBeams()
        case .toggleTurnSignals:
            toggleTurnSignals()
        case .toggleDoubleFlashingLights:
            toggleDoubleFlashingLights()
        case .resetSteeringWheelAndInstructmentPanel:
            resetSteeringWheelAndInstructmentPanel()
        case .none:
            break
        }
    }
}
