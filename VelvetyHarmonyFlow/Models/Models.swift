import Foundation

enum NoteKind: String, Codable, CaseIterable, Identifiable, Hashable {
    case intention = "Intention"
    case win = "Win"
    case friction = "Friction"
    case gratitude = "Gratitude"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .intention: return "sunrise.fill"
        case .win: return "checkmark.seal.fill"
        case .friction: return "cloud.bolt.fill"
        case .gratitude: return "heart.fill"
        }
    }

    var hint: String {
        switch self {
        case .intention: return "One focus for the day ahead"
        case .win: return "Something that went right"
        case .friction: return "A snag worth naming, not fixing yet"
        case .gratitude: return "A person, place, or moment you keep"
        }
    }

    static func matching(_ name: String) -> NoteKind {
        NoteKind(rawValue: name) ?? .win
    }
}

struct DayNote: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var kind: String
    var title: String
    var body: String
    var createdAt: Date
    var pinned: Bool

    init(
        id: UUID = UUID(),
        kind: NoteKind,
        title: String,
        body: String,
        createdAt: Date = Date(),
        pinned: Bool = false
    ) {
        self.id = id
        self.kind = kind.rawValue
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.pinned = pinned
    }

    var kindValue: NoteKind {
        NoteKind.matching(kind)
    }
}

enum LedgerSort: String, CaseIterable, Identifiable {
    case newest
    case oldest
    case kind

    var id: String { rawValue }

    var label: String {
        switch self {
        case .newest: return "Newest"
        case .oldest: return "Oldest"
        case .kind: return "Type"
        }
    }
}

enum DailyPrompt {
    static let lines = [
        "What is one win you can claim before sleep?",
        "What intention would make tomorrow feel lighter?",
        "Where did friction show up — and what did it teach?",
        "Who or what earned a quiet thank-you today?",
        "What progress was small but real?",
        "What would you keep from today if you could save only one line?",
        "What drained you, and what restored you?",
        "Which unfinished thing can wait without guilt?",
        "What surprised you in a good way?",
        "If tonight had a headline, what would it be?"
    ]

    static func phrase(for date: Date = Date()) -> String {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        let count = lines.count
        if count == 0 {
            return "What mattered in this day?"
        }
        return lines[abs(day) % count]
    }
}

enum NoteDate {
    static let medium: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let dayHeading: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }()

    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

enum DemoCatalog {
    static func notes(relativeTo now: Date = Date()) -> [DayNote] {
        let calendar = Calendar.current
        func day(_ offset: Int, hour: Int, minute: Int) -> Date {
            let base = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now)) ?? now
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
        }

        return [
            DayNote(
                kind: .intention,
                title: "Protect the morning hour",
                body: "No inbox before coffee. One focused block on the hardest task.",
                createdAt: day(0, hour: 7, minute: 40),
                pinned: true
            ),
            DayNote(
                kind: .win,
                title: "Shipped the tricky draft",
                body: "Sent the outline after two stalled days. Imperfect, but moving.",
                createdAt: day(0, hour: 16, minute: 20)
            ),
            DayNote(
                kind: .gratitude,
                title: "Quiet walk after lunch",
                body: "Ten minutes outside reset the afternoon better than another coffee.",
                createdAt: day(-1, hour: 13, minute: 15)
            ),
            DayNote(
                kind: .friction,
                title: "Context switching tax",
                body: "Too many half-open tabs. Tomorrow: one thread at a time until noon.",
                createdAt: day(-1, hour: 21, minute: 5)
            ),
            DayNote(
                kind: .win,
                title: "Called a friend back",
                body: "Short call, real catch-up. Felt more human than scrolling.",
                createdAt: day(-2, hour: 19, minute: 40),
                pinned: true
            ),
            DayNote(
                kind: .intention,
                title: "Leave work at the door",
                body: "Close the laptop by 19:00. Evening is for rest, not catch-up.",
                createdAt: day(-2, hour: 8, minute: 10)
            ),
            DayNote(
                kind: .gratitude,
                title: "Kitchen playlist",
                body: "Cooking with music made a plain Tuesday feel like a small ceremony.",
                createdAt: day(-3, hour: 18, minute: 50)
            )
        ]
    }
}
