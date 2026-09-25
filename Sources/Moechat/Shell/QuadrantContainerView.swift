import SwiftUI

/// 单个象限容器。
/// 收起态：一个方块，露出默认应用的图标。
/// 放大态：长宽各 3 倍，内部是 3×3 的子应用网格。
struct QuadrantContainerView: View {
    let quadrant: Quadrant
    let isExpanded: Bool
    let onTap: () -> Void
    let onAppTap: (SubApp) -> Void

    private let collapsedSize = CGSize(width: 84, height: 108)
    private let expansionScale: CGFloat = 3

    private var size: CGSize {
        isExpanded
            ? CGSize(width: collapsedSize.width * expansionScale,
                     height: collapsedSize.height * expansionScale)
            : collapsedSize
    }

    private var cornerRadius: CGFloat {
        isExpanded ? 30 : Theme.radiusContainer
    }

    var body: some View {
        Group {
            if isExpanded {
                expandedContent
            } else {
                collapsedContent
            }
        }
        .frame(width: size.width, height: size.height)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(isExpanded ? quadrant.accent.opacity(0.15) : Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    isExpanded ? quadrant.accent.opacity(0.55) : Theme.surfaceStroke,
                    lineWidth: 1
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
        .onTapGesture(perform: onTap)
        .help(quadrant.title)
    }

    // MARK: - 收起态

    private var collapsedContent: some View {
        VStack(spacing: 0) {
            appIcon(quadrant.defaultApp, size: 30)
            Spacer(minLength: 0)
            HStack(spacing: 5) {
                Circle()
                    .fill(quadrant.accent)
                    .frame(width: 5, height: 5)
                Text(quadrant.title)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .padding(11)
    }

    // MARK: - 放大态：3×3 网格

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(68), spacing: 8), count: 3),
                spacing: 8
            ) {
                ForEach(0..<9, id: \.self) { index in
                    if index < quadrant.apps.count {
                        appCell(quadrant.apps[index])
                    } else {
                        emptyCell
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
    }

    private func appCell(_ app: SubApp) -> some View {
        Button {
            onAppTap(app)
        } label: {
            VStack(spacing: 5) {
                Image(systemName: app.symbol)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.92))
                Text(app.title)
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.80))
            }
            .frame(width: 68, height: 68)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusGridCell)
                    .fill(quadrant.accent.opacity(0.20))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusGridCell)
                    .strokeBorder(quadrant.accent.opacity(0.38), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var emptyCell: some View {
        RoundedRectangle(cornerRadius: Theme.radiusGridCell)
            .fill(Color.white.opacity(0.03))
            .frame(width: 68, height: 68)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusGridCell)
                    .strokeBorder(
                        Color.white.opacity(0.09),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                    )
            )
    }

    private func appIcon(_ app: SubApp, size: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: size * 0.33)
            .fill(quadrant.accent.opacity(0.36))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: app.symbol)
                    .font(.system(size: size * 0.52, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.92))
            )
    }
}
