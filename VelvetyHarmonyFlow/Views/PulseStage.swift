import SwiftUI
import Charts

struct PulseStage: View {
    @EnvironmentObject private var store: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StageHeading(title: "Mood Pulse")
                .padding(.horizontal, 16)

            if store.entries.isEmpty {
                VelvetEmptyState(
                    title: "Capture a feeling to see its pulse",
                    systemImage: "waveform.path.ecg"
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        summaryStrip
                        moodChartPanel
                        activityChartPanel
                        heatPanel
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
            }
        }
    }

    private var summaryStrip: some View {
        HStack(spacing: 10) {
            pulseStat(value: "\(store.entries.count)", label: "Polaroids")
            pulseStat(value: "\(store.captions.count)", label: "Captions")
            pulseStat(value: "\(store.captureStreak())", label: "Day streak")
        }
    }

    private func pulseStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundColor(Palette.primary)
            Text(label)
                .font(.system(size: 11, design: .serif))
                .foregroundColor(Palette.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Palette.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Palette.primary.opacity(0.35), lineWidth: 1)
        )
    }

    private var moodChartPanel: some View {
        VelvetFieldPanel(title: "Mood mix") {
            Chart(moodRows) { row in
                BarMark(
                    x: .value("Mood", row.mood.rawValue),
                    y: .value("Polaroids", row.count)
                )
                .foregroundStyle(Palette.primary)
                .cornerRadius(5)
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let name = value.as(String.self), let mood = Mood.matchingExact(name) {
                            Text(mood.emoji)
                                .font(.system(size: 13))
                        }
                    }
                    .foregroundStyle(Palette.accent)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                        .foregroundStyle(Palette.primary.opacity(0.18))
                    AxisValueLabel()
                        .foregroundStyle(Palette.accent)
                }
            }
            .frame(height: 168)
        }
    }

    private var activityChartPanel: some View {
        VelvetFieldPanel(title: "Last 14 days") {
            Chart(dayRows) { row in
                AreaMark(
                    x: .value("Day", row.date),
                    y: .value("Polaroids", row.count)
                )
                .foregroundStyle(Palette.primary.opacity(0.22))
                LineMark(
                    x: .value("Day", row.date),
                    y: .value("Polaroids", row.count)
                )
                .foregroundStyle(Palette.primary)
                .lineStyle(StrokeStyle(lineWidth: 2))
                PointMark(
                    x: .value("Day", row.date),
                    y: .value("Polaroids", row.count)
                )
                .foregroundStyle(Palette.primary)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                    AxisGridLine()
                        .foregroundStyle(Palette.primary.opacity(0.12))
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .foregroundStyle(Palette.accent)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                        .foregroundStyle(Palette.primary.opacity(0.18))
                    AxisValueLabel()
                        .foregroundStyle(Palette.accent)
                }
            }
            .frame(height: 168)
        }
    }

    private var heatPanel: some View {
        VelvetFieldPanel(title: "Four weeks of light") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 5) {
                ForEach(Array(weekdayHeads.enumerated()), id: \.offset) { _, day in
                    Text(day)
                        .font(.system(size: 10, weight: .semibold, design: .serif))
                        .foregroundColor(Palette.accent)
                        .frame(maxWidth: .infinity)
                }
                ForEach(heatCells) { cell in
                    RoundedRectangle(cornerRadius: 5)
                        .fill(cell.date == nil ? Color.clear : heatFill(for: cell.count))
                        .frame(height: 26)
                        .overlay {
                            if let date = cell.date {
                                Text("\(Calendar.current.component(.day, from: date))")
                                    .font(.system(size: 9, design: .serif))
                                    .foregroundColor(cell.count == 0 ? Palette.accent : Palette.background)
                            }
                        }
                        .accessibilityLabel(cell.date == nil ? "Empty" : "\(cell.count) polaroids")
                }
            }
        }
    }

    private var moodRows: [MoodPulseRow] {
        Mood.allCases.map { mood in
            MoodPulseRow(mood: mood, count: store.polaroidCount(for: mood))
        }
    }

    private var dayRows: [DayPulseRow] {
        store.polaroidsByDay(last: 14).map { DayPulseRow(date: $0.date, count: $0.count) }
    }

    private var weekdayHeads: [String] {
        let calendar = Calendar.current
        let symbols = calendar.veryShortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        if first == 0 {
            return symbols
        }
        return Array(symbols[first...]) + Array(symbols[..<first])
    }

    private var heatCells: [HeatCell] {
        let calendar = Calendar.current
        let days = store.polaroidsByDay(last: 28)
        guard let firstDate = days.first?.date else { return [] }
        var leading = calendar.component(.weekday, from: firstDate) - calendar.firstWeekday
        if leading < 0 {
            leading += 7
        }
        var cells: [HeatCell] = []
        if leading > 0 {
            for index in 0..<leading {
                cells.append(HeatCell(id: -(index + 1), date: nil, count: 0))
            }
        }
        for (index, day) in days.enumerated() {
            cells.append(HeatCell(id: index, date: day.date, count: day.count))
        }
        return cells
    }

    private func heatFill(for count: Int) -> Color {
        if count <= 0 {
            return Palette.surface
        }
        let intensity = min(0.35 + Double(count) * 0.18, 1)
        return Palette.primary.opacity(intensity)
    }
}

private struct MoodPulseRow: Identifiable {
    let mood: Mood
    let count: Int
    var id: String { mood.rawValue }
}

private struct DayPulseRow: Identifiable {
    let date: Date
    let count: Int
    var id: Date { date }
}

private struct HeatCell: Identifiable {
    let id: Int
    let date: Date?
    let count: Int
}

private extension Mood {
    static func matchingExact(_ name: String) -> Mood? {
        Mood(rawValue: name)
    }
}
