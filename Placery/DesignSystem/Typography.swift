import SwiftUI

extension Font {
    /// 地名や演出文に使う明朝体。iOSに標準搭載のヒラギノ明朝を使い、フォント同梱を避けている。
    static func mincho(_ size: CGFloat, bold: Bool = false) -> Font {
        .custom(bold ? "HiraMinProN-W6" : "HiraMinProN-W3", size: size)
    }

    static func label(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold)
    }
}

extension View {
    func sectionLabel() -> some View {
        font(.label(11))
            .kerning(0.5)
            .foregroundStyle(Color.inkSoft)
    }
}
