import SwiftUI

struct UnlockMomentView: View {
    var bookmark: Bookmark

    @Environment(\.dismiss) private var dismiss
    @State private var isOpen = false
    @State private var showsDetail = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [MomentPalette.top, MomentPalette.bottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.16), .clear],
                            center: .center,
                            startRadius: 4,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(y: -70)

                VStack(spacing: 0) {
                    Spacer()

                    OpeningBook(photo: bookmark.photo, angle: isOpen ? -152 : 0)
                        .frame(width: 132, height: 104)
                        .offset(x: isOpen ? 62 : 0)
                        .padding(.bottom, 44)

                    Text("しおりが開きました")
                        .font(.mincho(24, bold: true))
                        .kerning(1.6)
                        .foregroundStyle(MomentPalette.ink)

                    Text(bookmark.placeName)
                        .font(.system(size: 13))
                        .foregroundStyle(MomentPalette.ink.opacity(0.82))
                        .padding(.top, 6)

                    Text("@\(bookmark.author) · \(bookmark.postedAt.formatted(.dateTime.year().month().day())) に挟まれたしおり")
                        .font(.system(size: 11))
                        .foregroundStyle(MomentPalette.ink.opacity(0.5))
                        .padding(.top, 18)

                    Spacer()

                    Button("読む") { showsDetail = true }
                        .font(.system(size: 15, weight: .bold))
                        .padding(.horizontal, 34)
                        .padding(.vertical, 6)
                        .buttonStyle(.glassProminent)
                        .buttonBorderShape(.capsule)
                        .tint(MomentPalette.ink)
                        .foregroundStyle(MomentPalette.bottom)

                    Button("あとで読む") { dismiss() }
                        .font(.system(size: 13))
                        .foregroundStyle(MomentPalette.ink.opacity(0.6))
                        .padding(.top, 16)
                        .padding(.bottom, 30)
                }
                .padding(.horizontal, 32)
                .multilineTextAlignment(.center)
            }
            .navigationDestination(isPresented: $showsDetail) {
                BookmarkDetailScreen(bookmark: bookmark)
            }
        }
        .task {
            withAnimation(.easeInOut(duration: 1.3).delay(0.35)) {
                isOpen = true
            }
        }
    }
}

private struct OpeningBook: View, Animatable {
    var photo: PhotoSwatch
    var angle: Double

    nonisolated var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(photo.gradient)
                .shadow(color: .black.opacity(0.55), radius: 12, y: 8)

            cover
                .rotation3DEffect(
                    .degrees(angle),
                    axis: (x: 0, y: 1, z: 0),
                    anchor: .leading,
                    perspective: 0.5
                )
        }
    }

    @ViewBuilder
    private var cover: some View {
        if angle > -90 {
            RoundedRectangle(cornerRadius: 5)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.36, green: 0.48, blue: 0.37), Color(red: 0.21, green: 0.29, blue: 0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Color(red: 0.16, green: 0.23, blue: 0.15))
                        .frame(width: 5)
                }
                .shadow(color: .black.opacity(0.6), radius: 14, y: 10)
        } else {
            RoundedRectangle(cornerRadius: 5)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.97, green: 0.96, blue: 0.92), Color(red: 0.89, green: 0.86, blue: 0.80)],
                        startPoint: .bottomTrailing,
                        endPoint: .topLeading
                    )
                )
                .scaleEffect(x: -1, y: 1)
        }
    }
}

#Preview {
    UnlockMomentView(bookmark: Bookmark.samples[0])
}
