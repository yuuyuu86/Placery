import AuthenticationServices
import SwiftUI

struct SignInScreen: View {
    @Environment(AuthStore.self) private var auth
    @Environment(\.colorScheme) private var colorScheme

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

                Image(systemName: "bookmark.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(MomentPalette.ink.opacity(0.9))
                    .padding(.bottom, 22)

                Text("しおりを、あなたのものに。")
                    .font(.mincho(24, bold: true))
                    .foregroundStyle(MomentPalette.ink)

                Text("サインインすると、挟んだしおりを別の端末でも読み返せます。")
                    .font(.system(size: 13))
                    .lineSpacing(5)
                    .foregroundStyle(MomentPalette.ink.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
                    .padding(.horizontal, 20)

                Spacer()

                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName]
                } onCompletion: { result in
                    auth.handle(result)
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .clipShape(Capsule())
                .padding(.bottom, 34)
            }
            .padding(.horizontal, 34)
        }
        .alert("サインインできませんでした", isPresented: errorBinding) {
            Button("OK") { auth.signInError = nil }
        } message: {
            Text(auth.signInError ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { auth.signInError != nil },
            set: { if !$0 { auth.signInError = nil } }
        )
    }
}

#Preview {
    SignInScreen()
        .environment(AuthStore())
}
