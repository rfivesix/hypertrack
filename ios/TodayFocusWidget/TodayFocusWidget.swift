import SwiftUI
import WidgetKit

private let widgetSuiteName = "group.com.rfivesix.hypertrack.widget"
private let payloadKey = "payload_json"

private func widgetLocalized(_ key: String) -> String {
  NSLocalizedString(key, comment: "")
}

struct TodayFocusWidgetItem: Decodable, Identifiable {
  let key: String
  let label: String
  let valueText: String
  let accentColor: Int

  var id: String { key }
}

struct TodayFocusWidgetPayload: Decodable {
  let title: String
  let subtitle: String
  let emptyText: String
  let enabled: Bool
  let maxVisibleItems: Int
  let items: [TodayFocusWidgetItem]

  static let empty = TodayFocusWidgetPayload(
    title: widgetLocalized("widget_title"),
    subtitle: "",
    emptyText: widgetLocalized("widget_empty"),
    enabled: false,
    maxVisibleItems: 6,
    items: []
  )
}

struct TodayFocusWidgetEntry: TimelineEntry {
  let date: Date
  let payload: TodayFocusWidgetPayload
}

struct TodayFocusWidgetProvider: TimelineProvider {
  func placeholder(in context: Context) -> TodayFocusWidgetEntry {
    TodayFocusWidgetEntry(date: Date(), payload: .empty)
  }

  func getSnapshot(in context: Context, completion: @escaping (TodayFocusWidgetEntry) -> Void) {
    completion(TodayFocusWidgetEntry(date: Date(), payload: loadPayload()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<TodayFocusWidgetEntry>) -> Void) {
    let entry = TodayFocusWidgetEntry(date: Date(), payload: loadPayload())
    let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
    completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
  }

  private func loadPayload() -> TodayFocusWidgetPayload {
    guard let defaults = UserDefaults(suiteName: widgetSuiteName) else {
      return .empty
    }
    guard let raw = defaults.string(forKey: payloadKey), let data = raw.data(using: .utf8) else {
      return .empty
    }
    return (try? JSONDecoder().decode(TodayFocusWidgetPayload.self, from: data)) ?? .empty
  }
}

struct TodayFocusWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: TodayFocusWidgetProvider.Entry

  var body: some View {
    let payload = entry.payload
    let maxByFamily = familyMaxCount
    let visibleCount = max(1, min(payload.maxVisibleItems, maxByFamily, payload.items.count))
    let visibleItems = Array(payload.items.prefix(visibleCount))

    ZStack {
      solidBackground

      VStack(alignment: .leading, spacing: 8) {
        Text(payload.title)
          .font(.system(size: 16, weight: .bold))
          .foregroundColor(.white)
          .lineLimit(1)

        if !payload.subtitle.isEmpty {
          Text(payload.subtitle)
            .font(.system(size: 12, weight: .regular))
            .foregroundColor(.white.opacity(0.85))
            .lineLimit(1)
        }

        if !payload.enabled || visibleItems.isEmpty {
          Text(payload.emptyText)
            .font(.system(size: 12, weight: .regular))
            .foregroundColor(.white.opacity(0.85))
            .padding(.top, 4)
          Spacer(minLength: 0)
        } else {
          VStack(alignment: .leading, spacing: 6) {
            ForEach(visibleItems) { item in
              HStack(spacing: 8) {
                Rectangle()
                  .fill(colorFromArgb(item.accentColor))
                  .frame(width: 4, height: 24)
                  .cornerRadius(2)

                VStack(alignment: .leading, spacing: 1) {
                  Text(item.label)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(1)
                  Text(item.valueText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                }

                Spacer(minLength: 0)
              }
            }
          }
          Spacer(minLength: 0)
        }
      }
      .padding(12)
    }
    .widgetURL(URL(string: "hypertrack://diary"))
    .modifier(TodayFocusWidgetBackgroundModifier(color: solidBackground))
  }

  private var familyMaxCount: Int {
    switch family {
    case .systemSmall:
      return 2
    case .systemMedium:
      return 4
    case .systemLarge:
      return 8
    case .systemExtraLarge:
      return 10
    case .accessoryCircular, .accessoryRectangular, .accessoryInline:
      return 2
    @unknown default:
      return 4
    }
  }

  private var solidBackground: Color {
    Color(red: 26.0 / 255.0, green: 26.0 / 255.0, blue: 26.0 / 255.0)
  }

  private func colorFromArgb(_ argb: Int) -> Color {
    let red = Double((argb >> 16) & 0xFF) / 255.0
    let green = Double((argb >> 8) & 0xFF) / 255.0
    let blue = Double(argb & 0xFF) / 255.0
    return Color(red: red, green: green, blue: blue)
  }
}

struct TodayFocusWidgetBackgroundModifier: ViewModifier {
  let color: Color

  func body(content: Content) -> some View {
    if #available(iOS 17.0, *) {
      content.containerBackground(color, for: .widget)
    } else {
      content.background(color)
    }
  }
}

struct TodayFocusWidget: Widget {
  let kind: String = "TodayFocusWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: TodayFocusWidgetProvider()) { entry in
      TodayFocusWidgetView(entry: entry)
    }
    .configurationDisplayName(widgetLocalized("widget_display_name"))
    .description(widgetLocalized("widget_description"))
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}
