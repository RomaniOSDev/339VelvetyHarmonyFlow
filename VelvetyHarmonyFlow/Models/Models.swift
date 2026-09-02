import Foundation

enum Mood: String, Codable, CaseIterable, Identifiable, Hashable {
    case joyful = "Joyful"
    case serene = "Serene"
    case nostalgia = "Nostalgia"
    case wonder = "Wonder"
    case tender = "Tender"
    case wild = "Wild"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .joyful:
            return "😊"
        case .serene:
            return "🌿"
        case .nostalgia:
            return "🎞️"
        case .wonder:
            return "✨"
        case .tender:
            return "💗"
        case .wild:
            return "🌪️"
        }
    }

    var posterName: String {
        let posters = ["BannerPolaroids", "BannerCamera", "BannerDusk", "BgMeadow"]
        let index = Self.allCases.firstIndex(of: self) ?? 0
        let count = posters.count
        if count == 0 {
            return "BannerPolaroids"
        }
        return posters[index % count]
    }

    static func matching(_ name: String) -> Mood {
        Mood(rawValue: name) ?? .serene
    }
}

struct EmotionEntry: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var title: String
    var mood: String
    var moodEmoji: String
    var description: String
    var imageName: String
    var createdAt: Date
    var sealedUntil: Date?

    init(
        id: UUID = UUID(),
        title: String,
        mood: Mood,
        description: String,
        createdAt: Date = Date(),
        sealedUntil: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.mood = mood.rawValue
        self.moodEmoji = mood.emoji
        self.description = description
        self.imageName = mood.posterName
        self.createdAt = createdAt
        self.sealedUntil = sealedUntil
    }

    var moodKind: Mood {
        Mood.matching(mood)
    }

    var isSealed: Bool {
        guard let sealedUntil else { return false }
        return sealedUntil > Date()
    }

    mutating func apply(mood: Mood) {
        self.mood = mood.rawValue
        moodEmoji = mood.emoji
        imageName = mood.posterName
    }
}

struct EmotiveCaption: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var photoId: UUID
    var captionText: String
    var creationDate: Date

    init(
        id: UUID = UUID(),
        photoId: UUID,
        captionText: String,
        creationDate: Date = Date()
    ) {
        self.id = id
        self.photoId = photoId
        self.captionText = captionText
        self.creationDate = creationDate
    }
}

enum WallSort: String, CaseIterable, Identifiable {
    case newest
    case oldest
    case mood

    var id: String { rawValue }

    var label: String {
        switch self {
        case .newest:
            return "New"
        case .oldest:
            return "Old"
        case .mood:
            return "Mood"
        }
    }
}

enum DailyPrompt {
    static let lines = [
        "What colour was the hour?",
        "Which feeling refused to sit still?",
        "What would you write on the back of this day?",
        "Where did the light catch you off guard?",
        "What stayed after the room went quiet?",
        "If this mood had a temperature, what is it?",
        "What did you almost say out loud?",
        "Which memory asked to be held, not solved?",
        "What are you keeping in the grain of today?",
        "If dusk could speak, what would it name?",
        "What feeling arrived without knocking?",
        "What still glows after you look away?"
    ]

    static func phrase(for date: Date = Date()) -> String {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        let count = lines.count
        if count == 0 {
            return "What lingered in this light?"
        }
        return lines[abs(day) % count]
    }
}

enum SealDate {
    static let medium: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
