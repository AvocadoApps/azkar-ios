import SwiftUI
import WidgetKit
import Entities

@available(iOS 17, *)
private struct TintAwareCategoryQuickAccessWidgetView: View {
    let entry: CategoryQuickAccessWidgetEntry
    let widgetFamily: WidgetFamily

    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        CategoryQuickAccessWidgetContentView(
            entry: entry,
            widgetFamily: widgetFamily,
            useSFSymbols: renderingMode != .fullColor
        )
    }
}

@available(iOS 16, *)
struct CategoryQuickAccessWidgetView: View {
    let entry: CategoryQuickAccessWidgetEntry

    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        if #available(iOS 17, *) {
            TintAwareCategoryQuickAccessWidgetView(entry: entry, widgetFamily: widgetFamily)
        } else {
            CategoryQuickAccessWidgetContentView(entry: entry, widgetFamily: widgetFamily, useSFSymbols: false)
        }
    }
}

@available(iOS 16, *)
private struct CategoryQuickAccessWidgetContentView: View {
    let entry: CategoryQuickAccessWidgetEntry
    let widgetFamily: WidgetFamily
    let useSFSymbols: Bool

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            smallWidget
        default:
            mediumWidget
        }
    }

    private var smallWidget: some View {
        let currentCategory = contextualCategory(for: entry.date)

        return HStack(spacing: 6) {
            compactCategoryCell(category: .morning, completionFlag: .morning, isContextual: currentCategory == .morning)
            compactCategoryCell(category: .evening, completionFlag: .evening, isContextual: currentCategory == .evening)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var mediumWidget: some View {
        let categories: [(ZikrCategory, CompletionState?)] = [
            (.morning, .morning),
            (.evening, .evening),
            (.night, .night),
            (.afterSalah, nil),
        ]
        let currentCategory = contextualCategory(for: entry.date)

        return VStack(spacing: 6) {
            HStack(spacing: 6) {
                categoryCell(category: categories[0].0, completionFlag: categories[0].1, isContextual: currentCategory == categories[0].0)
                categoryCell(category: categories[1].0, completionFlag: categories[1].1, isContextual: currentCategory == categories[1].0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 6) {
                categoryCell(category: categories[2].0, completionFlag: categories[2].1, isContextual: currentCategory == categories[2].0)
                categoryCell(category: categories[3].0, completionFlag: categories[3].1, isContextual: currentCategory == categories[3].0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func categoryCell(category: ZikrCategory, completionFlag: CompletionState?, isContextual: Bool) -> some View {
        let isCompleted = completionFlag.map { entry.completionState.contains($0) } ?? false
        let palette = CategoryQuickAccessWidgetPalette.palette(for: category)

        return Link(destination: WidgetCategoryMetadata.deepLinkURL(for: category)) {
            VStack(spacing: 3) {
                Spacer(minLength: 0)

                categoryIcon(for: category, size: 30)
                    .opacity(isCompleted ? 0.45 : 1.0)
                    .shadow(color: isContextual ? palette.tint.opacity(0.25) : .clear, radius: 4, y: 2)

                HStack(spacing: 2) {
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(palette.tint)
                    }

                    Text(LocalizedStringKey(WidgetCategoryMetadata.metadata(for: category).titleKey))
                        .font(.caption2.weight(.medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .foregroundStyle(isCompleted ? .secondary : .primary)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(cellFill(palette: palette, isContextual: isContextual, isCompleted: isCompleted))
            )
            .contentShape(Rectangle())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func compactCategoryCell(category: ZikrCategory, completionFlag: CompletionState?, isContextual: Bool) -> some View {
        let isCompleted = completionFlag.map { entry.completionState.contains($0) } ?? false
        let palette = CategoryQuickAccessWidgetPalette.palette(for: category)

        return Link(destination: WidgetCategoryMetadata.deepLinkURL(for: category)) {
            VStack(spacing: 4) {
                Spacer(minLength: 0)

                categoryIcon(for: category, size: 34)
                    .opacity(isCompleted ? 0.45 : 1.0)
                    .shadow(color: isContextual ? palette.tint.opacity(0.25) : .clear, radius: 4, y: 2)

                HStack(spacing: 2) {
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(palette.tint)
                    }

                    Text(LocalizedStringKey(WidgetCategoryMetadata.metadata(for: category).titleKey))
                        .font(.caption2.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
                .foregroundStyle(isCompleted ? .secondary : .primary)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(cellFill(palette: palette, isContextual: isContextual, isCompleted: isCompleted))
            )
            .contentShape(Rectangle())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func categoryIcon(for category: ZikrCategory, size: CGFloat) -> some View {
        let metadata = WidgetCategoryMetadata.metadata(for: category)
        if useSFSymbols, let sfSymbol = metadata.sfSymbolName {
            Image(systemName: sfSymbol)
                .font(.system(size: size * 0.6, weight: .medium))
                .frame(width: size, height: size)
        } else {
            Image(metadata.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        }
    }

    private func cellFill(palette: CategoryQuickAccessWidgetPalette, isContextual: Bool, isCompleted: Bool) -> Color {
        if isContextual && !isCompleted {
            return palette.tint.opacity(palette.contextualFillOpacity)
        }

        if isCompleted {
            return Color(.systemGray5).opacity(0.5)
        }

        return Color(.secondarySystemBackground).opacity(0.5)
    }
}
