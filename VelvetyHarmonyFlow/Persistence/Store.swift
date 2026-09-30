import Foundation
import Combine
import CoreSpotlight
import UniformTypeIdentifiers
import UserNotifications

final class Store: ObservableObject {
    @Published var notes: [DayNote] = []
    @Published var tutorialCompleted: Bool = false
    @Published var ledgerSort: LedgerSort = .newest
    @Published var eveningPromptEnabled: Bool = false
    @Published var didInstallDemo: Bool = false
    @Published var undoTitle: String?

    private let defaults: UserDefaults
    private let snapshotKey = "quietledger.snapshot.v1"
    private let spotlightDomain = "quietledger.notes"
    private var pendingUndo: PendingUndo?
    private var undoExpiry: DispatchWorkItem?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
        if !didInstallDemo && notes.isEmpty && !tutorialCompleted {
            installDemoContent()
        }
        refreshEveningPrompts()
        indexSpotlight()
    }

    func addNote(_ note: DayNote) {
        notes.insert(note, at: 0)
        save()
    }

    func updateNote(_ note: DayNote) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index] = note
        save()
    }

    func deleteNote(id: UUID) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        let note = notes[index]
        stashUndo(note, index: index, title: "Note removed")
        notes.remove(at: index)
        save()
    }

    func togglePin(_ id: UUID) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[index].pinned.toggle()
        save()
    }

    func isPinned(_ id: UUID) -> Bool {
        notes.first(where: { $0.id == id })?.pinned ?? false
    }

    func undoLast() {
        guard let pendingUndo else { return }
        undoExpiry?.cancel()
        self.pendingUndo = nil
        undoTitle = nil
        let clamped = min(max(pendingUndo.index, 0), notes.count)
        notes.insert(pendingUndo.note, at: clamped)
        save()
    }

    func note(for id: UUID) -> DayNote? {
        notes.first { $0.id == id }
    }

    func notes(on day: Date) -> [DayNote] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: day)
        return notes
            .filter { calendar.isDate($0.createdAt, inSameDayAs: start) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func notes(of kind: NoteKind) -> [DayNote] {
        notes.filter { $0.kindValue == kind }
    }

    func todayIntention() -> DayNote? {
        notes(on: Date()).first { $0.kindValue == .intention }
    }

    func todayWins() -> [DayNote] {
        notes(on: Date()).filter { $0.kindValue == .win }
    }

    func setLedgerSort(_ sort: LedgerSort) {
        ledgerSort = sort
        save()
    }

    func setEveningPrompt(_ enabled: Bool) {
        eveningPromptEnabled = enabled
        save()
        if enabled {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in
                DispatchQueue.main.async {
                    self.refreshEveningPrompts()
                }
            }
        } else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: Self.promptIdentifiers)
        }
    }

    func completeTutorial() {
        tutorialCompleted = true
        save()
    }

    func installDemoContent() {
        notes = DemoCatalog.notes()
        didInstallDemo = true
        save()
    }

    func clearDemoAndStartFresh() {
        notes = []
        didInstallDemo = true
        tutorialCompleted = true
        save()
        indexSpotlight()
    }

    func count(for kind: NoteKind) -> Int {
        notes.filter { $0.kindValue == kind }.count
    }

    func captureStreak() -> Int {
        let calendar = Calendar.current
        let days = Set(notes.map { calendar.startOfDay(for: $0.createdAt) })
        guard !days.isEmpty else { return 0 }
        var cursor = calendar.startOfDay(for: Date())
        if !days.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }
        var streak = 0
        while days.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    func notesByDay(last days: Int) -> [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var buckets: [Date: Int] = [:]
        for offset in 0..<days {
            if let day = calendar.date(byAdding: .day, value: -offset, to: today) {
                buckets[day] = 0
            }
        }
        for note in notes {
            let day = calendar.startOfDay(for: note.createdAt)
            if buckets[day] != nil {
                buckets[day, default: 0] += 1
            }
        }
        return buckets.keys.sorted().map { (date: $0, count: buckets[$0] ?? 0) }
    }

    func pinnedNotes() -> [DayNote] {
        notes.filter(\.pinned).sorted { $0.createdAt > $1.createdAt }
    }

    func refreshEveningPrompts() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: Self.promptIdentifiers)
        guard eveningPromptEnabled else { return }
        let calendar = Calendar.current
        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: Date()) else { continue }
            let content = UNMutableNotificationContent()
            content.title = "Evening review"
            content.body = DailyPrompt.phrase(for: day)
            content.sound = .default
            var components = calendar.dateComponents([.year, .month, .day], from: day)
            components.hour = 20
            components.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: Self.promptIdentifiers[offset],
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    func resetAll() {
        notes = []
        tutorialCompleted = false
        ledgerSort = .newest
        eveningPromptEnabled = false
        didInstallDemo = false
        pendingUndo = nil
        undoTitle = nil
        undoExpiry?.cancel()
        save()
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: Self.promptIdentifiers)
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [spotlightDomain])
        NotificationCenter.default.post(name: Notification.Name("dataReset"), object: nil)
    }

    private struct PendingUndo {
        let note: DayNote
        let index: Int
    }

    private func stashUndo(_ note: DayNote, index: Int, title: String) {
        pendingUndo = PendingUndo(note: note, index: index)
        undoTitle = title
        undoExpiry?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.pendingUndo = nil
            self?.undoTitle = nil
        }
        undoExpiry = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 6, execute: work)
    }

    private struct Snapshot: Codable {
        var notes: [DayNote]
        var tutorialCompleted: Bool
        var ledgerSort: String?
        var eveningPromptEnabled: Bool?
        var didInstallDemo: Bool?
    }

    private func load() {
        guard let data = defaults.data(forKey: snapshotKey) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let snapshot = try? decoder.decode(Snapshot.self, from: data) else { return }
        notes = snapshot.notes
        tutorialCompleted = snapshot.tutorialCompleted
        ledgerSort = LedgerSort(rawValue: snapshot.ledgerSort ?? "") ?? .newest
        eveningPromptEnabled = snapshot.eveningPromptEnabled ?? false
        didInstallDemo = snapshot.didInstallDemo ?? false
    }

    private func save() {
        let snapshot = Snapshot(
            notes: notes,
            tutorialCompleted: tutorialCompleted,
            ledgerSort: ledgerSort.rawValue,
            eveningPromptEnabled: eveningPromptEnabled,
            didInstallDemo: didInstallDemo
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: snapshotKey)
        indexSpotlight()
    }

    private func indexSpotlight() {
        let snapshot = notes
        let domain = spotlightDomain
        let index = CSSearchableIndex.default()
        index.deleteSearchableItems(withDomainIdentifiers: [domain]) { _ in
            let items: [CSSearchableItem] = snapshot.map { note in
                let attributes = CSSearchableItemAttributeSet(contentType: .plainText)
                attributes.title = note.title
                attributes.contentDescription = [note.kind, note.body]
                    .filter { !$0.isEmpty }
                    .joined(separator: " · ")
                attributes.keywords = [note.kind, "ledger", "win", "review"]
                return CSSearchableItem(
                    uniqueIdentifier: note.id.uuidString,
                    domainIdentifier: domain,
                    attributeSet: attributes
                )
            }
            index.indexSearchableItems(items)
        }
    }

    private static let promptIdentifiers = (0..<7).map { "quietledger.prompt.\($0)" }
}
