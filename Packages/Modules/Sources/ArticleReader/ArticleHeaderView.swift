import SwiftUI
import NukeUI
import Popovers
import Extensions
import Entities
import Library

extension Article.ImageType {
    @ViewBuilder @MainActor
    func getImageView(
        _ maxHeight: CGFloat = .infinity
    ) -> some View {
        switch self {
            
        case .link(let link):
            LazyImage(url: link) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .accentColor(Color.primary)
                } else if state.isLoading {
                    Color(.systemBackground)
                        .overlay {
                            ProgressView()
                        }
                } else {
                    PatternView()
                }
            }
            .frame(minWidth: 0, maxHeight: maxHeight)
            
        case .resource(let name):
            Image(name)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .accentColor(Color.primary)
                .frame(minWidth: 0, maxHeight: maxHeight)
            
        }
    }
}

struct ArticleHeaderView: View {
        
    let title: String
    let language: String?
    var tags: [String]?
    var cover: Article.CoverImage?
    var coverAltText: String?
    var views: Int?
    var viewsAbbreviated: String?
    var shares: Int?
    var sharesAbbreviated: String?
    
    let imageMaxHeight: CGFloat
    @State var showAltText = false
    @Environment(\.appTheme) var appTheme
    
    var body: some View {
        imageAndTitle
    }
    
    @MainActor @ViewBuilder
    var imageAndTitle: some View {
        if let imageFormat = cover?.imageFormat {
            switch imageFormat {
                
            case .standaloneTop:
                VStack(spacing: 0) {
                    standaloneImage
                    getTitleView()
                }
                
            case .standaloneUnderTitle:
                VStack(spacing: 0) {
                    getTitleView()
                    standaloneImage
                }
                
            case .titleBackground:
                titleWithBackgroundImage
                
            }
        } else {
            getTitleView(45)
        }
    }
    
    @ViewBuilder
    func getTitleView(
        _ fontSize: CGFloat = 30,
        lineLimit: Int = 3,
        tagsforegroundStyle: Color = Color.secondary
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Font.system(size: fontSize, weight: .black, design: .serif))
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .dynamicTypeSize(.accessibility5)
                .lineLimit(lineLimit)
                .minimumScaleFactor(0.25)
                .applyAccessibilityLanguage(language)
                .accessibilityAddTraits(.isHeader)
            
            if #available(iOS 16, *) {
                ScrollView(.horizontal) {
                    horizontalScrollViewContent(foregroundStyle: tagsforegroundStyle)
                }
                .scrollIndicators(.never)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    horizontalScrollViewContent(foregroundStyle: tagsforegroundStyle)
                }
            }
        }
        .padding()
    }
    
    func horizontalScrollViewContent(
        foregroundStyle: Color
    ) -> some View {
        HStack(alignment: .center, spacing: 8) {
            countView(
                views,
                abbreviatedNumber: viewsAbbreviated,
                image: "eye"
            )
            countView(
                shares,
                abbreviatedNumber: sharesAbbreviated,
                image: "square.and.arrow.up"
            )
            if tags != nil {
                Divider()
                    .frame(height: 10)
                tagsView
            }
        }
        .foregroundStyle(foregroundStyle)
    }
    
    @MainActor @ViewBuilder
    var standaloneImage: some View {
        image
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: appTheme.cornerRadius))
            .allowsHitTesting(false)
            .overlay(alignment: .topTrailing) {
                altTextView
            }
            .applyAccessibilityLabel(coverAltText)
            .padding()
    }
    
    @MainActor @ViewBuilder
    var image: some View {
        cover?.imageType.getImageView(imageMaxHeight)
    }
    
    @MainActor
    var titleWithBackgroundImage: some View {
        image
            .clipped()
            .overlay(alignment: .bottom) {
                getTitleView(
                    40,
                    lineLimit: 2,
                    tagsforegroundStyle: Color.white.opacity(0.55)
                )
                .foregroundStyle(Color.white)
                .padding(.vertical)
                .background(
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.75)],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
            }
            .overlay(alignment: .topTrailing) {
                altTextView
            }
            .applyAccessibilityLabel(coverAltText)
            .clipped()
    }
    
    @ViewBuilder
    var tagsView: some View {
        if let tags = tags {
            HStack {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .systemFont(.callout)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
    
    @ViewBuilder
    private func countView(
        _ number: Int?,
        abbreviatedNumber: String?,
        image: String
    ) -> some View {
        if let number, let abbreviatedNumber {
            ArticleStatsView(
                abbreviatedNumber: abbreviatedNumber,
                number: number,
                imageName: image
            )
        }
    }
        
    @ViewBuilder
    var altTextView: some View {
        if let coverAltText {
            Templates.Menu(
                configuration: { config in
                    config.popoverAnchor = .topRight
                }
            ) {
                Text(coverAltText)
                    .systemFont(.caption)
                    .padding()
                    .cornerRadius(10)
            } label: { das in
                Text("ALT")
                    .padding(6)
                    .foregroundStyle(Color.white)
                    .background(Color.black)
                    .systemFont(.caption, weight: .bold)
                    .cornerRadius(6)
                    .padding(8)
            }
        }
    }
    
}

#Preview("Background") {
    ArticleHeaderView(
        title: "Test title",
        language: nil,
        tags: ["#benefit", "#general", "#info"],
        cover: .init(
            imageType: .link(demoImageURL),
            imageFormat: .titleBackground
        ),
        coverAltText: "MidJourney Image",
        views: 1231,
        imageMaxHeight: 300
    )
}

#Preview("Standalone Top") {
    ArticleHeaderView(
        title: "Test",
        language: nil,
        tags: ["#benefit", "#general", "#info"],
        cover: .init(
            imageType: .link(demoImageURL),
            imageFormat: .standaloneTop
        ),
        coverAltText: "MidJourney Image",
        views: 1231,
        imageMaxHeight: 300
    )
}

#Preview("Standalone Under title") {
    ArticleHeaderView(
        title: "Test",
        language: nil,
        tags: ["#benefit", "#general", "#info"],
        cover: .init(
            imageType: .link(demoImageURL),
            imageFormat: .standaloneUnderTitle
        ),
        coverAltText: "man in black wear standing in the middle of an ice cold lake, in the style of stephan martinière, marina abramović, pictorial space, 32k uhd, alan bean, depictions of inclement weather, humanity's struggle",
        views: 1231,
        imageMaxHeight: 300
    )
}
