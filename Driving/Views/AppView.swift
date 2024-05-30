//
//  ContentView.swift
//  Driving
//
//  Created by Nathan Mak on 2024/5/22.
//

import RealityKit
import RealityKitContent
import SwiftUI

struct AppView: View {
    @Environment(GameModel.self) private var gameModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.scenePhase) private var scenePhase
    @State private var isGameGuidePresented = false
    var body: some View {
        ZStack(alignment: .bottom) {
            Image(.poster)
                .resizable()
                .scaledToFit()
                .clipShape(.rect(cornerRadius: 100, style: .continuous))
            VStack {
                if gameModel.status == .isStopped {
                    Button {
                        Task {
                            await openImmersiveSpace(id: "ImmersiveSpace")
                        }
                    } label: {
                        Text("开始")
                            .font(.largeTitle)
                            .frame(width: 400, height: 60)
                    }
                } else {
                    Button {
                        Task {
                            gameModel.stopGame()
                            await dismissImmersiveSpace()
                        }
                    } label: {
                        Text("停止")
                            .font(.largeTitle)
                            .frame(width: 400, height: 60)
                    }
                }
                Button {
                    isGameGuidePresented = true
                } label: {
                    Text("游戏说明")
                        .font(.largeTitle)
                        .frame(width: 400, height: 60)
                }
            }
            .padding(.bottom)
        }
        .sheet(isPresented: $isGameGuidePresented) {
            GameGuideView()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .background {
                gameModel.stopGame()
                Task {
                    await dismissImmersiveSpace()
                }
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    AppView()
        .environment(GameModel())
}
