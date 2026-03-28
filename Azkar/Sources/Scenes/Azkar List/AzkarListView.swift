//
//  AzkarListView.swift
//  Azkar
//
//  Created by Abdurahim Jauzee on 06.05.2020.
//  Copyright © 2020 Al Jawziyya. All rights reserved.
//

import SwiftUI
import AudioPlayer
import Library
import Extensions

typealias AzkarListViewModel = ZikrPagesViewModel

struct AzkarListView: View {

    let viewModel: AzkarListViewModel
    
    @State var page = 0

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            list
        }
        .onAppear {
            AnalyticsReporter.reportScreen("Azkar List", className: viewName)
        }
        .navigationTitle(viewModel.title)
        .background(.background, ignoreSafeArea: .all)
        .onReceive(viewModel.selectedPage) { page in
            self.page = page
        }
    }

    var list: some View {
        LazyVStack(alignment: HorizontalAlignment.leading, spacing: 8) {
            ForEach(viewModel.azkar.indices, id: \.self) { index in
                rowView(for: index)
            }
        }
    }

    private func rowView(for index: Int) -> some View {
        let zikr = viewModel.azkar[index]
        let title = zikr.title ?? index.description

        return Button {
            viewModel.navigateToZikr(zikr, index: index)
        } label: {
            HStack {
                Text(title)
                    .contentShape(Rectangle())
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .accessibilityHidden(true)
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
        .applyAccessibilityLanguage(zikr.zikr.language.id)
    }

}

struct AzkarListView_Previews: PreviewProvider {
    static var previews: some View {
        AzkarListView(viewModel: .placeholder)
    }
}
