import SwiftUI

/// Legacy gallery screen removed from IA. Kept as a thin redirect helper for Spotlight deep links.
struct GalleryStage: View {
    var body: some View {
        UsefulEmptyState(
            title: "Moved to Ledger",
            subtitle: "Notes now live in a chronological ledger with type filters — not a mood gallery.",
            systemImage: "arrow.right.circle.fill"
        )
    }
}
