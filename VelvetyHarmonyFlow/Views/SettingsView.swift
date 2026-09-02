import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Contact Sheet")
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundColor(Palette.primary)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("Close")
                        .font(.system(size: 15, weight: .medium, design: .serif))
                        .foregroundColor(Palette.primary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 16)

            LazyVGrid(columns: columns, spacing: 18) {
                contactFrame(title: "Rate Us", symbol: "star") {
                    AppLinks.requestReview()
                }
                contactFrame(title: "Privacy", symbol: "hand.raised") {
                    AppLinks.openPrivacy()
                }
                contactFrame(title: "Terms", symbol: "doc.text") {
                    AppLinks.openTerms()
                }
                contactFrame(title: "Darkroom", symbol: store.darkroomEnabled ? "moon.fill" : "moon") {
                    store.toggleDarkroom()
                }
                contactFrame(title: "Evening", symbol: store.eveningPromptEnabled ? "bell.fill" : "bell") {
                    store.setEveningPrompt(!store.eveningPromptEnabled)
                }
                contactFrame(title: "Reset", symbol: "arrow.counterclockwise") {
                    confirmReset = true
                }
            }
            .padding(.horizontal, 22)

            Spacer()
        }
        .velvetCanvas()
        .darkroomVeil(store.darkroomEnabled)
        .confirmationDialog("Erase every polaroid, caption, and favourite?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset", role: .destructive) {
                store.resetAll()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func contactFrame(title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 0) {
                ZStack {
                    Palette.surface
                    Image(systemName: symbol)
                        .font(.system(size: 28, weight: .regular))
                        .foregroundColor(Palette.background.opacity(0.55))
                }
                .frame(height: 92)
                .padding(8)
                .background(Palette.primary)

                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundColor(Palette.background)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 12)
                    .background(Palette.primary)
            }
            .rotationEffect(.degrees(rotation(for: title)))
            .shadow(color: Palette.background.opacity(0.5), radius: 8, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .frame(minHeight: 44)
    }

    private func rotation(for title: String) -> Double {
        switch title {
        case "Privacy":
            return -2.4
        case "Terms":
            return 1.8
        case "Reset":
            return -1.2
        case "Darkroom":
            return -1.6
        case "Evening":
            return 2.0
        default:
            return 2.2
        }
    }
}
