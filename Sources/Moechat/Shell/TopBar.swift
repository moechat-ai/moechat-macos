import SwiftUI

/// 顶栏 = 第 0 象限（时空）。
/// 左：主体图标，点击切换主体；中：可输入的地址栏；右：后退 / 前进 / 刷新。
struct TopBar: View {
    let subject: Subject
    @Binding var address: SpacetimeAddress

    var body: some View {
        HStack(spacing: 10) {
            SubjectBadge(subject: subject)
            AddressField(address: $address)
            NavigationButtons()
        }
        .padding(.horizontal, Theme.shellPadding)
        .padding(.top, 10)
        .padding(.bottom, 16)
    }
}

/// 主体图标 —— 时空环里嵌着当前主体，所以「点击它切换主体」是自然的。
struct SubjectBadge: View {
    let subject: Subject

    var body: some View {
        Button {
            // TODO: 打开主体切换面板
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.03))
                    .frame(width: 40, height: 40)
                Circle()
                    .strokeBorder(Color.white.opacity(0.20), lineWidth: 1)
                    .frame(width: 40, height: 40)
                Circle()
                    .fill(Color(hex: 0x3E9BD6))
                    .frame(width: 28, height: 28)
                Text(subject.initial)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x08131C))
            }
        }
        .buttonStyle(.plain)
        .help("切换主体")
    }
}

/// 地址栏 —— 装的是时空坐标，允许输入以跳转到别的时空。
struct AddressField: View {
    @Binding var address: SpacetimeAddress
    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            TextField("时空坐标", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Theme.addressText)
                .focused($isFocused)
                .onSubmit(commit)

            if !isFocused {
                Rectangle()
                    .fill(Color(hex: 0x3E9BD6))
                    .frame(width: 1, height: 13)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(Theme.addressBar, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
        .onAppear { text = address.text }
    }

    private func commit() {
        // TODO: 解析输入并跳转。解析规则见待确认清单第 13 条。
    }
}

struct NavigationButtons: View {
    var body: some View {
        HStack(spacing: 4) {
            navButton("chevron.left", help: "后退")
            navButton("chevron.right", help: "前进")
            navButton("arrow.clockwise", help: "刷新")
        }
    }

    private func navButton(_ symbol: String, help: String) -> some View {
        Button {
            // TODO: 时空历史导航
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.62))
                .frame(width: 26, height: 26)
                .background(Color.white.opacity(0.06), in: Circle())
        }
        .buttonStyle(.plain)
        .help(help)
    }
}
