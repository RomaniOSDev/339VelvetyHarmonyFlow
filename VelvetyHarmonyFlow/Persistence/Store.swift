import Foundation
import Combine
import CoreSpotlight
import UniformTypeIdentifiers
import UserNotifications

final class Store: ObservableObject {
    @Published var entries: [EmotionEntry] = []
    @Published var captions: [EmotiveCaption] = []
    @Published var favouritedEmotions: [String] = []
    @Published var preferredMoodSet: [String] = []
    @Published var tutorialCompleted: Bool = false
    @Published var favouritedEntryIds: [String] = []
    @Published var darkroomEnabled: Bool = false
    @Published var wallSort: WallSort = .newest
    @Published var eveningPromptEnabled: Bool = false
    @Published var undoTitle: String?

    private let defaults: UserDefaults
    private let snapshotKey = "vhf.snapshot.v1"
    private let spotlightDomain = "vhf.polaroids"
    private var pendingUndo: PendingUndo?
    private var undoExpiry: DispatchWorkItem?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
        refreshEveningPrompts()
        indexSpotlight()
    }

    func addEntry(_ entry: EmotionEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func updateEntry(_ entry: EmotionEntry) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[index] = entry
        save()
    }

    func deleteEntry(id: UUID) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        let entry = entries[index]
        let related = captions.filter { $0.photoId == id }
        stashUndo(
            .entry(entry, captions: related, index: index),
            title: "Polaroid put away"
        )
        entries.remove(at: index)
        captions.removeAll { $0.photoId == id }
        favouritedEntryIds.removeAll { $0 == id.uuidString }
        save()
    }

    func addCaption(_ caption: EmotiveCaption) {
        captions.insert(caption, at: 0)
        save()
    }

    func updateCaption(_ caption: EmotiveCaption) {
        guard let index = captions.firstIndex(where: { $0.id == caption.id }) else { return }
        captions[index] = caption
        save()
    }

    func deleteCaption(id: UUID) {
        guard let index = captions.firstIndex(where: { $0.id == id }) else { return }
        let caption = captions[index]
        stashUndo(.caption(caption, index: index), title: "Caption put away")
        captions.remove(at: index)
        save()
    }

    func undoLast() {
        guard let pendingUndo else { return }
        undoExpiry?.cancel()
        self.pendingUndo = nil
        undoTitle = nil
        switch pendingUndo {
        case .entry(let entry, let related, let index):
            let clamped = min(max(index, 0), entries.count)
            entries.insert(entry, at: clamped)
            captions.append(contentsOf: related)
            captions.sort { $0.creationDate > $1.creationDate }
        case .caption(let caption, let index):
            let clamped = min(max(index, 0), captions.count)
            captions.insert(caption, at: clamped)
        }
        save()
    }

    func captions(for photoId: UUID) -> [EmotiveCaption] {
        captions
            .filter { $0.photoId == photoId }
            .sorted { $0.creationDate > $1.creationDate }
    }

    func latestCaption(for photoId: UUID) -> EmotiveCaption? {
        captions(for: photoId).first
    }

    func entry(for photoId: UUID) -> EmotionEntry? {
        entries.first { $0.id == photoId }
    }

    func entries(for mood: Mood) -> [EmotionEntry] {
        entries.filter { $0.mood == mood.rawValue }
    }

    func toggleFavourite(_ moodName: String) {
        if let index = favouritedEmotions.firstIndex(of: moodName) {
            favouritedEmotions.remove(at: index)
        } else {
            favouritedEmotions.append(moodName)
            if !preferredMoodSet.contains(moodName) {
                preferredMoodSet.append(moodName)
            }
        }
        save()
    }

    func isFavourited(_ moodName: String) -> Bool {
        favouritedEmotions.contains(moodName)
    }

    func toggleLoved(_ entryId: UUID) {
        let key = entryId.uuidString
        if let index = favouritedEntryIds.firstIndex(of: key) {
            favouritedEntryIds.remove(at: index)
        } else {
            favouritedEntryIds.append(key)
        }
        save()
    }

    func isLoved(_ entryId: UUID) -> Bool {
        favouritedEntryIds.contains(entryId.uuidString)
    }

    func togglePreferred(_ moodName: String) {
        if let index = preferredMoodSet.firstIndex(of: moodName) {
            preferredMoodSet.remove(at: index)
        } else {
            preferredMoodSet.append(moodName)
        }
        save()
    }

    func isPreferred(_ moodName: String) -> Bool {
        preferredMoodSet.contains(moodName)
    }

    func setWallSort(_ sort: WallSort) {
        wallSort = sort
        save()
    }

    func toggleDarkroom() {
        darkroomEnabled.toggle()
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

    func suggestedMoods(limit: Int = 3) -> [Mood] {
        var counts: [String: Int] = [:]
        for entry in entries {
            counts[entry.mood, default: 0] += 1
        }
        let preferred = preferredMoodSet
        let ranked = Mood.allCases.sorted { lhs, rhs in
            let leftPreferred = preferred.contains(lhs.rawValue)
            let rightPreferred = preferred.contains(rhs.rawValue)
            if leftPreferred != rightPreferred {
                return leftPreferred && !rightPreferred
            }
            let leftCount = counts[lhs.rawValue] ?? 0
            let rightCount = counts[rhs.rawValue] ?? 0
            if leftCount != rightCount {
                return leftCount > rightCount
            }
            return lhs.rawValue < rhs.rawValue
        }
        let usable = ranked.filter { mood in
            (counts[mood.rawValue] ?? 0) > 0
        }
        return Array(usable.prefix(limit))
    }

    func moodsWithEntries() -> [Mood] {
        let names = Set(entries.map(\.mood))
        return Mood.allCases.filter { names.contains($0.rawValue) }
    }

    func polaroidCount(for mood: Mood) -> Int {
        entries.filter { $0.mood == mood.rawValue }.count
    }

    func captureStreak() -> Int {
        let calendar = Calendar.current
        let days = Set(entries.map { calendar.startOfDay(for: $0.createdAt) })
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

    func polaroidsByDay(last days: Int) -> [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var buckets: [Date: Int] = [:]
        for offset in 0..<days {
            if let day = calendar.date(byAdding: .day, value: -offset, to: today) {
                buckets[day] = 0
            }
        }
        for entry in entries {
            let day = calendar.startOfDay(for: entry.createdAt)
            if buckets[day] != nil {
                buckets[day, default: 0] += 1
            }
        }
        return buckets.keys.sorted().map { (date: $0, count: buckets[$0] ?? 0) }
    }

    func wander(awayFrom current: UUID? = nil) -> EmotionEntry? {
        let open = entries.filter { !$0.isSealed }
        let pool = open.filter { $0.id != current }
        if pool.isEmpty {
            return open.randomElement()
        }
        return pool.randomElement()
    }

    func refreshEveningPrompts() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: Self.promptIdentifiers)
        guard eveningPromptEnabled else { return }
        let calendar = Calendar.current
        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: Date()) else { continue }
            let content = UNMutableNotificationContent()
            content.title = "A line for dusk"
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
        entries = []
        captions = []
        favouritedEmotions = []
        preferredMoodSet = []
        tutorialCompleted = false
        favouritedEntryIds = []
        darkroomEnabled = false
        wallSort = .newest
        eveningPromptEnabled = false
        pendingUndo = nil
        undoTitle = nil
        undoExpiry?.cancel()
        save()
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: Self.promptIdentifiers)
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [spotlightDomain])
        NotificationCenter.default.post(name: Notification.Name("dataReset"), object: nil)
    }

    private enum PendingUndo {
        case entry(EmotionEntry, captions: [EmotiveCaption], index: Int)
        case caption(EmotiveCaption, index: Int)
    }

    private func stashUndo(_ undo: PendingUndo, title: String) {
        pendingUndo = undo
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
        var entries: [EmotionEntry]
        var captions: [EmotiveCaption]
        var favouritedEmotions: [String]
        var preferredMoodSet: [String]
        var tutorialCompleted: Bool
        var favouritedEntryIds: [String]?
        var darkroomEnabled: Bool?
        var wallSort: String?
        var eveningPromptEnabled: Bool?
    }

    private func load() {
        guard let data = defaults.data(forKey: snapshotKey) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let snapshot = try? decoder.decode(Snapshot.self, from: data) else { return }
        entries = snapshot.entries
        captions = snapshot.captions
        favouritedEmotions = snapshot.favouritedEmotions
        preferredMoodSet = snapshot.preferredMoodSet
        tutorialCompleted = snapshot.tutorialCompleted
        favouritedEntryIds = snapshot.favouritedEntryIds ?? []
        darkroomEnabled = snapshot.darkroomEnabled ?? false
        wallSort = WallSort(rawValue: snapshot.wallSort ?? "") ?? .newest
        eveningPromptEnabled = snapshot.eveningPromptEnabled ?? false
    }

    private func save() {
        let snapshot = Snapshot(
            entries: entries,
            captions: captions,
            favouritedEmotions: favouritedEmotions,
            preferredMoodSet: preferredMoodSet,
            tutorialCompleted: tutorialCompleted,
            favouritedEntryIds: favouritedEntryIds,
            darkroomEnabled: darkroomEnabled,
            wallSort: wallSort.rawValue,
            eveningPromptEnabled: eveningPromptEnabled
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: snapshotKey)
        indexSpotlight()
    }

    private func indexSpotlight() {
        let snapshot = entries
        let domain = spotlightDomain
        let index = CSSearchableIndex.default()
        index.deleteSearchableItems(withDomainIdentifiers: [domain]) { _ in
            let items: [CSSearchableItem] = snapshot.map { entry in
                let attributes = CSSearchableItemAttributeSet(contentType: .plainText)
                attributes.title = entry.title
                if entry.isSealed, let sealedUntil = entry.sealedUntil {
                    attributes.contentDescription = "Sealed until \(SealDate.medium.string(from: sealedUntil))"
                } else {
                    attributes.contentDescription = [entry.mood, entry.description]
                        .filter { !$0.isEmpty }
                        .joined(separator: " · ")
                }
                attributes.keywords = [entry.mood, entry.moodEmoji, "polaroid", "velvet"]
                return CSSearchableItem(
                    uniqueIdentifier: entry.id.uuidString,
                    domainIdentifier: domain,
                    attributeSet: attributes
                )
            }
            index.indexSearchableItems(items)
        }
    }

    private static let promptIdentifiers = (0..<7).map { "vhf.prompt.\($0)" }
}
