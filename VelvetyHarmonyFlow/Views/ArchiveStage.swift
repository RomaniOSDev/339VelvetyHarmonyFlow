import SwiftUI

struct ArchiveStage: View {
    @EnvironmentObject private var store: Store
    @State private var composer: EntryComposerState?
    @State private var pendingDelete: EmotionEntry?
    @State private var query = ""
    @State private var moodFilter: Mood?
    @State private var lovedOnly = false
    @State private var compareMode = false
    @State private var comparePicks: [UUID] = []
    @State private var comparePair: ComparePair?
    @State private var sealedNotice: EmotionEntry?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            archiveHeading
                .padding(.horizontal, 16)

            if store.entries.isEmpty {
                VelvetEmptyState(
                    title: "Capture your emotions now!",
                    systemImage: "plus.circle.fill",
                    subtitle: DailyPrompt.phrase()
                ) {
                    composer = .create
                }
            } else {
                promptRibbon
                searchRibbon
                if visibleEntries.isEmpty {
                    VelvetEmptyState(
                        title: "No polaroids in this light",
                        systemImage: "magnifyingglass"
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 22) {
                            ForEach(Array(visibleEntries.enumerated()), id: \.element.id) { index, entry in
                                Button {
                                    handleTap(entry)
                                } label: {
                                    PolaroidCard(
                                        entry: entry,
                                        handwritten: handwrittenLine(for: entry),
                                        loved: store.isLoved(entry.id)
                                    )
                                    .offset(y: index % 2 == 0 ? 0 : 14)
                                    .overlay {
                                        if comparePicks.contains(entry.id) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(Palette.primary, lineWidth: 3)
                                                .padding(2)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    if !entry.isSealed {
                                        Button("Edit") {
                                            composer = .edit(entry)
                                        }
                                    }
                                    Button(store.isLoved(entry.id) ? "Remove from kept" : "Keep this polaroid") {
                                        store.toggleLoved(entry.id)
                                    }
                                    if store.entries.count >= 2 {
                                        Button("Compare") {
                                            beginCompare(with: entry)
                                        }
                                    }
                                    Button("Delete", role: .destructive) {
                                        pendingDelete = entry
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 28)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
        }
        .dismissKeyboardOnTap()
        .sheet(item: $composer) { state in
            EntryComposerView(state: state)
                .environmentObject(store)
        }
        .sheet(item: $comparePair) { pair in
            CompareSheet(left: pair.left, right: pair.right)
                .environmentObject(store)
        }
        .confirmationDialog("Remove this polaroid from the wall?", isPresented: deleteDialogBinding, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let entry = pendingDelete {
                    store.deleteEntry(id: entry.id)
                }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) {
                pendingDelete = nil
            }
        }
        .alert("Still in the darkroom", isPresented: sealedAlertBinding) {
            Button("OK", role: .cancel) {
                sealedNotice = nil
            }
        } message: {
            if let sealedNotice, let until = sealedNotice.sealedUntil {
                Text("This polaroid opens on \(SealDate.medium.string(from: until)).")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("openPolaroid"))) { note in
            guard let id = note.object as? UUID, let entry = store.entry(for: id) else { return }
            if entry.isSealed {
                sealedNotice = entry
            } else {
                composer = .edit(entry)
            }
        }
    }

    private var archiveHeading: some View {
        HStack(spacing: 10) {
            Text(compareMode ? "Pick two" : "Emotion Archive")
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundColor(Palette.primary)
            Spacer()
            if compareMode {
                Button {
                    compareMode = false
                    comparePicks = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 26, weight: .regular))
                        .foregroundColor(Palette.primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cancel compare")
            } else {
                if store.entries.count >= 2 {
                    Button {
                        compareMode = true
                        comparePicks = []
                    } label: {
                        Image(systemName: "square.split.2x1")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundColor(Palette.primary)
                            .shadow(color: Palette.primary.opacity(0.35), radius: 6)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Compare polaroids")
                }
                Button {
                    composer = .create
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 26, weight: .regular))
                        .foregroundColor(Palette.primary)
                        .shadow(color: Palette.primary.opacity(0.35), radius: 6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("New polaroid")
            }
        }
        .padding(.bottom, 8)
    }

    private var promptRibbon: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "quote.opening")
                .foregroundColor(Palette.accent)
            Text(DailyPrompt.phrase())
                .font(.system(size: 13, design: .serif))
                .italic()
                .foregroundColor(Palette.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface.opacity(0.85))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Palette.primary.opacity(0.28), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var searchRibbon: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Palette.accent)
                VelvetPromptField(placeholder: "Search titles, notes, moods", text: $query)
            }
            .padding(12)
            .background(Palette.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Palette.primary.opacity(0.35), lineWidth: 1)
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    VelvetFilterChip(title: "All", selected: moodFilter == nil && !lovedOnly) {
                        moodFilter = nil
                        lovedOnly = false
                    }
                    VelvetFilterChip(title: "Kept", selected: lovedOnly) {
                        lovedOnly.toggle()
                    }
                    ForEach(Mood.allCases) { mood in
                        MoodChip(mood: mood, selected: moodFilter == mood) {
                            moodFilter = moodFilter == mood ? nil : mood
                        }
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(WallSort.allCases) { sort in
                        VelvetFilterChip(title: sort.label, selected: store.wallSort == sort) {
                            store.setWallSort(sort)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var deleteDialogBinding: Binding<Bool> {
        Binding(
            get: { pendingDelete != nil },
            set: { presented in
                if !presented {
                    pendingDelete = nil
                }
            }
        )
    }

    private var sealedAlertBinding: Binding<Bool> {
        Binding(
            get: { sealedNotice != nil },
            set: { presented in
                if !presented {
                    sealedNotice = nil
                }
            }
        )
    }

    private var visibleEntries: [EmotionEntry] {
        var result = store.entries.filter { entry in
            if lovedOnly && !store.isLoved(entry.id) {
                return false
            }
            if let moodFilter, entry.mood != moodFilter.rawValue {
                return false
            }
            let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if needle.isEmpty {
                return true
            }
            if entry.isSealed {
                return entry.title.localizedCaseInsensitiveContains(needle)
                    || entry.mood.localizedCaseInsensitiveContains(needle)
            }
            return entry.title.localizedCaseInsensitiveContains(needle)
                || entry.description.localizedCaseInsensitiveContains(needle)
                || entry.mood.localizedCaseInsensitiveContains(needle)
        }
        switch store.wallSort {
        case .newest:
            result.sort { $0.createdAt > $1.createdAt }
        case .oldest:
            result.sort { $0.createdAt < $1.createdAt }
        case .mood:
            result.sort {
                if $0.mood == $1.mood {
                    return $0.createdAt > $1.createdAt
                }
                return $0.mood < $1.mood
            }
        }
        return result
    }

    private func handleTap(_ entry: EmotionEntry) {
        if compareMode {
            pickForCompare(entry)
            return
        }
        if entry.isSealed {
            sealedNotice = entry
            return
        }
        composer = .edit(entry)
    }

    private func beginCompare(with entry: EmotionEntry) {
        compareMode = true
        comparePicks = [entry.id]
    }

    private func pickForCompare(_ entry: EmotionEntry) {
        if let index = comparePicks.firstIndex(of: entry.id) {
            comparePicks.remove(at: index)
            return
        }
        comparePicks.append(entry.id)
        if comparePicks.count == 2,
           let leftId = comparePicks.first,
           let rightId = comparePicks.last,
           let left = store.entry(for: leftId),
           let right = store.entry(for: rightId) {
            comparePair = ComparePair(left: left, right: right)
            compareMode = false
            comparePicks = []
        }
    }

    private func handwrittenLine(for entry: EmotionEntry) -> String {
        if entry.isSealed {
            return ""
        }
        if let caption = store.latestCaption(for: entry.id) {
            return caption.captionText
        }
        return entry.description
    }
}

private struct ComparePair: Identifiable {
    let left: EmotionEntry
    let right: EmotionEntry
    var id: String { "\(left.id.uuidString)-\(right.id.uuidString)" }
}

struct CompareSheet: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss
    let left: EmotionEntry
    let right: EmotionEntry

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Two lights")
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

            ScrollView {
                VStack(spacing: 8) {
                    PolaroidCard(
                        entry: left,
                        handwritten: store.latestCaption(for: left.id)?.captionText ?? left.description,
                        loved: store.isLoved(left.id)
                    )
                    PolaroidCard(
                        entry: right,
                        handwritten: store.latestCaption(for: right.id)?.captionText ?? right.description,
                        loved: store.isLoved(right.id)
                    )
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            }
        }
        .velvetCanvas()
        .darkroomVeil(store.darkroomEnabled)
    }
}

enum EntryComposerState: Identifiable {
    case create
    case edit(EmotionEntry)

    var id: String {
        switch self {
        case .create:
            return "create"
        case .edit(let entry):
            return entry.id.uuidString
        }
    }
}

struct EntryComposerView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss
    let state: EntryComposerState

    @State private var titleText = ""
    @State private var descriptionText = ""
    @State private var selectedMood: Mood = .joyful
    @State private var confirmDelete = false
    @State private var showTitleAlert = false
    @State private var sealEnabled = false
    @State private var sealDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(heading)
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

            ScrollView {
                VStack(spacing: 14) {
                    Image(selectedMood.posterName)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 150)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Palette.background.opacity(0.05),
                                    Palette.primary.opacity(0.22)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Palette.primary, lineWidth: 8)
                        )
                        .shadow(color: Palette.background.opacity(0.45), radius: 8, y: 4)
                        .padding(.horizontal, 28)
                        .rotationEffect(.degrees(-1.4))

                    VelvetFieldPanel(title: "Title") {
                        VelvetPromptField(placeholder: "Name this feeling", text: $titleText)
                    }

                    VelvetFieldPanel(title: "Mood") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 108), spacing: 8)], spacing: 8) {
                            ForEach(Mood.allCases) { mood in
                                MoodChip(mood: mood, selected: selectedMood == mood) {
                                    selectedMood = mood
                                }
                            }
                        }
                    }

                    VelvetFieldPanel(title: "Note") {
                        VStack(alignment: .leading, spacing: 8) {
                            VelvetPromptEditor(
                                placeholder: DailyPrompt.phrase(),
                                text: $descriptionText
                            )
                            Button {
                                descriptionText = DailyPrompt.phrase()
                            } label: {
                                Text("Use today's line")
                                    .font(.system(size: 13, weight: .semibold, design: .serif))
                                    .foregroundColor(Palette.accent)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VelvetFieldPanel(title: "Time capsule") {
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle(isOn: $sealEnabled) {
                                Text("Seal until a later day")
                                    .font(.system(size: 15, design: .serif))
                                    .foregroundColor(Palette.primary)
                            }
                            .tint(Palette.primary)
                            if sealEnabled {
                                DatePicker(
                                    "Opens on",
                                    selection: $sealDate,
                                    in: Date()...,
                                    displayedComponents: .date
                                )
                                .font(.system(size: 15, design: .serif))
                                .foregroundColor(Palette.primary)
                                .tint(Palette.accent)
                                .colorScheme(.dark)
                            }
                        }
                    }

                    Button {
                        persist()
                    } label: {
                        Text("Save Polaroid")
                            .font(.system(size: 16, weight: .bold, design: .serif))
                            .foregroundColor(Palette.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Capsule().fill(Palette.primary))
                            .shadow(color: Palette.primary.opacity(0.4), radius: 8, y: 3)
                    }
                    .buttonStyle(.plain)

                    if case .edit = state {
                        Button {
                            confirmDelete = true
                        } label: {
                            Text("Delete Polaroid")
                                .font(.system(size: 15, weight: .medium, design: .serif))
                                .foregroundColor(Palette.accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .overlay(
                                    Capsule().stroke(Palette.accent.opacity(0.7), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .velvetCanvas()
        .dismissKeyboardOnTap()
        .darkroomVeil(store.darkroomEnabled)
        .onAppear(perform: hydrate)
        .alert("Give this polaroid a title", isPresented: $showTitleAlert) {
            Button("OK", role: .cancel) {}
        }
        .confirmationDialog("Remove this polaroid from the wall?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if case .edit(let entry) = state {
                    store.deleteEntry(id: entry.id)
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var heading: String {
        switch state {
        case .create:
            return "New Polaroid"
        case .edit:
            return "Edit Polaroid"
        }
    }

    private func hydrate() {
        if case .edit(let entry) = state {
            titleText = entry.title
            descriptionText = entry.description
            selectedMood = entry.moodKind
            if let sealedUntil = entry.sealedUntil, sealedUntil > Date() {
                sealEnabled = true
                sealDate = sealedUntil
            }
        }
    }

    private func persist() {
        let trimmed = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            showTitleAlert = true
            return
        }
        let seal = sealEnabled ? endOfDay(sealDate) : nil
        switch state {
        case .create:
            let entry = EmotionEntry(
                title: trimmed,
                mood: selectedMood,
                description: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
                sealedUntil: seal
            )
            store.addEntry(entry)
        case .edit(let existing):
            var updated = existing
            updated.title = trimmed
            updated.description = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.apply(mood: selectedMood)
            updated.sealedUntil = seal
            store.updateEntry(updated)
        }
        dismiss()
    }

    private func endOfDay(_ date: Date) -> Date {
        let start = Calendar.current.startOfDay(for: date)
        return Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? date
    }
}
