import SwiftUI
import UIKit

enum Palette {
    static let background = Color("AppBackground")
    static let surface = Color("AppSurface")
    static let primary = Color("AppPrimary")
    static let accent = Color("AppAccent")
}

struct AppBackgroundView: View {
    var body: some View {
        Color("AppBackground")
            .overlay {
                Image("BgMeadow")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.22)
            }
            .overlay {
                LinearGradient(
                    colors: [
                        Color("AppBackground").opacity(0.35),
                        Color("AppAccent").opacity(0.12),
                        Color("AppPrimary").opacity(0.14)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .clipped()
            .ignoresSafeArea()
    }
}

struct AppCanvasModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                AppBackgroundView()
            }
    }
}

extension View {
    func appCanvas() -> some View {
        modifier(AppCanvasModifier())
    }

    /// Backward-compatible alias used during migration.
    func velvetCanvas() -> some View {
        appCanvas()
    }

    func clearScrollBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.clear)
    }

    /// Clears NavigationStack / UIKit chrome so AppBackgroundView shows through.
    func transparentNavigationChrome() -> some View {
        self
            .toolbarBackground(.hidden, for: .navigationBar)
            .background(Color.clear)
    }

    func dismissKeyboardOnTap() -> some View {
        simultaneousGesture(
            TapGesture().onEnded { _ in
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        )
    }
}

struct LaneTabBar: View {
    @Binding var selectedLane: HomeLane
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(HomeLane.allCases) { lane in
                Button {
                    selectedLane = lane
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: lane.symbol)
                            .font(.system(size: 16, weight: .semibold))
                        Text(lane.rawValue)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(selectedLane == lane ? Palette.background : Palette.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(selectedLane == lane ? Palette.primary : Palette.surface.opacity(0.7))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(lane.rawValue)
                .accessibilityAddTraits(selectedLane == lane ? .isSelected : [])
            }

            Button(action: onSettings) {
                VStack(spacing: 4) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("More")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundColor(Palette.primary)
                .frame(width: 58)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Palette.surface.opacity(0.7))
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Palette.background.opacity(0.94))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Palette.primary.opacity(0.25))
                .frame(height: 1)
        }
    }
}

struct NoteCard: View {
    let note: DayNote

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: note.kindValue.symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Palette.background)
                    .padding(7)
                    .background(Circle().fill(Palette.primary))

                Text(note.kind.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Palette.accent)

                Spacer()

                if note.pinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Palette.primary)
                }

                Text(NoteDate.shortTime.string(from: note.createdAt))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(Palette.primary.opacity(0.55))
            }

            Text(note.title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(Palette.primary)
                .fixedSize(horizontal: false, vertical: true)

            if !note.body.isEmpty {
                Text(note.body)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(Palette.primary.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Palette.primary.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Palette.background.opacity(0.35), radius: 8, y: 3)
    }
}

struct UsefulEmptyState: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var primaryTitle: String? = nil
    var primaryAction: (() -> Void)? = nil
    var secondaryTitle: String? = nil
    var secondaryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 20)

            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .regular))
                .foregroundColor(Palette.primary)
                .padding(18)
                .background(
                    Circle()
                        .fill(Palette.surface)
                        .overlay(Circle().stroke(Palette.primary.opacity(0.2), lineWidth: 1))
                )

            Text(title)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Palette.primary)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(Palette.accent)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            if let primaryTitle, let primaryAction {
                Button(action: primaryAction) {
                    Text(primaryTitle)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Palette.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Palette.primary))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 36)
            }

            if let secondaryTitle, let secondaryAction {
                Button(action: secondaryAction) {
                    Text(secondaryTitle)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Palette.primary)
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FilterChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(selected ? Palette.background : Palette.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(selected ? Palette.primary : Palette.surface)
                )
                .overlay(
                    Capsule().stroke(Palette.primary.opacity(selected ? 0 : 0.45), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct KindChip: View {
    let kind: NoteKind
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: kind.symbol)
                    .font(.system(size: 12, weight: .semibold))
                Text(kind.rawValue)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundColor(selected ? Palette.background : Palette.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(selected ? Palette.primary : Palette.surface)
            )
            .overlay(
                Capsule().stroke(Palette.primary.opacity(selected ? 0 : 0.45), lineWidth: 1)
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
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(Palette.primary)
            Spacer()
            Button(action: action) {
                Text("Undo")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
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
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Palette.primary.opacity(0.35), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

struct StageHeading: View {
    let title: String
    var systemImage: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(Palette.primary)
            Spacer()
            if let systemImage, let action {
                Button(action: action) {
                    Image(systemName: systemImage)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(Palette.primary)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Palette.surface))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 4)
    }
}

struct FieldPanel<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(Palette.accent)
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Palette.primary.opacity(0.28), lineWidth: 1)
        )
    }
}

struct PromptField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(Palette.primary.opacity(0.45))
                    .allowsHitTesting(false)
            }
            TextField("", text: $text)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(Palette.primary)
                .tint(Palette.accent)
        }
    }
}

struct PromptEditor: View {
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 90

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(Palette.primary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: minHeight)
                .tint(Palette.accent)
            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(Palette.primary.opacity(0.45))
                    .padding(.top, 8)
                    .padding(.leading, 5)
                    .allowsHitTesting(false)
            }
        }
    }
}

/// Shared note composer used by Today and Ledger.
struct NoteComposerSheet: View {
    enum Mode: Identifiable {
        case create(NoteKind)
        case edit(DayNote)

        var id: String {
            switch self {
            case .create(let kind): return "create-\(kind.rawValue)"
            case .edit(let note): return "edit-\(note.id.uuidString)"
            }
        }
    }

    let mode: Mode
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var kind: NoteKind = .win
    @State private var title = ""
    @State private var bodyText = ""
    @State private var pinned = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(kind.hint)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(Palette.accent)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(NoteKind.allCases) { item in
                                    KindChip(kind: item, selected: kind == item) {
                                        kind = item
                                    }
                                }
                            }
                        }

                        FieldPanel(title: "Headline") {
                            PromptField(placeholder: "Short title", text: $title)
                        }

                        FieldPanel(title: "Details") {
                            PromptEditor(placeholder: "What happened, or what you want next…", text: $bodyText, minHeight: 120)
                        }

                        Toggle(isOn: $pinned) {
                            Text("Pin to Review")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(Palette.primary)
                        }
                        .tint(Palette.primary)
                        .padding(14)
                        .background(Palette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(20)
                    .padding(.bottom, 24)
                }
                .clearScrollBackground()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .fontWeight(.bold)
                }
            }
        }
        .transparentNavigationChrome()
        .dismissKeyboardOnTap()
        .onAppear(perform: hydrate)
    }

    private var navigationTitle: String {
        switch mode {
        case .create: return "New note"
        case .edit: return "Edit note"
        }
    }

    private func hydrate() {
        switch mode {
        case .create(let initial):
            kind = initial
        case .edit(let note):
            kind = note.kindValue
            title = note.title
            bodyText = note.body
            pinned = note.pinned
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        switch mode {
        case .create:
            store.addNote(
                DayNote(kind: kind, title: trimmedTitle, body: trimmedBody, pinned: pinned)
            )
        case .edit(var note):
            note.kind = kind.rawValue
            note.title = trimmedTitle
            note.body = trimmedBody
            note.pinned = pinned
            store.updateNote(note)
        }
        dismiss()
    }
}
