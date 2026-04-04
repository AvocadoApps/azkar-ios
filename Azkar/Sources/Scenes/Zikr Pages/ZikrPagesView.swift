import SwiftUI
import AudioPlayer
import Combine
import SwiftUIX
import Extensions
import Library
import WidgetKit

struct ZikrPagesView: View, Equatable {

    static func == (lhs: ZikrPagesView, rhs: ZikrPagesView) -> Bool {
        lhs.viewModel.title == rhs.viewModel.title && lhs.viewModel.page == rhs.viewModel.page
    }

    @ObservedObject var viewModel: ZikrPagesViewModel
    @State var readingMode: ZikrReadingMode?

    @Namespace private var pageSelectionNamespace
    @State private var scrollProxy: ScrollViewProxy?
    
    @Environment(\.appTheme) var appTheme
    @Environment(\.colorTheme) var colorTheme

    private let pageIndicatorHeight: CGFloat = 50

    private var selectablePageIndices: Range<Int> {
        viewModel.pages.indices.dropLast()
    }

    var showPageIndicators = false

    var body: some View {
        VStack(spacing: 8) {
            pagerView
            if showPageIndicators {
                bottomPageOverlay
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                if let page = viewModel.pages[safe: viewModel.page], page != .readingCompletion {
                    HStack {
                        Button(systemImage: .squareAndArrowUp, action: viewModel.shareCurrentZikr)
                            .accessibilityLabel(Text("common.share"))
                        Button(systemImage: .textformat, action: viewModel.navigateToTextSettings)
                            .accessibilityLabel(Text("settings.text.title"))
                    }
                }
            }
        }
        .background(.background, ignoreSafeArea: .all)
        .onAppear {
            AnalyticsReporter.reportScreen("Azkar Pages", className: viewName)
        }
    }
    
    var pagerView: some View {
        PaginationView(
            axis: .horizontal,
            transitionStyle: .scroll,
            showsIndicators: false
        ) {
            ForEach(viewModel.pages) { pageType in
                switch pageType {
                case .zikr(let zikr):
                    ZikrView(
                        viewModel: zikr,
                        counterFinishedCallback: viewModel.goToNextZikrIfNeeded,
                        counterTapCallback: viewModel.onCounterTapped
                    )
                case .readingCompletion:
                    ReadingCompletionView(
                        isCompleted: !viewModel.hasRemainingRepeats,
                        hasUncompletedAzkar: viewModel.hasUncompletedAzkar,
                        markAsCompleted: {
                            await viewModel.markCurrentCategoryAsCompleted()
                            WidgetCenter.reloadAzkarWidgets()
                        },
                        goToFirstUncompleted: viewModel.goToFirstUncompletedZikr
                    )
                }
            }
        }
        .initialPageIndex(viewModel.initialPage)
        .currentPageIndex($viewModel.page.animation(.spring))
        .edgesIgnoringSafeArea(.bottom)
        .environment(\.zikrReadingMode, readingMode ?? viewModel.preferences.zikrReadingMode)
        .onReceive(viewModel.preferences.$zikrReadingMode) { newMode in
            readingMode = newMode
        }
    }

    var bottomPageOverlay: some View {
        GeometryReader { geo in
            PagesPreviewView(
                selectedPage: $viewModel.page,
                pageCount: viewModel.pages.count - 1,
                height: pageIndicatorHeight,
                spacing: 4,
                safeAreaBottom: geo.safeAreaInsets.bottom,
                indicatorView: { idx, isSelected in
                    pageIndicator(index: idx, isSelected: isSelected)
                }
            )
            .edgesIgnoringSafeArea(.bottom)
        }
        .opacity(viewModel.page < viewModel.pages.count - 1 ? 1 : 0)
        .frame(maxHeight: pageIndicatorHeight + 8)
        .allowsHitTesting(true)
    }
    
    @ViewBuilder private func pageIndicator(index: Int, isSelected: Bool) -> some View {
        let viewModel = self.viewModel.azkar[index]
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? colorTheme.getColor(.accent) : colorTheme.getColor(.contentBackground))
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
            VStack(spacing: 0) {
                Text("\(index + 1)")
                    .font(.caption)
                let remainingRepeatsNumber = viewModel.remainingRepeatsNumber ?? 0
                if remainingRepeatsNumber == 0 {
                    Text("✓")
                        .font(.caption2)
                }
            }
            .foregroundColor(isSelected ? Color.white : colorTheme.getColor(.tertiaryText))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .minimumScaleFactor(0.15)
        }
        .glassEffectCompat(.clear, in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: String(localized: "common.dhikr"), locale: Locale.current, String(index + 1)))
        .accessibilityValue(pageIndicatorAccessibilityValue(for: viewModel))
    }

    private func pageIndicatorAccessibilityValue(for viewModel: ZikrViewModel) -> String {
        guard let remainingRepeatsNumber = viewModel.remainingRepeatsNumber else {
            return ""
        }

        if remainingRepeatsNumber == 0 {
            return String(localized: "remaining-repeats.completed")
        }

        return String(format: String(localized: "remaining-repeats"), locale: Locale.current, remainingRepeatsNumber)
    }

}

#Preview("ZikrPages") {
    NavigationView {
        ZikrPagesView(viewModel: ZikrPagesViewModel.placeholder)
    }
}
