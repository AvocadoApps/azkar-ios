import SwiftUI
import FactoryKit
import Library
import Entities
import DatabaseInteractors

struct ReminderTitlePickerScreen: View {

    @Injected(\.preferences) private var preferences: Preferences

    private enum Mode: Identifiable, Hashable {
        case `default`
        case random
        case pickQuote

        var id: Self { self }
    }

    let info: ReminderTitlePickerInfo
    private let quotes: [NotificationQuote]

    @State private var selection: ReminderTitleSelection
    @State private var showingQuoteSheet = false
    /// A random quote shown in the preview while `.random` is selected.
    @State private var randomPreviewQuote: NotificationQuote?

    init(info: ReminderTitlePickerInfo) {
        self.info = info
        let preferences = Container.shared.preferences()
        let db = AzkarDatabase(language: preferences.contentLanguage)
        let quotes = (try? db.getNotificationQuotes(category: Self.quoteCategory(for: info.type))) ?? []
        self.quotes = quotes
        _selection = State(initialValue: info.selection)
        _randomPreviewQuote = State(initialValue: info.selection == .random ? quotes.randomElement() : nil)
    }

    private static func quoteCategory(for type: ReminderTitlePickerType) -> NotificationQuoteCategory {
        switch type {
        case .morning, .evening:
            return .adhkar
        case .jumua:
            return .jumua
        }
    }

    private static func notificationCategory(for type: ReminderTitlePickerType) -> NotificationCategory {
        switch type {
        case .morning:
            return .morning
        case .evening:
            return .evening
        case .jumua:
            return .jumua
        }
    }

    private var selectedQuote: NotificationQuote? {
        guard case let .quote(id) = selection else { return nil }
        return quotes.first(where: { $0.id == id })
    }

    private func quoteBody(_ quote: NotificationQuote) -> String {
        if let source = quote.source, !source.isEmpty {
            return "\(quote.text) (\(source))"
        }
        return quote.text
    }

    // MARK: - Top menu

    private let modes: [Mode] = [.default, .random, .pickQuote]

    private func isSelected(_ mode: Mode) -> Bool {
        switch (mode, selection) {
        case (.default, .default), (.random, .random):
            return true
        case (.pickQuote, .quote):
            return true
        default:
            return false
        }
    }

    private func title(for mode: Mode) -> String {
        switch mode {
        case .default:
            return String(localized: "common.default")
        case .random:
            return String(localized: "common.random")
        case .pickQuote:
            return String(localized: "settings.reminders.title.pick-quote")
        }
    }

    private func subtitle(for mode: Mode) -> String? {
        switch mode {
        case .default:
            return String(localized: "settings.reminders.title.default-subtitle")
        case .random:
            return String(localized: "settings.reminders.title.random-subtitle")
        case .pickQuote:
            return String(localized: "settings.reminders.title.pick-quote-subtitle")
        }
    }

    private func handleTap(_ mode: Mode) {
        switch mode {
        case .default:
            apply(.default)
        case .random:
            randomPreviewQuote = quotes.randomElement()
            apply(.random)
        case .pickQuote:
            showingQuoteSheet = true
        }
    }

    private func apply(_ newSelection: ReminderTitleSelection) {
        selection = newSelection
        switch info.type {
        case .morning:
            preferences.morningReminderTitle = newSelection
        case .evening:
            preferences.eveningReminderTitle = newSelection
        case .jumua:
            preferences.jumuaReminderTitle = newSelection
        }
    }

    private var menu: some View {
        VStack(spacing: 0) {
            ForEachIndexed(modes) { _, position, mode in
                modeRow(mode)
                if position != .last {
                    Divider()
                }
            }
        }
        .applyContainerStyle()
    }

    private func modeRow(_ mode: Mode) -> some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            handleTap(mode)
        } label: {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title(for: mode))
                        .systemFont(.body)
                        .multilineTextAlignment(.leading)

                    if let subtitle = subtitle(for: mode) {
                        Text(subtitle)
                            .systemFont(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(.vertical, 8)

                Spacer(minLength: 0)

                CheckboxView(isChecked: .constant(isSelected(mode)))
                    .frame(width: 20, height: 20)

                if mode == .pickQuote {
                    Image(systemName: "chevron.right")
                        .systemFont(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.text)
    }

    // MARK: - Quote sheet

    private func isQuoteSelected(_ quote: NotificationQuote) -> Bool {
        if case let .quote(id) = selection {
            return id == quote.id
        }
        return false
    }

    private func quoteRow(_ quote: NotificationQuote) -> some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            apply(.quote(id: quote.id))
            showingQuoteSheet = false
        } label: {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(quote.text)
                        .systemFont(.body)
                        .multilineTextAlignment(.leading)

                    if let source = quote.source {
                        Text(source)
                            .systemFont(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(.vertical, 8)

                Spacer(minLength: 0)

                CheckboxView(isChecked: .constant(isQuoteSelected(quote)))
                    .frame(width: 20, height: 20)
            }
            .contentShape(Rectangle())
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.text)
    }

    private var quoteSheet: some View {
        NavigationView {
            Group {
                if quotes.isEmpty {
                    Text("settings.reminders.title.no-quotes")
                        .systemFont(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEachIndexed(quotes) { _, position, quote in
                                quoteRow(quote)
                                if position != .last {
                                    Divider()
                                }
                            }
                        }
                        .applyContainerStyle()
                    }
                    .customScrollContentBackground()
                }
            }
            .background(.background, ignoreSafeArea: .all)
            .navigationTitle("settings.reminders.title.pick-quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("common.cancel")) {
                        showingQuoteSheet = false
                    }
                }
            }
        }
        .reminderQuoteSheetDetents()
    }

    // MARK: - Preview

    private var previewTitle: String {
        switch selection {
        case .default:
            return Self.notificationCategory(for: info.type).defaultNotificationTitle
        case .random, .quote:
            return String(localized: "app-name")
        }
    }

    private var previewBody: String? {
        switch selection {
        case .default:
            return nil
        case .random:
            return randomPreviewQuote.map(quoteBody)
        case .quote:
            return selectedQuote.map(quoteBody)
        }
    }

    /// Identity of the currently displayed preview content, so the transition
    /// also runs when the random quote re-rolls (selection stays `.random`).
    private var previewIdentity: String {
        "\(previewTitle)|\(previewBody ?? "")"
    }

    var preview: some View {
        VStack {
            Divider()

            ReminderNotificationPreview(
                title: previewTitle,
                bodyText: previewBody,
                appIcon: preferences.appIcon
            )
        }
        .background(.background)
    }

    var body: some View {
        ScrollView {
            menu

            preview
                .opacity(0)
        }
        .overlay(alignment: .bottom) {
            preview
                .id(previewIdentity)
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.97, anchor: .bottom)),
                        removal: .opacity
                    )
                )
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: previewIdentity)
        .customScrollContentBackground()
        .background(.background, ignoreSafeArea: .all)
        .navigationTitle("settings.reminders.title.section")
        .sheet(isPresented: $showingQuoteSheet) {
            quoteSheet
        }
        .onAppear {
            AnalyticsReporter.reportScreen("Settings", className: viewName)
        }
    }
}

private extension View {
    @ViewBuilder
    func reminderQuoteSheetDetents() -> some View {
        if #available(iOS 16.0, *) {
            self.presentationDetents([.medium, .large])
        } else {
            self
        }
    }
}

private struct ReminderNotificationPreview: View {

    let title: String
    let bodyText: String?
    let appIcon: AppIcon

    /// The system's localized "now", as shown on a just-delivered notification.
    private static let nowLabel: String = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(fromTimeInterval: 0)
    }()

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            iconImage

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)

                if let bodyText {
                    Text(bodyText)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(4)
                }
            }

            Spacer()

            Text(verbatim: Self.nowLabel)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.14), radius: 12, x: 0, y: 6)
        .padding(.horizontal)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var iconImage: some View {
        if let image = UIImage(named: appIcon.iconImageName, in: resourcesBundle, compatibleWith: nil) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 20, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 4.5, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                .fill(Color.accentColor)
                .frame(width: 20, height: 20)
        }
    }
}
