import SwiftUI

struct TodayStage: View {
    @EnvironmentObject private var store: Store
    @State private var composer: NoteComposerSheet.Mode?
    @State private var pendingDelete: DayNote?

    private let tabBarClearance: CGFloat = 100

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        StageHeading(title: "Today")

                        promptCard
                        ritualStatus
                        intentionSection
                        winsSection
                        otherTodaySection
                        quickAddRow
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, tabBarClearance)
                }
                .clearScrollBackground()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Add intention") { composer = .create(.intention) }
                        Button("Add win") { composer = .create(.win) }
                        Button("Add friction") { composer = .create(.friction) }
                        Button("Add gratitude") { composer = .create(.gratitude) }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(Palette.primary)
                    }
                }
            }
        }
        .transparentNavigationChrome()
        .sheet(item: $composer) { mode in
            NoteComposerSheet(mode: mode)
                .environmentObject(store)
        }
        .confirmationDialog("Delete this note?", isPresented: Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let pendingDelete {
                    store.deleteNote(id: pendingDelete.id)
                }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) {
                pendingDelete = nil
            }
        }
    }

    private var todayNotes: [DayNote] {
        store.notes(on: Date())
    }

    private var promptCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("EVENING PROMPT")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Palette.accent)
            Text(DailyPrompt.phrase())
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(Palette.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Palette.primary.opacity(0.18), lineWidth: 1)
        )
    }

    private var ritualStatus: some View {
        let hasIntention = store.todayIntention() != nil
        let winCount = store.todayWins().count
        return HStack(spacing: 10) {
            statusPill(
                title: hasIntention ? "Intention set" : "Need intention",
                symbol: hasIntention ? "sunrise.fill" : "sunrise",
                filled: hasIntention
            )
            statusPill(
                title: winCount == 0 ? "No wins yet" : "\(winCount) win\(winCount == 1 ? "" : "s")",
                symbol: winCount == 0 ? "checkmark.seal" : "checkmark.seal.fill",
                filled: winCount > 0
            )
        }
    }

    private func statusPill(title: String, symbol: String, filled: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundColor(filled ? Palette.background : Palette.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(filled ? Palette.primary : Palette.surface)
        )
    }

    @ViewBuilder
    private var intentionSection: some View {
        sectionLabel("Morning intention")
        if let intention = store.todayIntention() {
            noteRow(intention)
        } else {
            miniEmpty(
                title: "Set today’s focus",
                subtitle: "One intention keeps the day from scattering.",
                actionTitle: "Write intention"
            ) {
                composer = .create(.intention)
            }
        }
    }

    @ViewBuilder
    private var winsSection: some View {
        sectionLabel("Wins so far")
        let wins = store.todayWins()
        if wins.isEmpty {
            miniEmpty(
                title: "Capture a small win",
                subtitle: "Even a tiny finish counts — it trains the evening review.",
                actionTitle: "Add a win"
            ) {
                composer = .create(.win)
            }
        } else {
            ForEach(wins) { note in
                noteRow(note)
            }
        }
    }

    @ViewBuilder
    private var otherTodaySection: some View {
        let others = todayNotes.filter { $0.kindValue != .intention && $0.kindValue != .win }
        if !others.isEmpty {
            sectionLabel("Also today")
            ForEach(others) { note in
                noteRow(note)
            }
        }
    }

    private var quickAddRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Quick add")
            HStack(spacing: 8) {
                quickButton("Friction", symbol: "cloud.bolt.fill") {
                    composer = .create(.friction)
                }
                quickButton("Gratitude", symbol: "heart.fill") {
                    composer = .create(.gratitude)
                }
            }
        }
    }

    private func quickButton(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundColor(Palette.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Palette.primary.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(Palette.accent)
            .padding(.top, 4)
    }

    private func noteRow(_ note: DayNote) -> some View {
        Button {
            composer = .edit(note)
        } label: {
            NoteCard(note: note)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(note.pinned ? "Unpin" : "Pin to Review") {
                store.togglePin(note.id)
            }
            Button("Edit") { composer = .edit(note) }
            Button("Delete", role: .destructive) { pendingDelete = note }
        }
    }

    private func miniEmpty(
        title: String,
        subtitle: String,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(Palette.primary)
            Text(subtitle)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(Palette.primary.opacity(0.7))
            Button(action: action) {
                Text(actionTitle)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Palette.background)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Palette.primary))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Palette.primary.opacity(0.15), lineWidth: 1)
        )
    }
}

// Keep old type name compiling if referenced elsewhere during migration.
typealias ArchiveStage = TodayStage
