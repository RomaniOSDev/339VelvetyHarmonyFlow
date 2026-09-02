import SwiftUI

struct GalleryStage: View {
    @EnvironmentObject private var store: Store
    @State private var wandering: EmotionEntry?

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                galleryHeading
                    .padding(.horizontal, 16)

                if store.entries.isEmpty {
                    VelvetEmptyState(
                        title: "No Collections Yet",
                        systemImage: "camera"
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            suggestionStrip
                            moodGrid
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 28)
                    }
                }
            }
            .velvetCanvas()
            .toolbar(.hidden, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(for: Mood.self) { mood in
                MoodCollectionView(mood: mood)
                    .environmentObject(store)
            }
            .sheet(item: $wandering) { entry in
                WanderSheet(seed: entry)
                    .environmentObject(store)
            }
        }
    }

    private var galleryHeading: some View {
        HStack(spacing: 10) {
            Text("Emotion Gallery")
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundColor(Palette.primary)
            Spacer()
            if store.entries.contains(where: { !$0.isSealed }) {
                Button {
                    wandering = store.wander()
                } label: {
                    Image(systemName: "shuffle")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundColor(Palette.primary)
                        .shadow(color: Palette.primary.opacity(0.35), radius: 6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Wander a polaroid")
            }
        }
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var suggestionStrip: some View {
        let suggestions = store.suggestedMoods()
        if !suggestions.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Suggested for you")
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundColor(Palette.accent)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(suggestions) { mood in
                            NavigationLink(value: mood) {
                                Text("\(mood.emoji)  \(mood.rawValue)")
                                    .font(.system(size: 13, weight: .semibold, design: .serif))
                                    .foregroundColor(Palette.background)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(Palette.primary))
                                    .shadow(color: Palette.primary.opacity(0.35), radius: 6, y: 2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var moodGrid: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(displayMoods) { mood in
                ZStack(alignment: .topTrailing) {
                    NavigationLink(value: mood) {
                        MoodTile(mood: mood, count: store.entries(for: mood).count)
                    }
                    .buttonStyle(.plain)

                    Button {
                        store.toggleFavourite(mood.rawValue)
                    } label: {
                        Image(systemName: store.isFavourited(mood.rawValue) ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Palette.primary)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Palette.background.opacity(0.55))
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                    .accessibilityLabel(store.isFavourited(mood.rawValue) ? "Remove favourite" : "Favourite mood")
                }
            }
        }
    }

    private var displayMoods: [Mood] {
        let grouped = store.moodsWithEntries()
        let favourites = Mood.allCases.filter { store.isFavourited($0.rawValue) }
        var seen = Set<Mood>()
        var result: [Mood] = []
        for mood in favourites + grouped {
            if seen.insert(mood).inserted {
                result.append(mood)
            }
        }
        return result
    }
}

struct MoodTile: View {
    let mood: Mood
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(mood.posterName)
                .resizable()
                .scaledToFill()
                .frame(height: 96)
                .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text("\(mood.emoji)  \(mood.rawValue)")
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .foregroundColor(Palette.primary)
                    .lineLimit(1)
                Text(count == 1 ? "1 polaroid" : "\(count) polaroids")
                    .font(.system(size: 11, design: .serif))
                    .foregroundColor(Palette.accent)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Palette.accent, lineWidth: 1.5)
                .shadow(color: Palette.primary.opacity(0.75), radius: 8)
        )
        .shadow(color: Palette.background.opacity(0.4), radius: 8, y: 4)
    }
}

struct MoodCollectionView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss
    let mood: Mood

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Palette.primary)
                }
                .buttonStyle(.plain)

                Text("\(mood.emoji)  \(mood.rawValue)")
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundColor(Palette.primary)

                Spacer()

                Button {
                    store.toggleFavourite(mood.rawValue)
                } label: {
                    Image(systemName: store.isFavourited(mood.rawValue) ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(Palette.primary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 10)

            let items = store.entries(for: mood)
            if items.isEmpty {
                VelvetEmptyState(
                    title: "No Collections Yet",
                    systemImage: "camera"
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 22) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, entry in
                            PolaroidCard(
                                entry: entry,
                                handwritten: store.latestCaption(for: entry.id)?.captionText ?? entry.description,
                                loved: store.isLoved(entry.id)
                            )
                            .offset(y: index % 2 == 0 ? 0 : 12)
                            .contextMenu {
                                Button(store.isLoved(entry.id) ? "Remove from kept" : "Keep this polaroid") {
                                    store.toggleLoved(entry.id)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
            }
        }
        .velvetCanvas()
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }
}

struct WanderSheet: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var entry: EmotionEntry

    init(seed: EmotionEntry) {
        _entry = State(initialValue: seed)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("A polaroid from the wall")
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundColor(Palette.primary)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Palette.primary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 8)

            Spacer(minLength: 12)

            PolaroidCard(
                entry: entry,
                handwritten: store.latestCaption(for: entry.id)?.captionText ?? entry.description,
                loved: store.isLoved(entry.id)
            )
            .padding(.horizontal, 36)

            Spacer(minLength: 12)

            Button {
                if let next = store.wander(awayFrom: entry.id) {
                    entry = next
                }
            } label: {
                Text("Another")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundColor(Palette.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Palette.primary))
                    .shadow(color: Palette.primary.opacity(0.4), radius: 8, y: 3)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .velvetCanvas()
        .darkroomVeil(store.darkroomEnabled)
    }
}
