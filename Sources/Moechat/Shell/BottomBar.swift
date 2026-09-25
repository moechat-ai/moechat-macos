import SwiftUI

/// 底栏 —— 四个象限容器。点击容器放大为 3 倍，露出子应用网格。
struct BottomBar: View {
    @Binding var expanded: Quadrant?
    @Binding var activeApp: SubApp?

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Quadrant.allCases) { quadrant in
                QuadrantContainerView(
                    quadrant: quadrant,
                    isExpanded: expanded == quadrant,
                    onTap: { handleTap(quadrant) },
                    onAppTap: { app in
                        activeApp = app
                        expanded = nil
                    }
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Theme.shellPadding)
        .padding(.bottom, 26)
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: expanded)
    }

    /// 点击容器：容器放大，同时默认应用自动进入。再点一次收起。
    private func handleTap(_ quadrant: Quadrant) {
        if expanded == quadrant {
            expanded = nil
        } else {
            expanded = quadrant
            activeApp = quadrant.defaultApp
        }
    }
}
