import SwiftUI
import UIKit

enum Palette {
    static let background = Color("AppBackground")
    static let surface = Color("AppSurface")
    static let primary = Color("AppPrimary")
    static let accent = Color("AppAccent")
}

struct VelvetCanvasModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color("AppBackground")
                    .overlay {
                        Image("BgMeadow")
                            .resizable()
                            .scaledToFill()
                            .opacity(0.30)
                    }
                    .overlay {
                        LinearGradient(
                            colors: [
                                Color("AppBackground").opacity(0.28),
                                Color("AppAccent").opacity(0.14),
                                Color("AppPrimary").opacity(0.16)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                    .clipped()
                    .ignoresSafeArea()
            }
    }
}

extension View {
    func velvetCanvas() -> some View {
        modifier(VelvetCanvasModifier())
    }

    func darkroomVeil(_ enabled: Bool) -> some View {
        overlay {
            if enabled {
                Color.black.opacity(0.42)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }
}

enum PolaroidMotion {
    static func tilt(for id: UUID) -> Double {
        let seed = id.uuidString.utf8.reduce(0) { partial, unit in
            partial &+ Int(unit)
        }
        let bucket = seed % 5
        switch bucket {
        case 0:
            return -2
        case 1:
            return -1.2
        case 2:
            return 0.6
        case 3:
            return 1.4
        default:
            return 2
        }
    }
}

struct FilmStripBar: View {
    @Binding var selectedLane: HomeLane
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            sprocketColumn
            ForEach(HomeLane.allCases) { lane in
                filmFrame(title: lane.rawValue, isSelected: selectedLane == lane) {
                    selectedLane = lane
                }
            }
            filmFrame(title: "Desk", isSelected: false, action: onSettings)
                .accessibilityLabel("Settings")
            sprocketColumn
        }
        .padding(.vertical, 8)
        .background(Palette.background.opacity(0.94))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Palette.primary.opacity(0.7))
                .frame(height: 2)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Palette.primary.opacity(0.7))
                .frame(height: 2)
        }
    }

    private var sprocketColumn: some View {
        VStack(spacing: 5) {
            ForEach(0..<6, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(Palette.primary.opacity(0.38))
                    .frame(width: 9, height: 7)
            }
        }
        .padding(.horizontal, 4)
    }

    private func filmFrame(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .serif))
                .foregroundColor(isSelected ? Palette.background : Palette.primary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isSelected ? Palette.primary : Palette.surface.opacity(0.55))
                .overlay(
                    Rectangle()
                        .stroke(Palette.primary.opacity(isSelected ? 0.95 : 0.45), lineWidth: 1)
                )
                .padding(.horizontal, 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .frame(minHeight: 44)
    }
}

struct PolaroidCard: View {
    let entry: EmotionEntry
    var handwritten: String = ""
    var loved: Bool = false

    var body: some View {
        Group {
            if entry.isSealed {
                sealedBody
            } else {
                openBody
            }
        }
        .background(entry.isSealed ? Palette.surface : Palette.primary)
        .shadow(color: Palette.background.opacity(0.55), radius: 8, x: 0, y: 5)
        .rotationEffect(.degrees(PolaroidMotion.tilt(for: entry.id)))
        .overlay(alignment: .topTrailing) {
            if loved {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(entry.isSealed ? Palette.primary : Palette.background)
                    .padding(.top, 16)
                    .padding(.trailing, 14)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
    }

    private var openBody: some View {
        VStack(spacing: 0) {
            Image(entry.imageName)
                .resizable()
                .scaledToFill()
                .frame(minHeight: 118, maxHeight: 148)
                .clipped()
                .padding(.horizontal, 10)
                .padding(.top, 10)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundColor(Palette.background)
                    .lineLimit(2)

                if !handwritten.isEmpty {
                    Text(handwritten)
                        .font(.system(size: 12, weight: .regular, design: .serif))
                        .italic()
                        .foregroundColor(Palette.background.opacity(0.82))
                        .lineLimit(3)
                }

                Text("\(entry.moodEmoji)  \(entry.mood)")
                    .font(.system(size: 10, weight: .medium, design: .serif))
                    .foregroundColor(Palette.surface)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 14)
        }
    }

    private var sealedBody: some View {
        VStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(Palette.primary)
                .padding(.top, 36)
            Text("Sealed")
                .font(.system(size: 15, weight: .semibold, design: .serif))
                .foregroundColor(Palette.primary)
            if let sealedUntil = entry.sealedUntil {
                Text("Opens \(SealDate.medium.string(from: sealedUntil))")
                    .font(.system(size: 11, design: .serif))
                    .foregroundColor(Palette.accent)
                    .multilineTextAlignment(.center)
            }
            Spacer(minLength: 16)
        }
        .frame(maxWidth: .infinity, minHeight: 176)
        .overlay(
            Rectangle()
                .stroke(Palette.primary.opacity(0.45), lineWidth: 8)
                .padding(6)
        )
    }
}

struct VelvetEmptyState: View {
    let title: String
    let systemImage: String
    var subtitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 12)
            Button(action: { action?() }) {
                VStack(spacing: 16) {
                    Image(systemName: systemImage)
                        .font(.system(size: 50, weight: .regular))
                        .foregroundColor(Palette.primary)
                        .shadow(color: Palette.primary.opacity(0.45), radius: 8)
                    Text(title)
                        .font(.system(size: 20, weight: .medium, design: .serif))
                        .foregroundColor(Palette.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 14, design: .serif))
                            .italic()
                            .foregroundColor(Palette.accent)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(action == nil)
            Spacer(minLength: 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct VelvetFilterChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundColor(selected ? Palette.background : Palette.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(selected ? Palette.primary : Palette.surface)
                )
                .overlay(
                    Capsule()
                        .stroke(Palette.primary.opacity(selected ? 0 : 0.55), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct UndoBanner: View {
    let title: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 14, design: .serif))
                .foregroundColor(Palette.primary)
            Spacer()
            Button(action: action) {
                Text("Undo")
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundColor(Palette.background)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Palette.primary))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Palette.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Palette.primary.opacity(0.4), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

struct MoodChip: View {
    let mood: Mood
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(mood.emoji)  \(mood.rawValue)")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundColor(selected ? Palette.background : Palette.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(selected ? Palette.primary : Palette.surface)
                )
                .overlay(
                    Capsule()
                        .stroke(Palette.primary.opacity(selected ? 0 : 0.55), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct StageHeading: View {
    let title: String
    var systemImage: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundColor(Palette.primary)
            Spacer()
            if let systemImage, let action {
                Button(action: action) {
                    Image(systemName: systemImage)
                        .font(.system(size: 26, weight: .regular))
                        .foregroundColor(Palette.primary)
                        .shadow(color: Palette.primary.opacity(0.35), radius: 6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 8)
    }
}

struct VelvetFieldPanel<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .serif))
                .foregroundColor(Palette.accent)
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Palette.primary.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: Palette.background.opacity(0.35), radius: 8, y: 3)
    }
}

struct VelvetPromptField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: 16, design: .serif))
                    .foregroundColor(Palette.primary.opacity(0.48))
                    .allowsHitTesting(false)
            }
            TextField("", text: $text)
                .font(.system(size: 16, design: .serif))
                .foregroundColor(Palette.primary)
                .tint(Palette.accent)
        }
    }
}

struct VelvetPromptEditor: View {
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 90

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(.system(size: 15, design: .serif))
                .foregroundColor(Palette.primary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: minHeight)
                .tint(Palette.accent)
            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: 15, design: .serif))
                    .foregroundColor(Palette.primary.opacity(0.48))
                    .padding(.top, 8)
                    .padding(.leading, 5)
                    .allowsHitTesting(false)
            }
        }
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        simultaneousGesture(
            TapGesture().onEnded { _ in
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        )
    }
}
