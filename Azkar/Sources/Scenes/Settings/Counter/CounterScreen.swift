import SwiftUI
import Popovers
import Library
import Entities
import AzkarResources

struct CounterView: View {
    
    @ObservedObject var viewModel: CounterViewModel
    
    var body: some View {
        ScrollView {
            VStack {
                content
            }
            .applyContainerStyle()
        }
        .applyThemedToggleStyle()
        .customScrollContentBackground()
        .background(.background, ignoreSafeArea: .all)
        .navigationTitle("settings.counter.title")
        .animation(.smooth, value: viewModel.preferences.counterType)
    }
    
    var content: some View {
        Group {
            typePicker
            
            Divider()
            
            if viewModel.preferences.counterType == .floatingButton {
                HStack {
                    Text("settings.counter.counter-size.title")
                    Spacer()
                    Picker(
                        CounterSize.allCases,
                        id: \.self,
                        selection: $viewModel.preferences.counterSize,
                        content: { size in
                            Text(size.title)
                        }
                    )
                    .pickerStyle(.segmented)
                }
                
                Divider()
                
                HStack {
                    Text("settings.counter.counter-position.title")
                    Spacer()
                    Picker(
                        CounterPosition.allCases,
                        id: \.self,
                        selection: $viewModel.preferences.counterPosition,
                        content: { size in
                            Text(size.title)
                        }
                    )
                    .pickerStyle(.segmented)
                }
                
                Divider()
            }

            Toggle("settings.counter.counter-ticker", isOn: $viewModel.preferences.enableCounterTicker)
                .padding(.vertical, 3)

            Divider()
            
            Toggle("settings.counter.counter-haptics", isOn: $viewModel.preferences.enableCounterHapticFeedback)
                .padding(.vertical, 3)

            Divider()
            
            pageIndicatorsSection

            Divider()

            Toggle(isOn: $viewModel.preferences.enableGoToNextZikrOnCounterFinished) {
                HStack {
                    Text("settings.counter.go-to-next-dhikr")

                    Spacer()

                    Templates.Menu {
                        Text("settings.counter.go-to-next-dhikr-tip")
                            .padding()
                            .cornerRadius(10)
                            .foregroundStyle(.text)
                    } label: { _ in
                        Image(systemName: "info.circle")
                            .foregroundStyle(.accent, opacity: 0.75)
                    }
                }
                .padding(.vertical, 3)
            }
        }
        .systemFont(.body)
        .foregroundStyle(.text)
        .onAppear {
            AnalyticsReporter.reportScreen("Settings", className: viewName)
        }
    }
    
    private var pageIndicatorsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("settings.counter.page-indicators")
                Spacer()
                Picker(
                    PageIndicatorsMode.allCases,
                    id: \.self,
                    selection: $viewModel.preferences.pageIndicatorsMode,
                    content: { mode in
                        Text(mode.title)
                    }
                )
                .pickerStyle(.segmented)
                .fixedSize()
            }

            if viewModel.preferences.pageIndicatorsMode == .custom {
                FlowLayout(spacing: 8) {
                    ForEach(ZikrCategory.allCases.filter { $0 != .other }) { category in
                        categoryChip(category)
                    }
                }
            }
        }
        .padding(.vertical, 3)
        .animation(.smooth, value: viewModel.preferences.pageIndicatorsMode)
    }

    private func categoryChip(_ category: ZikrCategory) -> some View {
        let isSelected = viewModel.preferences.pageIndicatorsCategories.contains(category)
        let fillColor: Color = isSelected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1)
        let borderColor: Color = isSelected ? Color.accentColor : Color.clear
        let foregroundColor: Color = isSelected ? Color.accentColor : Color.secondary

        return Button {
            var categories = viewModel.preferences.pageIndicatorsCategories
            if isSelected {
                categories.remove(category)
            } else {
                categories.insert(category)
            }
            viewModel.preferences.pageIndicatorsCategories = categories
        } label: {
            HStack(spacing: 6) {
                Image(category.widgetImageName, bundle: azkarResourcesBundle)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 15, height: 15)
                Text(category.title)
                    .systemFont(.footnote)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: 150)
            .foregroundColor(foregroundColor)
            .background(RoundedRectangle(cornerRadius: 16).fill(fillColor))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(borderColor, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    private var typePicker: some View {
        HStack {
            Text("settings.counter.counter-type.title")
            Spacer()

            Templates.Menu {
                Text("settings.counter.counter-type.info")
                    .padding()
                    .cornerRadius(10)
            } label: { _ in
                Image(systemName: "info.circle")
                    .foregroundStyle(.accent, opacity: 0.75)
            }

            Picker(
                CounterType.allCases,
                id: \.self,
                selection: $viewModel.preferences.counterType,
                content: { type in
                    Text(type.title)
                }
            )
            .pickerStyle(.segmented)
        }
        .padding(.vertical, 3)
    }
    
}

private struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    init(spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            FlowLayoutImpl(spacing: spacing) {
                content
            }
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: spacing)], spacing: spacing) {
                content
            }
        }
    }
}

@available(iOS 16.0, *)
private struct FlowLayoutImpl: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalSize: CGSize = .zero

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalSize.width = max(totalSize.width, x - spacing)
            totalSize.height = max(totalSize.height, y + rowHeight)
        }

        return (positions, totalSize)
    }
}

#Preview {
    CounterView(
        viewModel: CounterViewModel(
            navigator: EmptySettingsNavigator()
        )
    )
}
