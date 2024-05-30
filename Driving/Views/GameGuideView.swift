//
//  GameGuideView.swift
//  Driving
//
//  Created by Nathan Mak on 2024/5/30.
//

import SwiftUI

struct GameGuideView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment: .leading) {
            Text("游戏说明")
                .font(.title)
            Text("转动方向盘：注视方向盘然后使用 visionOS 的转动双手手势来转动")
            Text("切换 D 档：右手掌平掌，手背向上🖐️")
            Text("切换 R 档：右手掌平掌，手心向上🖐️")
            Text("切换 P 档：右手握拳，手背向上👊")
            Text("刹车：右手握拳，手心向上👊")
            Text("打开/关闭远近光灯：右手手心向上，中指与拇指轻碰🤌")
            Text("打开/关闭转向灯：右手手心向上，无名指与拇指轻碰🤌")
            Text("打开/关闭双闪灯：右手手心向上，尾指与拇指轻碰🤌")
            Text("移动/固定方向盘与仪表盘位置：左手手心向上，中指与拇指轻碰🤌")
        }
        .padding(32)
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonBorderShape(.circle)
            .padding()
        }
    }
}

#Preview {
    GameGuideView()
        .glassBackgroundEffect()
}
