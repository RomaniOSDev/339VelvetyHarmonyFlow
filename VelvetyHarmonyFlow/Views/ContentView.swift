import SwiftUI

enum HomeLane: String, CaseIterable, Identifiable {
    case today = "Today"
    case ledger = "Ledger"
    case review = "Review"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .today: return "sun.max.fill"
        case .ledger: return "list.bullet.rectangle.portrait.fill"
        case .review: return "chart.line.uptrend.xyaxis"
        }
    }
}

struct ContentView: View {
    @StateObject private var store = Store()
    @State private var selectedLane: HomeLane = .today
    @State private var showSettings = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedLane {
                case .today:
                    TodayStage()
                case .ledger:
                    LedgerStage()
                case .review:
                    ReviewStage()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)

            if let undoTitle = store.undoTitle {
                UndoBanner(title: undoTitle) {
                    store.undoLast()
                }
            }

            LaneTabBar(selectedLane: $selectedLane, onSettings: { showSettings = true })
        }
        .appCanvas()
        .environmentObject(store)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(store)
        }
        .overlay {
            if !store.tutorialCompleted {
                WelcomeOverlay()
                    .environmentObject(store)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("dataReset"))) { _ in
            selectedLane = .today
            showSettings = false
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("openNote"))) { _ in
            selectedLane = .ledger
            showSettings = false
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("goToday"))) { _ in
            selectedLane = .today
            showSettings = false
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                store.refreshEveningPrompts()
            }
        }
    }
}

struct WelcomeOverlay: View {
    @EnvironmentObject private var store: Store

    var body: some View {
        ZStack {
            Palette.background.opacity(0.88)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                Text("Quiet Ledger")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Palette.primary)

                Text("A daily ritual for intentions, wins, friction, and gratitude — not a mood gallery. Morning focus, evening review, patterns over time.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(Palette.accent)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 10) {
                    welcomeRow(symbol: "sunrise.fill", text: "Today — set intention, log wins")
                    welcomeRow(symbol: "list.bullet.rectangle.portrait.fill", text: "Ledger — browse every note by day and type")
                    welcomeRow(symbol: "chart.line.uptrend.xyaxis", text: "Review — streak, mix, and pinned notes")
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                if store.didInstallDemo && !store.notes.isEmpty {
                    Text("A sample week is already loaded so you can explore Ledger and Review immediately.")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(Palette.primary.opacity(0.75))
                }

                VStack(spacing: 10) {
                    Button {
                        store.completeTutorial()
                    } label: {
                        Text(store.notes.isEmpty ? "Begin" : "Explore with sample notes")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Palette.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Palette.primary)
                            )
                    }
                    .buttonStyle(.plain)

                    if !store.notes.isEmpty {
                        Button {
                            store.clearDemoAndStartFresh()
                        } label: {
                            Text("Clear samples and start empty")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(Palette.primary)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            store.installDemoContent()
                            store.completeTutorial()
                        } label: {
                            Text("Load sample week first")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(Palette.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(24)
            .background(Palette.surface.opacity(0.97))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Palette.primary.opacity(0.25), lineWidth: 1)
            )
            .padding(.horizontal, 22)
        }
    }

    private func welcomeRow(symbol: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Palette.primary)
                .frame(width: 22)
            Text(text)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(Palette.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
