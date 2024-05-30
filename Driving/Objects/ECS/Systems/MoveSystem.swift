import RealityKit
import SwiftUI

public struct MoveSystem: System {
    private let forward = SIMD3<Float>(0, 0, -1)
    private let backward = SIMD3<Float>(0, 0, 1)

    static let moveQuery = EntityQuery(where: .has(MoveComponent.self))

    public init(scene: RealityKit.Scene) {
    }

    public func update(context: SceneUpdateContext) {
        let entities = context.scene.performQuery(Self.moveQuery)
        for entity in entities {
            guard let moveComponent = entity.components[MoveComponent.self] else { continue }
            let gameModel = moveComponent.gameModel
            let deltaTime = Float(context.deltaTime)
            if gameModel.grade == .d && gameModel.fuel > 0 {
                let forwardDirection = entity.transform.rotation.act(forward)
                let distance = gameModel.speed.value / 5 * deltaTime
                entity.transform.translation += forwardDirection * distance
                gameModel.fuel = max(gameModel.fuel - distance, 0)
            } else if gameModel.grade == .r && gameModel.fuel > 0 {
                let backwardDirection = entity.transform.rotation.act(backward)
                let distance = gameModel.speed.value / 5 * deltaTime
                entity.transform.translation += backwardDirection * distance
                gameModel.fuel = max(gameModel.fuel - distance, 0)
            }
        }
    }
}
