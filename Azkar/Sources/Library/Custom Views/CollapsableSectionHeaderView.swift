// Copyright © 2022 Al Jawziyya. All rights reserved. 

import SwiftUI

struct CollapsableSectionHeaderView: View {

    let title: LocalizedStringKey?
    let isExpanded: Bool
    let isExpandable: Bool

    var body: some View {
        HStack {
            title.flatMap { title in
                Text(title)
                    .systemFont(.caption, modification: .smallCaps)
                    .foregroundStyle(.tertiaryText)
            }
            if isExpandable {
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundStyle(.accent)
                    .rotationEffect(.init(degrees: isExpanded ? 180 : 0))
            }
        }
    }

}
