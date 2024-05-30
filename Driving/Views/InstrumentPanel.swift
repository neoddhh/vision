//
//  InstrumentPanel.swift
//  Driving
//
//  Created by Nathan Mak on 2024/5/24.
//

import SwiftUI

struct InstrumentPanel: View {
    @Environment(GameModel.self) var gameModel
    var body: some View {
        VStack {
            HStack(spacing: 8) {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                            .imageScale(.large)
                            .foregroundStyle(.black)
                            .frame(width: 40, height: 40)
                            .background(.green, in: .circle)
                        Text(gameModel.speed.text)
                            .font(.largeTitle.bold())
                            .fontDesign(.rounded)
                            + Text(" 档")
                    }
                    Text("当前速度")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(width: 200)
                .background(.instrumentPanelBlock, in: .rect(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "fuelpump.circle")
                            .imageScale(.large)
                            .foregroundStyle(.black)
                            .frame(width: 40, height: 40)
                            .background(.blue, in: .circle)
                        Text(gameModel.fuelPercent.formatted(.percent.grouping(.never)))
                            .font(.largeTitle.bold())
                            .fontDesign(.rounded)
                    }
                    Text("剩余油量")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(width: 200)
                .background(.instrumentPanelBlock, in: .rect(cornerRadius: 8, style: .continuous))
            }

            HStack {
                Text("P")
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(gameModel.grade == .p ? .red : .clear, in: .rect(cornerRadius: 8, style: .continuous))
                Text("D")
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(gameModel.grade == .d ? .orange : .clear, in: .rect(cornerRadius: 8, style: .continuous))
                Text("R")
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(gameModel.grade == .r ? .purple : .clear, in: .rect(cornerRadius: 8, style: .continuous))
            }
            .font(.largeTitle)
            .padding()
            .frame(width: 408)
            .background(.instrumentPanelBlock, in: .rect(cornerRadius: 8, style: .continuous))

            HStack {
                VStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(gameModel.areHighAndLowBeamsOn ? .yellow : .gray)
                        .imageScale(.large)
                    Text("远近光灯")
                }
                .frame(maxWidth: .infinity)
                VStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(gameModel.areTurnSignalsOn ? .yellow : .gray)
                        .imageScale(.large)
                    Text("转向灯")
                }
                .frame(maxWidth: .infinity)
                VStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(gameModel.areDoubleFlashingLightsOn ? .yellow : .gray)
                        .imageScale(.large)
                    Text("双闪灯")
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .frame(width: 408)
            .background(.instrumentPanelBlock, in: .rect(cornerRadius: 8, style: .continuous))
        }
        .padding(30)
        .background(.instrumentPanelBackground, in: .rect(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    InstrumentPanel()
        .frame(width: 640, height: 480)
        .glassBackgroundEffect()
        .environment(GameModel())
}
