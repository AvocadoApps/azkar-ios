// Copyright © 2025 Azkar
// All Rights Reserved.

import SwiftUI

public struct PickerMenu<T: Identifiable & Hashable>: View {
    let title: LocalizedStringKey
    @Binding var selection: T
    let items: [T]
    let itemTitle: (T) -> String
    let isItemEnabled: (T) -> Bool
    let itemAccessory: (T) -> PickerMenuAccessory?
    let labelPrefixAccessory: PickerMenuAccessory?
    let labelAccessory: PickerMenuAccessory?
    
    public init(
        title: LocalizedStringKey,
        selection: Binding<T>,
        items: [T],
        itemTitle: @escaping (T) -> String,
        isItemEnabled: @escaping (T) -> Bool = { _ in true },
        itemAccessory: @escaping (T) -> PickerMenuAccessory? = { _ in nil },
        labelPrefixAccessory: PickerMenuAccessory? = nil,
        labelAccessory: PickerMenuAccessory? = nil
    ) {
        self.title = title
        self._selection = selection
        self.items = items
        self.itemTitle = itemTitle
        self.isItemEnabled = isItemEnabled
        self.itemAccessory = itemAccessory
        self.labelPrefixAccessory = labelPrefixAccessory
        self.labelAccessory = labelAccessory
    }
    
    public var body: some View {
        HStack {
            Text(title)
                .systemFont(.body)
                .foregroundStyle(.text)
                .multilineTextAlignment(.leading)
                .layoutPriority(1)
            Spacer()

            Menu {
                ForEach(items, id: \.self) { item in
                    let enabled = isItemEnabled(item)
                    Button {
                        guard enabled else { return }
                        selection = item
                    } label: {
                        HStack(spacing: 8) {
                            Text(itemTitle(item))
                                .systemFont(.callout)
                            if let accessoryView = itemAccessory(item)?.view {
                                accessoryView
                            }
                            if selection == item {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.accent)
                            }
                        }
                    }
                    .disabled(!enabled)
                }
            } label: {
                HStack {
                    if let labelPrefixAccessory = labelPrefixAccessory?.view {
                        labelPrefixAccessory
                    }

                    Text(itemTitle(selection))
                        .systemFont(.callout)
                        .foregroundStyle(.secondaryText)
                        .multilineTextAlignment(.trailing)
                    
                    chevronAccessory
                        .opacity(labelAccessory == nil ? 1 : 0)
                        .overlay {
                            Group {
                                if let labelAccessory = labelAccessory?.view {
                                    labelAccessory
                                }
                            }
                        }
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var chevronAccessory: some View {
        Image(systemName: "chevron.down")
            .foregroundStyle(.secondaryText)
    }

}

public enum PickerMenuAccessory {
    case image(systemName: String, tint: Color? = nil)
    case progress(progress: Double? = nil, tint: Color? = nil)
    
    @ViewBuilder
    var view: some View {
        switch self {
        case .image(let systemName, let tint):
            Image(systemName: systemName)
                .foregroundStyle(tint ?? .primary)
        case .progress(let progress, let tint):
            if let progress = progress {
                ProgressView(value: progress)
                    .progressViewStyle(CircularProgressViewStyle(tint: tint ?? Color.accentColor))
                    .scaleEffect(0.75)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: tint ?? Color.accentColor))
                    .scaleEffect(0.75)
            }
        }
    }
}

@available(iOS 17, *)
#Preview {
    struct PreviewModel: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let needsDownload: Bool
        let isDownloading: Bool
        
        static let samples = [
            PreviewModel(name: "Option 1", needsDownload: false, isDownloading: false),
            PreviewModel(name: "Option 2", needsDownload: true, isDownloading: false),
            PreviewModel(name: "Option 3", needsDownload: false, isDownloading: true)
        ]
    }
    
    @Previewable @State var selected = PreviewModel.samples[0]
    
    return VStack(spacing: 20) {
        PickerMenu(
            title: "Basic picker",
            selection: $selected,
            items: PreviewModel.samples,
            itemTitle: { $0.name }
        )
        
        PickerMenu(
            title: "With accessories",
            selection: $selected,
            items: PreviewModel.samples,
            itemTitle: { $0.name },
            itemAccessory: { item in
                if item.isDownloading {
                    return PickerMenuAccessory.progress(tint: .blue)
                }
                if item.needsDownload {
                    return PickerMenuAccessory.image(systemName: "arrow.down.circle", tint: .blue)
                }
                return nil
            }
        )
        
        PickerMenu(
            title: "With label accessory",
            selection: $selected,
            items: PreviewModel.samples,
            itemTitle: { $0.name },
            labelAccessory: PickerMenuAccessory.image(systemName: "star.fill", tint: .yellow)
        )
    }
    .padding()
}
