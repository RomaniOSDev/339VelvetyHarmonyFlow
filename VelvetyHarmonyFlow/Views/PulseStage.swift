import SwiftUI
import Charts

struct ReviewStage: View {
    @EnvironmentObject private var store: Store
    @State private var composer: NoteComposerSheet.Mode?

    private let tabBarClearance: CGFloat = 100

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                if store.notes.isEmpty {
                    UsefulEmptyState(
                        title: "No patterns yet",
                        subtitle: "After a few days of intentions and wins, Review shows your streak, mix, and pinned notes.",
                        systemImage: "chart.bar.fill",
                        primaryTitle: "Start today’s ritual",
                        primaryAction: {
                            NotificationCenter.default.post(name: Notification.Name("goToday"), object: nil)
                        },
                        secondaryTitle: "Load sample week",
                        secondaryAction: { store.installDemoContent() }
                    )
                    .padding(.bottom, tabBarClearance)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            StageHeading(title: "Review")

                            statsRow
                            kindChart
                            activityChart
                            pinnedSection
                            tipCard
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, tabBarClearance)
                    }
                    .clearScrollBackground()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .transparentNavigationChrome()
        .sheet(item: $composer) { mode in
            NoteComposerSheet(mode: mode)
                .environmentObject(store)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statCard(value: "\(store.captureStreak())", label: "Day streak")
            statCard(value: "\(store.notes.count)", label: "Notes")
            statCard(value: "\(store.pinnedNotes().count)", label: "Pinned")
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(Palette.primary)
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(Palette.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var kindChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NOTE MIX")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Palette.accent)

            Chart(kindRows) { row in
                BarMark(
                    x: .value("Kind", row.kind.rawValue),
                    y: .value("Count", row.count)
                )
                .foregroundStyle(Palette.primary)
                .annotation(position: .top, spacing: 4) {
                    if row.count > 0 {
                        Text("\(row.count)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(Palette.primary.opacity(0.7))
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let name = value.as(String.self), let kind = NoteKind(rawValue: name) {
                            Image(systemName: kind.symbol)
                                .foregroundColor(Palette.primary)
                        }
                    }
                }
            }
            .frame(height: 160)
        }
        .padding(16)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var activityChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LAST 14 DAYS")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Palette.accent)

            Chart(dayRows) { row in
                BarMark(
                    x: .value("Day", row.date, unit: .day),
                    y: .value("Notes", row.count)
                )
                .foregroundStyle(Palette.accent.opacity(0.85))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day())
                }
            }
            .frame(height: 140)
        }
        .padding(16)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private var pinnedSection: some View {
        Text("PINNED")
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(Palette.accent)

        let pinned = store.pinnedNotes()
        if pinned.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Pin notes that should stay visible")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Palette.primary)
                Text("Open any note in Ledger and choose Pin — useful for lasting intentions or hard-won wins.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(Palette.primary.opacity(0.7))
                Button {
                    composer = .create(.intention)
                } label: {
                    Text("Write a lasting intention")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Palette.background)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Palette.primary))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else {
            ForEach(pinned.prefix(5)) { note in
                Button {
                    composer = .edit(note)
                } label: {
                    NoteCard(note: note)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var tipCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("RITUAL TIP")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Palette.accent)
            Text("Morning: one intention. Evening: at least one win. Friction and gratitude fill the gaps so the week has shape.")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(Palette.primary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var kindRows: [KindPulseRow] {
        NoteKind.allCases.map { kind in
            KindPulseRow(kind: kind, count: store.count(for: kind))
        }
    }

    private var dayRows: [DayPulseRow] {
        store.notesByDay(last: 14).map { DayPulseRow(date: $0.date, count: $0.count) }
    }
}

private struct KindPulseRow: Identifiable {
    let kind: NoteKind
    let count: Int
    var id: String { kind.rawValue }
}

private struct DayPulseRow: Identifiable {
    let date: Date
    let count: Int
    var id: Date { date }
}

typealias PulseStage = ReviewStage
