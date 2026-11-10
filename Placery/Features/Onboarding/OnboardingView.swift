import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void

    @Environment(LocationStore.self) private var location

    @State private var step = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [MomentPalette.top, MomentPalette.bottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Group {
                    if step == 0 {
                        concept
                    } else {
                        locationStep
                    }
                }
                .transition(.opacity)

                Spacer()

                HStack(spacing: 7) {
                    ForEach(0..<2, id: \.self) { index in
                        Capsule()
                            .fill(MomentPalette.ink.opacity(index == step ? 0.9 : 0.28))
                            .frame(width: index == step ? 18 : 6, height: 6)
                    }
                }
                .padding(.bottom, 22)

                Button(step == 0 ? "はじめる" : "位置情報を許可する") {
                    if step == 0 {
                        withAnimation(.easeInOut(duration: 0.25)) { step = 1 }
                    } else {
                        location.requestWhenInUse()
                        onFinish()
                    }
                }
                .font(.system(size: 15, weight: .bold))
                .padding(.horizontal, 40)
                .padding(.vertical, 6)
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
                .tint(MomentPalette.ink)
                .foregroundStyle(MomentPalette.bottom)

                Button("あとで") { onFinish() }
                    .font(.system(size: 13))
                    .foregroundStyle(MomentPalette.ink.opacity(0.55))
                    .padding(.top, 14)
                    .padding(.bottom, 34)
                    .opacity(step == 1 ? 1 : 0)
            }
            .padding(.horizontal, 34)
            .multilineTextAlignment(.center)
        }
    }

    private var concept: some View {
        VStack(spacing: 18) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 44))
                .foregroundStyle(MomentPalette.ink.opacity(0.9))
                .padding(.bottom, 6)

            Text("その場所に行った人だけが、\n読めるしおり。")
                .font(.mincho(25, bold: true))
                .lineSpacing(8)
                .foregroundStyle(MomentPalette.ink)

            Text("思い入れのある場所に、写真とことばを挟んでおく。\n誰かがその場所を訪れたとき、しおりが開きます。")
                .font(.system(size: 13))
                .lineSpacing(5)
                .foregroundStyle(MomentPalette.ink.opacity(0.7))
        }
    }

    private var locationStep: some View {
        VStack(spacing: 18) {
            Image(systemName: "location.fill")
                .font(.system(size: 40))
                .foregroundStyle(MomentPalette.ink.opacity(0.9))
                .padding(.bottom, 6)

            Text("いまいる場所を教えてください")
                .font(.mincho(23, bold: true))
                .foregroundStyle(MomentPalette.ink)

            Text("近くのしおりを地図に表示し、現地に着いたときに開くために使います。\n位置情報が誰かに共有されることはありません。")
                .font(.system(size: 13))
                .lineSpacing(5)
                .foregroundStyle(MomentPalette.ink.opacity(0.7))

            Text("アプリを閉じているときの通知は、あとから設定できます。")
                .font(.system(size: 11))
                .foregroundStyle(MomentPalette.ink.opacity(0.45))
                .padding(.top, 4)
        }
    }
}

#Preview {
    OnboardingView {}
        .environment(LocationStore())
}
