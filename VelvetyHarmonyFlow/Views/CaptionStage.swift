import SwiftUI

struct LedgerStage: View {
    @EnvironmentObject private var store: Store
    @State private var composer: NoteComposerSheet.Mode?
    @State private var pendingDelete: DayNote?
    @State private var kindFilter: NoteKind?
    @State private var query = ""
    @State private var pinnedOnly = false

    private let tabBarClearance: CGFloat = 100

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                if store.notes.isEmpty {
                    UsefulEmptyState(
                        title: "Your ledger is empty",
                        subtitle: "Log intentions, wins, friction, and gratitude. Sample notes can help you see how a week looks.",
                        systemImage: "book.closed.fill",
                        primaryTitle: "Add first note",
                        primaryAction: { composer = .create(.win) },
                        secondaryTitle: "Load sample week",
                        secondaryAction: { store.installDemoContent() }
                    )
                    .padding(.bottom, tabBarClearance)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            StageHeading(title: "Ledger", systemImage: "plus.circle.fill") {
                                composer = .create(.win)
                            }

                            searchField
                            filterRow
                            sortRow

                            if visibleNotes.isEmpty {
                                UsefulEmptyState(
                                    title: "Nothing matches",
                                    subtitle: "Try another type filter, clear search, or add a note for this filter.",
                                    systemImage: "line.3.horizontal.decrease.circle",
                                    primaryTitle: kindFilter == nil ? "Add note" : "Add \(kindFilter!.rawValue.lowercased())",
                                    primaryAction: {
                                        composer = .create(kindFilter ?? .win)
                                    },
                                    secondaryTitle: "Clear filters",
                                    secondaryAction: {
                                        kindFilter = nil
                                        query = ""
                                        pinnedOnly = false
                                    }
                                )
                                .frame(minHeight: 280)
                            } else {
                                ForEach(groupedSections, id: \.day) { section in
                                    Text(section.label)
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(Palette.accent)
                                        .padding(.top, 8)

                                    ForEach(section.notes) { note in
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
                                            Button("Delete", role: .destructive) {
                                                pendingDelete = note
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, tabBarClearance)
                    }
                    .clearScrollBackground()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Palette.primary.opacity(0.5))
            TextField("Search titles and details", text: $query)
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(Palette.primary)
                .tint(Palette.accent)
        }
        .padding(12)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", selected: kindFilter == nil && !pinnedOnly) {
                    kindFilter = nil
                    pinnedOnly = false
                }
                FilterChip(title: "Pinned", selected: pinnedOnly) {
                    pinnedOnly = true
                    kindFilter = nil
                }
                ForEach(NoteKind.allCases) { kind in
                    KindChip(kind: kind, selected: kindFilter == kind && !pinnedOnly) {
                        pinnedOnly = false
                        kindFilter = kind
                    }
                }
            }
        }
    }

    private var sortRow: some View {
        HStack(spacing: 8) {
            ForEach(LedgerSort.allCases) { sort in
                FilterChip(title: sort.label, selected: store.ledgerSort == sort) {
                    store.setLedgerSort(sort)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var visibleNotes: [DayNote] {
        var items = store.notes
        if pinnedOnly {
            items = items.filter(\.pinned)
        }
        if let kindFilter {
            items = items.filter { $0.kindValue == kindFilter }
        }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            items = items.filter {
                $0.title.localizedCaseInsensitiveContains(trimmed)
                    || $0.body.localizedCaseInsensitiveContains(trimmed)
                    || $0.kind.localizedCaseInsensitiveContains(trimmed)
            }
        }
        switch store.ledgerSort {
        case .newest:
            return items.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            return items.sorted { $0.createdAt < $1.createdAt }
        case .kind:
            return items.sorted {
                if $0.kind == $1.kind {
                    return $0.createdAt > $1.createdAt
                }
                return $0.kind < $1.kind
            }
        }
    }

    private struct DaySection {
        let day: Date
        let label: String
        let notes: [DayNote]
    }

    private var groupedSections: [DaySection] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: visibleNotes) { note in
            calendar.startOfDay(for: note.createdAt)
        }
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        return grouped.keys.sorted(by: >).map { day in
            let label: String
            if calendar.isDate(day, inSameDayAs: today) {
                label = "Today"
            } else if calendar.isDate(day, inSameDayAs: yesterday) {
                label = "Yesterday"
            } else {
                label = NoteDate.dayHeading.string(from: day)
            }
            let dayNotes = (grouped[day] ?? []).sorted { $0.createdAt > $1.createdAt }
            return DaySection(day: day, label: label, notes: dayNotes)
        }
    }
}

typealias CaptionStage = LedgerStage
