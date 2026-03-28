import SwiftUI
import NukeUI
import Entities
import Library
import AzkarResources
import Extensions

public struct ArticleScreen: View {
    
    @ObservedObject var viewModel: ArticleViewModel
    var shareOptions: ShareOptions?
    let onShareButtonTap: () -> Void
    @Environment(\.appTheme) var appTheme
    
    public struct ShareOptions {
        let maxWidth: CGFloat
        
        public init(maxWidth: CGFloat) {
            self.maxWidth = maxWidth
        }
    }
    
    public init(
        viewModel: ArticleViewModel,
        shareOptions: ShareOptions? = nil,
        onShareButtonTap: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.shareOptions = shareOptions
        self.onShareButtonTap = onShareButtonTap
    }
    
    private let minHeight = 175.0
    private var maxHeight: CGFloat {
        if viewModel.coverImage?.imageFormat == .titleBackground {
            return 250
        } else {
            return 200
        }
    }
    
    public var body: some View {
        if let shareOptions {
            VStack(spacing: 20) {
                content
                sharedWithAzkarView
            }
            .frame(width: shareOptions.maxWidth)
            .frame(maxHeight: .infinity)
        } else {
            content
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem {
                        shareButton
                    }
                }
        }
    }
    
    @MainActor @ViewBuilder
    public var content: some View {
        ScrollView {
            VStack(spacing: 16) {
                if shareOptions == nil {
                    headerView
                    scrollableContent
                } else {
                    Text(viewModel.title)
                        .customFont(.title1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .dynamicTypeSize(.accessibility5)
                        .padding(.horizontal)
                        .applyAccessibilityLanguage(viewModel.language.id)
                        .accessibilityAddTraits(.isHeader)
                    
                    scrollableContent
                }
            }
        }
        .customScrollContentBackground()
        .background(.background, ignoreSafeArea: .all)
    }
    
    var sharedWithAzkarView: some View {
        VStack {
            Image(uiImage: UIImage(named: "ink", in: azkarResourcesBundle, compatibleWith: nil)!)
                .resizable()
                .frame(width: 30, height: 30)
                .cornerRadius(6)
            Text("share.shared-with-azkar")
                .foregroundStyle(Color.secondary)
                .systemFont(12, modification: .smallCaps)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .frame(height: 45)
        .opacity(0.5)
    }
    
    var shareButton: some View {
        Button(action: onShareButtonTap, label: {
            Image(systemName: "square.and.arrow.up")
        })
        .accessibilityLabel(Text("common.share"))
    }
    
    var headerView: some View {
        ArticleHeaderView(
            title: viewModel.title,
            language: viewModel.language.id,
            tags: viewModel.tags,
            cover: viewModel.coverImage,
            coverAltText: viewModel.coverImageAltText,
            views: viewModel.views,
            viewsAbbreviated: viewModel.viewsAbbreviated,
            shares: viewModel.shares,
            sharesAbbreviated: viewModel.sharesAbbreviated,
            imageMaxHeight: maxHeight
        )
        .removeSaturationIfNeeded()
    }
    
    var scrollableContent: some View {
        VStack(spacing: 0) {
            textContent
            
            Color.clear.frame(height: 100)
        }
        .padding(.horizontal)
    }
    
    var textContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStringKey(viewModel.text))
                .customFont(.title3)
                .applyAccessibilityLanguage(viewModel.language.id)
        }
        .frame(maxWidth: .infinity)
    }
    
}

private func getDemoVM(
    _ coverImageFormat: Article.CoverImageFormat,
    _ imageLink: URL
) -> ArticleViewModel {
    return ArticleViewModel(
        article: .placeholder(
            imageLink: imageLink.absoluteString,
            coverImageFormat: coverImageFormat
        ),
        analyticsStream: { AsyncStream { _ in } },
        updateAnalytics: { _ in },
        fetchArticle: { return nil }
    )
}

let demoImageURL = URL(string: "https://storage.yandexcloud.net/azkar/post-covers/2_zikru_llahi")!

private struct ArticleScreenPreview: View {
    let viewModel: ArticleViewModel
    var body: some View {
        NavigationView {
            ArticleScreen(viewModel: viewModel)
        }
    }
}

#Preview("Background Image") {
    ArticleScreenPreview(viewModel: getDemoVM(.titleBackground, demoImageURL))
}

#Preview("Standalone Cover") {
    ArticleScreenPreview(viewModel: getDemoVM(.standaloneTop, demoImageURL))
}

#Preview("Standalone Under Title Cover") {
    ArticleScreenPreview(viewModel: getDemoVM(.standaloneUnderTitle, demoImageURL))
}

#Preview("No Image") {
    ArticleScreenPreview(
        viewModel: .init(
            article: .placeholder(),
            analyticsStream: { AsyncStream { _ in } },
            updateAnalytics: { _ in },
            fetchArticle: { return nil }
        )
    )
}
