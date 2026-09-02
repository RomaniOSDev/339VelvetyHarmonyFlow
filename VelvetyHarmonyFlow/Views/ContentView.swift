import SwiftUI

enum HomeLane: String, CaseIterable, Identifiable {
    case archive = "Archive"
    case captions = "Captions"
    case gallery = "Gallery"
    case pulse = "Pulse"

    var id: String { rawValue }
}

struct ContentView: View {
    @StateObject private var store = Store()
    @State private var selectedLane: HomeLane = .archive
    @State private var showSettings = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedLane {
                case .archive:
                    ArchiveStage()
                case .captions:
                    CaptionStage()
                case .gallery:
                    GalleryStage()
                case .pulse:
                    PulseStage()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if let undoTitle = store.undoTitle {
                UndoBanner(title: undoTitle) {
                    store.undoLast()
                }
            }
            FilmStripBar(selectedLane: $selectedLane, onSettings: { showSettings = true })
        }
        .velvetCanvas()
        .environmentObject(store)
        .darkroomVeil(store.darkroomEnabled)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(store)
        }
        .overlay {
            if !store.tutorialCompleted {
                TutorialDrape()
                    .environmentObject(store)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("dataReset"))) { _ in
            selectedLane = .archive
            showSettings = false
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("openPolaroid"))) { _ in
            selectedLane = .archive
            showSettings = false
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                store.refreshEveningPrompts()
            }
        }
    }
}

struct TutorialDrape: View {
    @EnvironmentObject private var store: Store

    var body: some View {
        ZStack {
            Palette.background.opacity(0.78)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                Text("Lay feelings into dusk")
                    .font(.system(size: 26, weight: .semibold, design: .serif))
                    .foregroundColor(Palette.primary)

                Text("Tag a polaroid, write a caption, then wander the gallery. Favourite the moods that keep calling you back.")
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .foregroundColor(Palette.accent)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Moods that feel like home")
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundColor(Palette.primary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 108), spacing: 8)], spacing: 8) {
                    ForEach(Mood.allCases) { mood in
                        MoodChip(mood: mood, selected: store.isPreferred(mood.rawValue)) {
                            store.togglePreferred(mood.rawValue)
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        store.completeTutorial()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 15, weight: .medium, design: .serif))
                            .foregroundColor(Palette.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .overlay(
                                Capsule()
                                    .stroke(Palette.primary, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        store.completeTutorial()
                    } label: {
                        Text("Begin")
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(Palette.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(Palette.primary))
                            .shadow(color: Palette.primary.opacity(0.4), radius: 8, y: 3)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(22)
            .background(Palette.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Palette.primary.opacity(0.55), lineWidth: 1)
            )
            .shadow(color: Palette.background.opacity(0.6), radius: 10, y: 6)
            .padding(.horizontal, 22)
        }
    }
}
