//  Copyright © 2020 Al Jawziyya. All rights reserved.

import UIKit
import SwiftUI
import Library
import AzkarResources

public struct AppInfoView: View {

    @ObservedObject var viewModel: AppInfoViewModel
    @Environment(\.openURL) private var openURL
    @Environment(\.appTheme) var appTheme
    @Environment(\.colorTheme) var colorTheme
    public init(viewModel: AppInfoViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            verticalStack
        }
        .overlay(alignment: .bottom) {
            copyrightView
        }
        .toolbar {
            ToolbarItem(placement: ToolbarItemPlacement.navigationBarTrailing) {
                if #available(iOS 16, *) {
                    ShareLink(item: URL(string: "https://apps.apple.com/app/id1511423586")!) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.accent)
                    }
                } else {
                    Button {
                        let url = URL(string: "https://apps.apple.com/app/id1511423586")!
                        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                        UIApplication.shared.connectedScenes
                            .compactMap { $0 as? UIWindowScene }
                            .flatMap { $0.windows }
                            .first { $0.isKeyWindow }?
                            .rootViewController?
                            .present(vc, animated: true)
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.accent)
                    }
                }
            }
        }
        .navigationTitle(Text("about.title", comment: "About app screen title."))
        .customScrollContentBackground()
        .background(.background, ignoreSafeArea: .all)
    }
    
    private var verticalStack: some View {
        LazyVStack(alignment: .center, spacing: 0) {
            self.iconAndVersion.background(
                colorTheme.getColor(.background).padding(-20)
            )
            .padding()
            
            links
                .applyContainerStyle()
            
            copyrightView.opacity(0)
        }
    }
    
    private var links: some View {
        VStack {
            outboundLinkButton(
                "credits.studio.telegram-channel",
                url: URL(string: "https://jawziyya.t.me")!,
                image: "paperplane",
                color: Color.blue
            )
            
            outboundLinkButton(
                "credits.studio.instagram-page",
                url: URL(string: "https://instagram.com/jawziyya.studio")!,
                image: "photo.stack",
                color: Color.orange
            )
            
            outboundLinkButton(
                "credits.studio.jawziyya-apps",
                url: URL(string: "https://apps.apple.com/developer/al-jawziyya/id1165327318")!,
                image: "apps.iphone",
                color: Color.indigo
            )
            
            NavigationLink {
                CreditsScreen(viewModel: CreditsViewModel())
            } label: {
                buttonLabel(
                    "credits.title",
                    image: "link",
                    color: Color.green,
                    navigationImage: "chevron.right"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var iconAndVersion: some View {
        VStack {
            HStack {
                Spacer()
                if let image = UIImage(named: viewModel.iconImageName, in: azkarResourcesBundle, compatibleWith: nil) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 1)
                        .id(viewModel.iconImageName)
                        .transition(.opacity)
                }
                Spacer()
            }

            HStack {
                Spacer()
                
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        HStack(spacing: 0) {
                            if appTheme == .code {
                                Text("~")
                            }
                            Text("app-name")
                        }
                        .systemFont(.title2, weight: .heavy, modification: .smallCaps)
                        .frame(alignment: .center)
                        .foregroundStyle(.accent)
                        if !UIDevice.current.isMac, viewModel.isProUser {
                            Text(" PRO")
                                .systemFont(.title2, weight: .heavy, modification: .smallCaps)
                                .foregroundStyle(Color.blue)
                        }
                    }
                    
                    if let onVersionTap = viewModel.onVersionTap {
                        Button(action: onVersionTap) {
                            HStack(spacing: 4) {
                                Text(viewModel.appVersion)
                                Image(systemName: "info.circle")
                            }
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                        }
                    } else {
                        Text(viewModel.appVersion)
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private func outboundLinkButton(
        _ title: LocalizedStringKey,
        url: URL,
        image: String,
        color: Color
    ) -> some View {
        Button {
            openURL(url)
        } label: {
            buttonLabel(title, image: image, color: color)
        }
        .buttonStyle(.plain)
    }
    
    private func buttonLabel(
        _ title: LocalizedStringKey,
        image: String,
        color: Color,
        navigationImage: String = "arrow.up.forward"
    ) -> some View {
        HStack(spacing: 15) {
            Image(systemName: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundStyle(color)
            
            Text(title)
            
            Spacer()
            
            Image(systemName: navigationImage)
                .foregroundStyle(color)
                .font(Font.caption2)
                .opacity(0.5)
        }
        .padding()
        .background(.contentBackground)
    }
    
    private var copyrightView: some View {
        let currentYear: String = String(Date().year)
        return VStack(spacing: 10) {
            Text("Copyright © 2020-\(currentYear)")
                .font(.caption)
            
            avocadoAppsBrandView
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.background)
    }

    private var avocadoAppsBrandView: some View {
        Button {
            openURL(URL(string: "https://avocadoapps.github.io/")!)
        } label: {
            HStack(spacing: 8) {
                Image("avocado-apps-logo", bundle: azkarResourcesBundle)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)

                Text("Avocado Apps")
                    .font(.headline.weight(.bold))
                    .tracking(-0.4)
                    .foregroundStyle(.primary)
                    .opacity(0.75)
            }
        }
        .buttonStyle(.plain)
    }
     
}

#Preview("App Info") {
    NavigationView {
        AppInfoView(viewModel: AppInfoViewModel(
            appVersion: "1.2.3",
            isProUser: true
        ))
    }
}
