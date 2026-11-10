import SwiftUI

struct BookPageShape: Shape {
    var mirrored = false

    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: (mirrored ? 1 - x : x) * rect.width, y: y * rect.height)
        }

        var path = Path()
        path.move(to: point(0.5, 0.20))
        path.addLine(to: point(0.09, 0.10))
        path.addLine(to: point(0.09, 0.83))
        path.addLine(to: point(0.5, 0.93))
        path.closeSubpath()
        return path
    }
}

struct OpenBookMark: View {
    var bookmark: Bookmark
    var width: CGFloat = 44

    var body: some View {
        ZStack {
            BookPageShape()
                .fill(Color.surface)
                .overlay(BookPageShape().stroke(Color.moss, lineWidth: 1.4))
            BookPageShape(mirrored: true)
                .fill(Color.surface)
                .overlay(BookPageShape(mirrored: true).stroke(Color.moss, lineWidth: 1.4))

            BookmarkPhoto(bookmark: bookmark)
                .frame(width: width * 0.22, height: width * 0.2)
                .clipShape(RoundedRectangle(cornerRadius: 1.5))
                .offset(x: width * 0.14, y: -width * 0.03)

            Rectangle()
                .fill(Color.mossDeep)
                .frame(width: 1.6, height: width * 0.5)
                .offset(y: width * 0.03)
        }
        .frame(width: width, height: width * 0.68)
        .shadow(color: .black.opacity(0.22), radius: 3, y: 3)
    }
}

struct ClosedBookMark: View {
    var width: CGFloat = 28
    var highlighted = false

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.lockTint)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(highlighted ? Color.moss : Color.hairline, lineWidth: 1.4)
            )
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(highlighted ? Color.moss.opacity(0.8) : Color.hairline)
                    .frame(width: 1.2)
                    .padding(.vertical, 3)
                    .padding(.leading, width * 0.25)
            }
            .overlay(alignment: .trailing) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.hairline)
                            .frame(height: 1)
                    }
                }
                .frame(width: width * 0.34)
                .padding(.trailing, width * 0.14)
            }
            .frame(width: width, height: width * 1.08)
            .overlay(alignment: .topTrailing) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.lock)
                    .padding(3)
                    .background(Circle().fill(Color.surface))
                    .shadow(color: .black.opacity(0.16), radius: 2, y: 1)
                    .offset(x: 6, y: -6)
            }
            .shadow(color: .black.opacity(0.2), radius: 3, y: 3)
    }
}

#Preview {
    HStack(spacing: 30) {
        OpenBookMark(bookmark: Bookmark.samples[0])
        ClosedBookMark()
        ClosedBookMark(highlighted: true)
    }
    .padding(40)
    .background(Color.pageBackground)
}
