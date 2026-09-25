import SwiftUI

/// 单个象限容器。
/// 收起态：一个方块，露出默认应用的图标。
/// 放大态：长宽各 3 倍，内部是 3×3 的子应用网格。
struct QuadrantContainerView: View {
    let quadrant: Quadrant
    let isExpanded: Bool
    let onTap: () -> Void
    let onAppTap: (SubApp) -> Void

    @Environment(\.catalog) private var catalog

    /// 收起态尺寸：底栏里的一格。
    private let collapsedSize = CGSize(width: 84, height: 108)

    /// 展开态的格子与间距。
    private let cellSize: CGFloat = 68
    private let cellGap: CGFloat = 8
    private let expansionPadding: CGFloat = 16

    /// 网格形状由内容量决定：最多 3 列，行数按需计算。
    private var appCount: Int { quadrant.apps.count }
    private var gridColumns: Int { min(3, max(1, appCount)) }
    private var gridRows: Int {
        Int(ceil(Double(appCount) / Double(gridColumns)))
    }

    /// 展开尺寸由内容决定——内容少就小，只有装满 3×3 时才达到 3 倍。
    private var expandedSize: CGSize {
        let w = CGFloat(gridColumns) * cellSize
            + CGFloat(gridColumns - 1) * cellGap
            + expansionPadding * 2
        let h = CGFloat(gridRows) * cellSize
            + CGFloat(gridRows - 1) * cellGap
            + expansionPadding * 2
        return CGSize(width: w, height: h)
    }

    private var size: CGSize {
        isExpanded ? expandedSize : collapsedSize
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
        .help(catalog[quadrant.titleKey])
    }

    // MARK: - 收起态

    /// 收起态显示的是「内容的缩略图」——里面有什么，图标就是什么。
    /// 与 Android 桌面文件夹同理：文件夹图标本身是内容的缩影。
    private var collapsedContent: some View {
        VStack(spacing: 0) {
            thumbnail
            Spacer(minLength: 0)
            HStack(spacing: 5) {
                Circle()
                    .fill(quadrant.accent)
                    .frame(width: 5, height: 5)
                Text(catalog[quadrant.titleKey])
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(Theme.secondaryText)
                    // 收起态容器只有 84pt 宽，英文的 "Possessions" 会折成两行并撑出容器。
                    // 限一行 + 尾部省略，与 Android 侧同一行为。
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(11)
    }

    /// 缩略图沿用展开态的同一套布局，做到所见即所得。
    private var thumbnail: some View {
        let columns = gridColumns
        let rows = gridRows
        let gap: CGFloat = 5
        let available = collapsedSize.width - 22
        let cell = min(26, (available - gap * CGFloat(columns - 1)) / CGFloat(columns))

        return Grid(horizontalSpacing: gap, verticalSpacing: gap) {
            ForEach(0..<rows, id: \.self) { row in
                GridRow {
                    ForEach(0..<columns, id: \.self) { column in
                        let index = row * columns + column
                        if index < appCount {
                            thumbnailIcon(quadrant.apps[index], size: cell)
                        } else {
                            Color.clear.frame(width: cell, height: cell)
                        }
                    }
                }
            }
        }
    }

    private func thumbnailIcon(_ app: SubApp, size: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: size * 0.28)
            .fill(quadrant.accent.opacity(0.34))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: app.symbol)
                    .font(.system(size: size * 0.54, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.90))
            )
    }

    // MARK: - 放大态：3×3 网格

    /// 展开态：网格形状与缩略图一致，尺寸刚好容纳内容，不留空槽。
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.fixed(cellSize), spacing: cellGap),
                    count: gridColumns
                ),
                spacing: cellGap
            ) {
                ForEach(quadrant.apps) { app in
                    appCell(app)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(expansionPadding)
    }

    private func appCell(_ app: SubApp) -> some View {
        Button {
            onAppTap(app)
        } label: {
            VStack(spacing: 5) {
                Image(systemName: app.symbol)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.92))
                Text(catalog[app.title])
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.80))
                    // 格子 68pt 宽，长词同样要限一行。
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(width: cellSize, height: cellSize)
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

}
