import SwiftUI

struct CaptionStage: View {
    @EnvironmentObject private var store: Store
    @State private var composer: CaptionComposerState?
    @State private var pendingDelete: EmotiveCaption?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StageHeading(title: "Emotive Captions", systemImage: "text.bubble.fill") {
                composer = .create(nil)
            }
            .padding(.horizontal, 16)

            if store.captions.isEmpty {
                VelvetEmptyState(
                    title: "Start capturing your feelings!",
                    systemImage: "text.bubble.fill",
                    subtitle: DailyPrompt.phrase()
                ) {
                    composer = .create(nil)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 28) {
                        ForEach(captionedPosters) { poster in
                            VStack(spacing: 10) {
                                Button {
                                    if let caption = poster.captions.first {
                                        composer = .edit(caption)
                                    }
                                } label: {
                                    PolaroidCard(
                                        entry: poster.entry,
                                        handwritten: poster.captions.first?.captionText ?? poster.entry.description,
                                        loved: store.isLoved(poster.entry.id)
                                    )
                                    .padding(.horizontal, 32)
                                }
                                .buttonStyle(.plain)

                                ForEach(poster.captions) { caption in
                                    Text(caption.captionText)
                                        .font(.system(size: 14, weight: .regular, design: .serif))
                                        .italic()
                                        .foregroundColor(Palette.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 40)
                                }
                            }
                            .contextMenu {
                                if let caption = poster.captions.first {
                                    Button("Edit Caption") {
                                        composer = .edit(caption)
                                    }
                                    Button("Add Another") {
                                        composer = .create(poster.entry.id)
                                    }
                                    Button("Delete Caption", role: .destructive) {
                                        pendingDelete = caption
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 28)
                }
            }
        }
        .sheet(item: $composer) { state in
            CaptionComposerView(state: state)
                .environmentObject(store)
        }
        .confirmationDialog("Remove this caption?", isPresented: deleteDialogBinding, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let caption = pendingDelete {
                    store.deleteCaption(id: caption.id)
                }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) {
                pendingDelete = nil
            }
        }
    }

    private var captionedPosters: [PosterCaptions] {
        var seen: [UUID] = []
        var result: [PosterCaptions] = []
        for caption in store.captions {
            if seen.contains(caption.photoId) {
                continue
            }
            guard let entry = store.entry(for: caption.photoId), !entry.isSealed else { continue }
            seen.append(caption.photoId)
            result.append(
                PosterCaptions(
                    entry: entry,
                    captions: store.captions(for: entry.id)
                )
            )
        }
        return result
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
}

private struct PosterCaptions: Identifiable {
    let entry: EmotionEntry
    let captions: [EmotiveCaption]
    var id: UUID { entry.id }
}

enum CaptionComposerState: Identifiable {
    case create(UUID?)
    case edit(EmotiveCaption)

    var id: String {
        switch self {
        case .create(let photoId):
            if let photoId {
                return "create-\(photoId.uuidString)"
            }
            return "create"
        case .edit(let caption):
            return caption.id.uuidString
        }
    }
}

struct CaptionComposerView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss
    let state: CaptionComposerState

    @State private var selectedPhotoId: UUID?
    @State private var captionText = ""
    @State private var showEmptyAlert = false
    @State private var confirmDelete = false
    @State private var showMissingPhotoAlert = false

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
                    if store.entries.filter({ !$0.isSealed }).isEmpty {
                        Text("Add an unsealed polaroid in Archive first, then return to write beneath it.")
                            .font(.system(size: 15, design: .serif))
                            .foregroundColor(Palette.accent)
                            .multilineTextAlignment(.center)
                            .padding(.top, 24)
                    } else {
                        if let preview = previewEntry {
                            PolaroidCard(entry: preview, handwritten: captionText)
                                .padding(.horizontal, 28)
                                .padding(.top, 8)
                        }

                        VelvetFieldPanel(title: "Polaroid") {
                            VStack(spacing: 8) {
                                ForEach(store.entries.filter { !$0.isSealed }) { entry in
                                    Button {
                                        selectedPhotoId = entry.id
                                    } label: {
                                        HStack {
                                            Text("\(entry.moodEmoji)  \(entry.title)")
                                                .font(.system(size: 15, design: .serif))
                                                .foregroundColor(Palette.primary)
                                            Spacer()
                                            if selectedPhotoId == entry.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(Palette.primary)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        VelvetFieldPanel(title: "Caption") {
                            VStack(alignment: .leading, spacing: 8) {
                                VelvetPromptEditor(
                                    placeholder: DailyPrompt.phrase(),
                                    text: $captionText,
                                    minHeight: 110
                                )
                                Button {
                                    captionText = DailyPrompt.phrase()
                                } label: {
                                    Text("Use today's line")
                                        .font(.system(size: 13, weight: .semibold, design: .serif))
                                        .foregroundColor(Palette.accent)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Button {
                            persist()
                        } label: {
                            Text("Save Caption")
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
                                Text("Delete Caption")
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
        .alert("Write a caption before saving", isPresented: $showEmptyAlert) {
            Button("OK", role: .cancel) {}
        }
        .alert("Choose a polaroid first", isPresented: $showMissingPhotoAlert) {
            Button("OK", role: .cancel) {}
        }
        .confirmationDialog("Remove this caption?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if case .edit(let caption) = state {
                    store.deleteCaption(id: caption.id)
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var heading: String {
        switch state {
        case .create:
            return "New Caption"
        case .edit:
            return "Edit Caption"
        }
    }

    private var previewEntry: EmotionEntry? {
        guard let selectedPhotoId else { return nil }
        return store.entry(for: selectedPhotoId)
    }

    private func hydrate() {
        switch state {
        case .create(let photoId):
            selectedPhotoId = photoId ?? store.entries.first(where: { !$0.isSealed })?.id
        case .edit(let caption):
            selectedPhotoId = caption.photoId
            captionText = caption.captionText
        }
    }

    private func persist() {
        let trimmed = captionText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            showEmptyAlert = true
            return
        }
        guard let selectedPhotoId else {
            showMissingPhotoAlert = true
            return
        }
        switch state {
        case .create:
            store.addCaption(
                EmotiveCaption(photoId: selectedPhotoId, captionText: trimmed)
            )
        case .edit(let existing):
            var updated = existing
            updated.photoId = selectedPhotoId
            updated.captionText = trimmed
            store.updateCaption(updated)
        }
        dismiss()
    }
}
