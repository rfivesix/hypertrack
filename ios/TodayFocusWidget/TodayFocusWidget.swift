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
  @Environment(\.colorScheme) private var colorScheme
  let entry: TodayFocusWidgetProvider.Entry

  var body: some View {
    let payload = entry.payload
    let maxByFamily = familyMaxCount
    let visibleCount = max(1, min(payload.maxVisibleItems, maxByFamily, payload.items.count))
    let visibleItems = Array(payload.items.prefix(visibleCount))
    let layout = layoutSpec
    let showSubtitle = !payload.subtitle.isEmpty && family != .systemSmall

    VStack(alignment: .leading, spacing: layout.sectionSpacing) {
      Text(payload.title)
        .font(.system(size: layout.titleFontSize, weight: .bold))
        .foregroundColor(primaryTextColor)
        .lineLimit(family == .systemSmall ? 1 : 2)
        .minimumScaleFactor(0.8)

      if showSubtitle {
        Text(payload.subtitle)
          .font(.system(size: layout.subtitleFontSize, weight: .regular))
          .foregroundColor(secondaryTextColor)
          .lineLimit(1)
      }

      if !payload.enabled || visibleItems.isEmpty {
        Text(payload.emptyText)
          .font(.system(size: layout.subtitleFontSize, weight: .regular))
          .foregroundColor(secondaryTextColor)
          .padding(.top, 4)
        Spacer(minLength: 0)
      } else {
        VStack(alignment: .leading, spacing: layout.itemSpacing) {
          ForEach(visibleItems) { item in
            HStack(spacing: layout.rowSpacing) {
              Rectangle()
                .fill(colorFromArgb(item.accentColor))
                .frame(width: 4, height: layout.accentHeight)
                .cornerRadius(2)

              VStack(alignment: .leading, spacing: 1) {
                Text(item.label)
                  .font(.system(size: layout.labelFontSize, weight: .regular))
                  .foregroundColor(secondaryTextColor)
                  .lineLimit(1)
                Text(item.valueText)
                  .font(.system(size: layout.valueFontSize, weight: .semibold))
                  .foregroundColor(primaryTextColor)
                  .lineLimit(1)
                  .minimumScaleFactor(0.82)
              }

              Spacer(minLength: 0)
            }
          }
        }
        Spacer(minLength: 0)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .padding(layout.padding)
    .widgetURL(URL(string: "hypertrack://diary"))
    .modifier(TodayFocusWidgetBackgroundModifier(color: surfaceBackground))
  }

  private var familyMaxCount: Int {
    switch family {
    case .systemSmall:
      return 3
    case .systemMedium:
      return 5
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

  private var surfaceBackground: Color {
    if colorScheme == .dark {
      return solidBackground
    }
    return Color(red: 242.0 / 255.0, green: 243.0 / 255.0, blue: 247.0 / 255.0)
  }

  private var primaryTextColor: Color {
    colorScheme == .dark ? .white : Color(red: 22.0 / 255.0, green: 24.0 / 255.0, blue: 29.0 / 255.0)
  }

  private var secondaryTextColor: Color {
    colorScheme == .dark
      ? Color.white.opacity(0.85)
      : Color(red: 69.0 / 255.0, green: 74.0 / 255.0, blue: 84.0 / 255.0)
  }

  private var layoutSpec: TodayFocusLayoutSpec {
    switch family {
    case .systemSmall:
      return TodayFocusLayoutSpec(
        padding: 7,
        sectionSpacing: 4,
        itemSpacing: 2,
        rowSpacing: 6,
        titleFontSize: 9,
        subtitleFontSize: 8,
        labelFontSize: 8,
        valueFontSize: 9,
        accentHeight: 16
      )
    case .systemMedium:
      return TodayFocusLayoutSpec(
        padding: 10,
        sectionSpacing: 6,
        itemSpacing: 4,
        rowSpacing: 8,
        titleFontSize: 13,
        subtitleFontSize: 10,
        labelFontSize: 10,
        valueFontSize: 12,
        accentHeight: 20
      )
    case .systemLarge, .systemExtraLarge:
      return TodayFocusLayoutSpec(
        padding: 13,
        sectionSpacing: 7,
        itemSpacing: 6,
        rowSpacing: 8,
        titleFontSize: 15,
        subtitleFontSize: 12,
        labelFontSize: 11,
        valueFontSize: 13,
        accentHeight: 24
      )
    default:
      return TodayFocusLayoutSpec(
        padding: 12,
        sectionSpacing: 6,
        itemSpacing: 5,
        rowSpacing: 8,
        titleFontSize: 13,
        subtitleFontSize: 10,
        labelFontSize: 10,
        valueFontSize: 12,
        accentHeight: 22
      )
    }
  }

  private func colorFromArgb(_ argb: Int) -> Color {
    let red = Double((argb >> 16) & 0xFF) / 255.0
    let green = Double((argb >> 8) & 0xFF) / 255.0
    let blue = Double(argb & 0xFF) / 255.0
    return Color(red: red, green: green, blue: blue)
  }
}

private struct TodayFocusLayoutSpec {
  let padding: CGFloat
  let sectionSpacing: CGFloat
  let itemSpacing: CGFloat
  let rowSpacing: CGFloat
  let titleFontSize: CGFloat
  let subtitleFontSize: CGFloat
  let labelFontSize: CGFloat
  let valueFontSize: CGFloat
  let accentHeight: CGFloat
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
