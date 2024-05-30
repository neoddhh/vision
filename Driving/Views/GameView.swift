//
//  ImmersiveView.swift
//  Driving
//
//  Created by Nathan Mak on 2024/5/22.
//

import RealityKit
import RealityKitContent
import SwiftUI

struct GameView: View {
    @Environment(GameModel.self) private var gameModel
    @Environment(\.realityKitScene) private var scene
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        RealityView { content, attachments in
            async let raceSceneAsync = try! Entity(named: "Race", in: realityKitContentBundle)
            async let steeringWheelAsync = try! Entity(named: "SteeringWheel", in: realityKitContentBundle)

            let raceScene = await raceSceneAsync
            let steeringWheel = await steeringWheelAsync

            let car = raceScene.findEntity(named: "Car")!
            car.components.set(MoveComponent(gameModel: gameModel))
            let light1 = car.findEntity(named: "_______035_002_132")!.children.first as! ModelEntity
            let light2 = car.findEntity(named: "_______035_002_134")!.children.first as! ModelEntity
            let light3 = car.findEntity(named: "_______035_002")!.children.first as! ModelEntity
            gameModel.car = car
            gameModel.light1 = light1
            gameModel.light2 = light2
            gameModel.light3 = light3
            gameModel.light1Material = light1.model!.materials
            gameModel.light2Material = light2.model!.materials
            gameModel.light3Material = light3.model!.materials

            let fence = raceScene.findEntity(named: "Fence")!
            for it in fence.children {
                if it.name.hasPrefix("Cube") {
                    let modelEntity = it as! ModelEntity
                    modelEntity.model?.materials = [UnlitMaterial(color: .clear)]
                }
                if it.name.hasPrefix("Cylinder") {
                    let modelEntity = it.children.first as! ModelEntity
                    modelEntity.model?.materials = [UnlitMaterial(color: .clear)]
                }
            }

            let headAnchorEntity = gameModel.headAnchorEntity
            headAnchorEntity.anchoring.trackingMode = .once
            if let flatSteeringWheel = steeringWheel.findEntity(named: "FlatSteeringWheel") {
                flatSteeringWheel.components.set(HoverEffectComponent())
                flatSteeringWheel.components.set(RotationComponent())
            }
            headAnchorEntity.addChild(steeringWheel)
            if let instrumentPanel = attachments.entity(for: "InstrumentPanel") {
                instrumentPanel.position = [-0.4, -0.35, -0.4]
                instrumentPanel.orientation *= simd_quatf(angle: -.pi / 4, axis: [1, 0, 0])
                headAnchorEntity.addChild(instrumentPanel)
            }

            let carCollisionDetectHead = car.findEntity(named: "CarCollisionDetectHead")!
            let carCollisionDetectTail = car.findEntity(named: "CarCollisionDetectTail")!
            (carCollisionDetectHead.children.first as! ModelEntity).model?.materials = [UnlitMaterial(color: .clear)]
            (carCollisionDetectTail.children.first as! ModelEntity).model?.materials = [UnlitMaterial(color: .clear)]
            let subscription1 = content.subscribe(to: CollisionEvents.Began.self, on: carCollisionDetectHead) { _ in
                gameModel.pauseCarGoForward()
            }
            let subscription2 = content.subscribe(to: CollisionEvents.Began.self, on: carCollisionDetectTail) { _ in
                gameModel.pauseCarGoBack()
            }
            let subscription3 = content.subscribe(to: CollisionEvents.Ended.self, on: carCollisionDetectHead) { _ in
                gameModel.resetCarGoForward()
            }
            let subscription4 = content.subscribe(to: CollisionEvents.Ended.self, on: carCollisionDetectTail) { _ in
                gameModel.resetCarGoBack()
            }
            gameModel.eventSubscriptions.append(subscription1)
            gameModel.eventSubscriptions.append(subscription2)
            gameModel.eventSubscriptions.append(subscription3)
            gameModel.eventSubscriptions.append(subscription4)

            content.add(raceScene)
            content.add(headAnchorEntity)

        } placeholder: {
            ProgressView()
        } attachments: {
            Attachment(id: "InstrumentPanel") {
                InstrumentPanel()
            }
        }
        .gesture(
            RotateGesture().targetedToAnyEntity()
                .handActivationBehavior(.pinch)
                .onChanged { value in
                    let entity = value.entity
                    guard let rotatableComponent = entity.components[RotationComponent.self] else { return }
                    let angle = -value.rotation
                    let newAngle = rotatableComponent.startAngle + angle
                    entity.orientation = simd_quatf(angle: Float(newAngle.radians), axis: [0, 1, 0])
                    gameModel.swerveCar(angle: newAngle)
                }
                .onEnded { value in
                    let entity = value.entity
                    guard let rotatableComponent = entity.components[RotationComponent.self] else { return }
                    let angle = -value.rotation
                    let newAngle = rotatableComponent.startAngle + angle
                    entity.orientation = simd_quatf(angle: Float(newAngle.radians), axis: [0, 1, 0])
                    entity.components[RotationComponent.self]?.startAngle = newAngle
                    gameModel.swerveCar(angle: newAngle)
                }
        )
        .task {
            await gameModel.startGame()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .background {
                gameModel.stopGame()
            }
        }
    }
}

#Preview(immersionStyle: .mixed) {
    GameView()
        .environment(GameModel())
}
