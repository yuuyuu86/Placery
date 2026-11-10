import CoreLocation
import PhotosUI
import SwiftUI

struct ComposeScreen: View {
    var coordinate: CLLocationCoordinate2D?

    @Environment(BookmarkStore.self) private var store
    @Environment(SubscriptionStore.self) private var subscription
    @Environment(CloudSyncService.self) private var cloud
    @Environment(\.dismiss) private var dismiss

    @State private var showsPaywall = false

    @State private var pickedItems: [PhotosPickerItem] = []
    @State private var photoFiles: [String] = []
    @State private var isLoadingPhotos = false
    @State private var placeName = ""
    @State private var note = ""
    @State private var rating = 0
    @State private var tags: Set<String> = []
    @State private var visibility: Visibility = .followers
    @State private var readableAnywhere = false

    private let tagOptions = ["絶景", "穴場", "カフェ", "グルメ", "思い出"]

    private var hasReachedFreeLimit: Bool {
        !subscription.isPlus && store.bookmarksThisMonth >= BookmarkStore.freeMonthlyLimit
    }

    private var photoLimit: Int {
        subscription.isPlus ? 5 : 1
    }

    private var canSubmit: Bool {
        !photoFiles.isEmpty && !placeName.isEmpty && !note.isEmpty && rating > 0 && !hasReachedFreeLimit
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if hasReachedFreeLimit {
                        limitCard
                    }
                    photoSection
                    placeSection
                    noteSection
                    ratingSection
                    tagSection
                    visibilitySection
                    if visibility == .everyone {
                        warningCard
                    }
                    lockToggle
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color.pageBackground)
            .navigationTitle("しおりを挟む")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) { submitBar }
            .sheet(isPresented: $showsPaywall) { PaywallView() }
        }
    }

    private var limitCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("今月のしおりを使い切りました", systemImage: "books.vertical.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.mossDeep)

            Text("無料プランでは1か月に\(BookmarkStore.freeMonthlyLimit)枚まで挟めます。Plusにすると無制限になります。")
                .font(.system(size: 11.5))
                .foregroundStyle(Color.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            Button("Placery Plus を見る") { showsPaywall = true }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.mossDeep)
                .padding(.top, 2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.mossTint))
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            labelRow("写真", required: true)

            HStack(spacing: 10) {
                ForEach(photoFiles, id: \.self) { name in
                    if let image = PhotoLibrary.shared.image(named: name) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 74, height: 74)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    remove(name)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 17))
                                        .foregroundStyle(.white, .black.opacity(0.5))
                                }
                                .offset(x: 6, y: -6)
                            }
                    }
                }

                if photoFiles.count < photoLimit {
                    PhotosPicker(
                        selection: $pickedItems,
                        maxSelectionCount: photoLimit - photoFiles.count,
                        matching: .images
                    ) {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.hairline, style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                            .frame(width: 74, height: 74)
                            .overlay {
                                if isLoadingPhotos {
                                    ProgressView()
                                } else {
                                    Image(systemName: "plus")
                                        .font(.system(size: 18))
                                        .foregroundStyle(Color.lock)
                                }
                            }
                    }
                }
            }

            if !subscription.isPlus {
                Text("無料プランでは写真は1枚までです。")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Color.inkSoft)
            }
        }
        .onChange(of: pickedItems) { _, items in
            guard !items.isEmpty else { return }
            Task { await load(items) }
        }
    }

    private func load(_ items: [PhotosPickerItem]) async {
        isLoadingPhotos = true
        defer {
            isLoadingPhotos = false
            pickedItems = []
        }

        for item in items {
            guard photoFiles.count < photoLimit,
                  let data = try? await item.loadTransferable(type: Data.self),
                  let name = PhotoLibrary.shared.save(data) else { continue }
            photoFiles.append(name)
        }
    }

    private func remove(_ name: String) {
        photoFiles.removeAll { $0 == name }
        PhotoLibrary.shared.delete([name])
    }

    private var placeSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            labelRow("場所", required: true)
            HStack(spacing: 10) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(Color.moss)
                VStack(alignment: .leading, spacing: 2) {
                    TextField("場所の名前", text: $placeName)
                        .font(.system(size: 14))
                    Text(coordinateCaption)
                        .font(.system(size: 10.5))
                        .foregroundStyle(Color.inkSoft)
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.field))
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            labelRow("テキスト", required: true)
            TextField("ここで感じたことを書く", text: $note, axis: .vertical)
                .font(.system(size: 13))
                .lineSpacing(4)
                .frame(minHeight: 76, alignment: .topLeading)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.field))
        }
    }

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            labelRow("評価", required: true)
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { value in
                    Image(systemName: value <= rating ? "star.fill" : "star")
                        .font(.system(size: 22))
                        .foregroundStyle(value <= rating ? Color.moss : Color.lock)
                        .onTapGesture { rating = value }
                }
            }
        }
    }

    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            labelRow("タグ", required: false)
            HStack(spacing: 7) {
                ForEach(tagOptions, id: \.self) { tag in
                    let isOn = tags.contains(tag)
                    Text(tag)
                        .font(.system(size: 12, weight: isOn ? .bold : .regular))
                        .foregroundStyle(isOn ? Color.mossDeep : Color.inkSoft)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background {
                            Capsule()
                                .fill(isOn ? Color.mossTint : Color.clear)
                                .overlay(Capsule().stroke(isOn ? Color.clear : Color.hairline, lineWidth: 1))
                        }
                        .onTapGesture {
                            if isOn { tags.remove(tag) } else { tags.insert(tag) }
                        }
                }
            }
        }
    }

    private var visibilitySection: some View {
        VStack(alignment: .leading, spacing: 9) {
            labelRow("公開範囲", required: false)
            Picker("公開範囲", selection: $visibility) {
                ForEach(Visibility.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var warningCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.warnInk)
            VStack(alignment: .leading, spacing: 6) {
                Text("正確な位置が誰にでも表示されます。自宅や職場の近くではないか確認してください。")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.warnInk)
                Button("公開範囲を見直す") { visibility = .followers }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.warnInk)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.warnBackground)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.warnLine, lineWidth: 1))
        }
    }

    private var lockToggle: some View {
        Toggle(isOn: $readableAnywhere) {
            VStack(alignment: .leading, spacing: 3) {
                Text("現地に行かなくても読めるようにする")
                    .font(.system(size: 13))
                Text("OFFのままなら、現地に来た人だけが読めます")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkSoft)
            }
        }
        .tint(Color.moss)
    }

    private var submitBar: some View {
        Button {
            submit()
        } label: {
            Label("しおりを挟む", systemImage: "bookmark.fill")
                .font(.system(size: 15, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.roundedRectangle(radius: 16))
        .tint(Color.mossDeep)
        .disabled(!canSubmit)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private var coordinateCaption: String {
        guard let coordinate else { return "位置情報を取得中…" }
        return String(format: "現在地を自動取得 · %.4f, %.4f", coordinate.latitude, coordinate.longitude)
    }

    private func labelRow(_ title: String, required: Bool) -> some View {
        HStack(spacing: 6) {
            Text(title).sectionLabel()
            if required {
                Text("必須")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.moss)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.moss, lineWidth: 1))
            }
        }
    }

    private func submit() {
        let coordinate = coordinate ?? .inokashira
        let bookmark =
            Bookmark(
                placeName: placeName,
                note: note,
                rating: rating,
                tags: Array(tags),
                author: "you",
                postedAt: .now,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                visibility: visibility,
                requiresVisit: !readableAnywhere,
                openedAt: .now,
                photo: .pond,
                photoFiles: photoFiles
            )

        store.add(bookmark)
        Task { await cloud.push(bookmark) }
        dismiss()
    }
}

extension CLLocationCoordinate2D {
    static let inokashira = CLLocationCoordinate2D(latitude: 35.7006, longitude: 139.5803)
}

#Preview {
    ComposeScreen(coordinate: CLLocationCoordinate2D(latitude: 35.7006, longitude: 139.5803))
        .environment(BookmarkStore())
}
