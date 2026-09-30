import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 14) {
                        settingsRow(
                            title: "Evening reminder",
                            subtitle: store.eveningPromptEnabled ? "On · 20:00 local" : "Off",
                            symbol: store.eveningPromptEnabled ? "bell.fill" : "bell"
                        ) {
                            store.setEveningPrompt(!store.eveningPromptEnabled)
                        }

                        settingsRow(
                            title: "Reload sample week",
                            subtitle: "Replace current notes with demo content",
                            symbol: "square.and.arrow.down"
                        ) {
                            store.installDemoContent()
                            dismiss()
                        }

                        settingsRow(title: "Rate the app", subtitle: "App Store review prompt", symbol: "star") {
                            AppLinks.requestReview()
                        }

                        settingsRow(title: "Privacy", subtitle: "Open privacy policy", symbol: "hand.raised") {
                            AppLinks.openPrivacy()
                        }

                        settingsRow(title: "Terms", subtitle: "Open terms of use", symbol: "doc.text") {
                            AppLinks.openTerms()
                        }

                        settingsRow(title: "Reset all data", subtitle: "Erase notes and preferences", symbol: "trash") {
                            confirmReset = true
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 24)
                }
                .clearScrollBackground()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .transparentNavigationChrome()
        .confirmationDialog(
            "Erase every note and preference?",
            isPresented: $confirmReset,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                store.resetAll()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func settingsRow(
        title: String,
        subtitle: String,
        symbol: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Palette.background)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Palette.primary))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Palette.primary)
                    Text(subtitle)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(Palette.accent)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Palette.primary.opacity(0.4))
            }
            .padding(14)
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Palette.primary.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
