import SwiftUI
import Combine
import Extensions
import FactoryKit
import Library

extension ContentSizeCategory: @retroactive Comparable {}

extension EnvironmentValues {
    struct Diff: OptionSet {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let colorScheme = Diff(rawValue: 1 << 1)
        public static let dynamicTypeSize = Diff(rawValue: 1 << 2)
        public static let fontSizeCategory = Diff(rawValue: 1 << 3)
        public static let translationFont = Diff(rawValue: 1 << 4)
        public static let arabicFont = Diff(rawValue: 1 << 5)
    }
}

extension View {
    func attachEnvironmentOverrides(viewModel: EnvironmentOverridesViewModel = .init(), onChange: ((EnvironmentValues.Diff) -> Void)? = nil) -> some View {
        modifier(EnvironmentOverridesModifier(viewModel: viewModel, onChange: onChange))
    }
}

final class EnvironmentOverridesViewModel: ObservableObject {
    @Injected(\.preferences) var preferences: Preferences
    var objectWillChange = PassthroughSubject<Void, Never>()

    private var cancellabels = Set<AnyCancellable>()

    init() {
        preferences
            .storageChangesPublisher()
            .receive(on: RunLoop.main)
            .subscribe(objectWillChange)
            .store(in: &cancellabels)
    }
}

struct EnvironmentOverridesModifier: ViewModifier {

    @ObservedObject var viewModel: EnvironmentOverridesViewModel

    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @State private var previousDynamicTypeSize: DynamicTypeSize?
    
    @Environment(\.sizeCategory) private var defaultSizeCategory: ContentSizeCategory
    @State private var previousFontSizeCategory: ContentSizeCategory?
    
    @State private var previousTranslationFont: TranslationFont?
    @State private var previousArabicFont: ArabicFont?
    
    let onChange: ((EnvironmentValues.Diff) -> Void)?
    
    func body(content: Content) -> some View {
        content
            .onAppear { self.copyDefaultSettings() }
            .environment(\.fontSizeCategory, contentSizeCategory)
            .environment(\.dynamicTypeSize, dynamicTypeSize)
            .onChange(of: contentSizeCategory) { newValue in
                if previousFontSizeCategory != newValue {
                    onChange?(.fontSizeCategory)
                    previousFontSizeCategory = newValue
                }
            }
            .onChange(of: dynamicTypeSize) { newValue in
                if previousDynamicTypeSize != newValue {
                    onChange?(.dynamicTypeSize)
                    previousDynamicTypeSize = newValue
                }
            }
            .onChange(of: viewModel.preferences.preferredTranslationFont) { newValue in
                if previousTranslationFont != newValue {
                    onChange?(.translationFont)
                    previousTranslationFont = newValue
                }
            }
            .onChange(of: viewModel.preferences.preferredArabicFont) { newValue in
                if previousArabicFont != newValue {
                    onChange?(.arabicFont)
                    previousArabicFont = newValue
                }
            }
    }

    private var contentSizeCategory: ContentSizeCategory? {
        guard viewModel.preferences.useSystemFontSize == false else {
            return nil
        }
        return viewModel.preferences.sizeCategory
    }
    
    private func copyDefaultSettings() {
        previousFontSizeCategory = contentSizeCategory
        previousDynamicTypeSize = dynamicTypeSize
    }
    
}
