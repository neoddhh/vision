//
//  DrivingApp.swift
//  Driving
//
//  Created by Nathan Mak on 2024/5/22.
//

import SwiftUI

@main
struct DrivingApp: App {
    
    @State private var gameModel: GameModel = GameModel()

    init() {
        RotationComponent.registerComponent()
        MoveComponent.registerComponent()
        MoveSystem.registerSystem()
    }

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(gameModel)
        }
        .windowStyle(.plain)

        ImmersiveSpace(id: "ImmersiveSpace") {
            GameView()
                .environment(gameModel)
        }
    }
}
