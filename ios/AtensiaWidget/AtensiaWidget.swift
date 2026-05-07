import WidgetKit
import SwiftUI

// MARK: - Shared constants

private let appGroupId = "group.com.texapp.atensia"
private let widgetURL = URL(string: "atensia://today")!

// MARK: - Timeline entry

struct AtensiaEntry: TimelineEntry {
    let date: Date
    let quadrant: String      // e.g. "На підйомі" — empty when not set
    let streak: Int
    let valenceLabel: String  // e.g. "Чудово" — empty when not set
    let arousalLabel: String  // e.g. "Бадьоро" — empty when not set
    let hasEntry: Bool
}

// MARK: - Timeline provider

struct AtensiaProvider: TimelineProvider {
    func placeholder(in context: Context) -> AtensiaEntry {
        AtensiaEntry(date: Date(), quadrant: "На підйомі", streak: 3,
                     valenceLabel: "Чудово", arousalLabel: "Бадьоро", hasEntry: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (AtensiaEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AtensiaEntry>) -> Void) {
        let entry = loadEntry()
        // Refresh widget at the next calendar midnight.
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86_400))
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }

    // MARK: Private

    private func loadEntry() -> AtensiaEntry {
        let d = UserDefaults(suiteName: appGroupId)
        return AtensiaEntry(
            date: Date(),
            quadrant:     d?.string(forKey: "widget_quadrant")      ?? "",
            streak:       d?.integer(forKey: "widget_streak")       ?? 1,
            valenceLabel: d?.string(forKey: "widget_valence_label") ?? "",
            arousalLabel: d?.string(forKey: "widget_arousal_label") ?? "",
            hasEntry:     d?.bool(forKey: "widget_has_entry")       ?? false
        )
    }
}

// MARK: - Small widget view (2×2)

struct AtensiaSmallView: View {
    let entry: AtensiaEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("АТЕНЦІЯ")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary)
                .kerning(1.1)

            Spacer()

            Text(entry.hasEntry ? entry.quadrant : "—")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Spacer()

            HStack(spacing: 3) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(entry.hasEntry ? .primary : .secondary)
                Text("\(entry.streak)")
                    .font(.system(size: 12, weight: .bold))
                Text(streakSuffix(entry.streak))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.white)
        .widgetURL(widgetURL)
    }

    private func streakSuffix(_ n: Int) -> String {
        let mod10 = n % 10
        let mod100 = n % 100
        if mod10 == 1 && mod100 != 11 { return "день" }
        if mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14) { return "дні" }
        return "днів"
    }
}

// MARK: - Medium widget view (4×2)

struct AtensiaMediumView: View {
    let entry: AtensiaEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header row
            HStack {
                Text("АТЕНЦІЯ")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
                    .kerning(1.1)
                Spacer()
                if entry.hasEntry {
                    Text(entry.quadrant)
                        .font(.system(size: 11, weight: .medium))
                        .italic()
                        .foregroundColor(.secondary)
                }
            }

            // Axis selectors row
            HStack(spacing: 10) {
                // Valence axis
                AxisSelector(
                    label: "НАСТРІЙ",
                    options: ["Погано", "Нормально", "Чудово"],
                    selectedLabel: entry.valenceLabel
                )
                // Arousal axis
                AxisSelector(
                    label: "ЕНЕРГІЯ",
                    options: ["Виснажено", "Нормально", "Бадьоро"],
                    selectedLabel: entry.arousalLabel
                )
            }
            .frame(maxHeight: .infinity)

            // Streak footer
            HStack(spacing: 3) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(entry.hasEntry ? .primary : .secondary)
                Text("\(entry.streak) \(streakSuffix(entry.streak))")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.white)
        .widgetURL(widgetURL)
    }

    private func streakSuffix(_ n: Int) -> String {
        let mod10 = n % 10
        let mod100 = n % 100
        if mod10 == 1 && mod100 != 11 { return "день" }
        if mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14) { return "дні" }
        return "днів"
    }
}

// MARK: - Axis selector sub-view

private struct AxisSelector: View {
    let label: String
    let options: [String]
    let selectedLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.secondary)
                .kerning(0.8)

            HStack(spacing: 0) {
                ForEach(Array(options.enumerated()), id: \.offset) { idx, option in
                    if idx > 0 {
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 1.5)
                    }
                    let isSelected = (option == selectedLabel)
                    Text(option)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(isSelected ? Color.black : Color.white)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.black, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Widget configuration

@main
struct AtensiaWidget: Widget {
    let kind: String = "AtensiaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AtensiaProvider()) { entry in
            AtensiaEntryView(entry: entry)
        }
        .configurationDisplayName("Атенція")
        .description("Сьогоднішній стан та серія записів.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Entry view dispatcher

struct AtensiaEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: AtensiaEntry

    var body: some View {
        switch family {
        case .systemSmall:
            AtensiaSmallView(entry: entry)
        case .systemMedium:
            AtensiaMediumView(entry: entry)
        default:
            AtensiaSmallView(entry: entry)
        }
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    AtensiaWidget()
} timeline: {
    AtensiaEntry(date: .now, quadrant: "На підйомі", streak: 5,
                 valenceLabel: "Чудово", arousalLabel: "Бадьоро", hasEntry: true)
    AtensiaEntry(date: .now, quadrant: "", streak: 1,
                 valenceLabel: "", arousalLabel: "", hasEntry: false)
}

#Preview("Medium", as: .systemMedium) {
    AtensiaWidget()
} timeline: {
    AtensiaEntry(date: .now, quadrant: "В рівновазі", streak: 2,
                 valenceLabel: "Нормально", arousalLabel: "Нормально", hasEntry: true)
}
