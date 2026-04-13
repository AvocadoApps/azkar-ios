import SwiftUI
import Library
import Entities

struct ZikrShareSheetView: View {

    let zikr: Zikr
    let actionHandler: ZikrShareActionHandler

    @StateObject private var backgroundsService: ShareBackgroundsServiceType

    init(zikr: Zikr, actionHandler: ZikrShareActionHandler) {
        self.zikr = zikr
        self.actionHandler = actionHandler
        _backgroundsService = StateObject(
            wrappedValue: ShareBackgroundsServiceProvider.createShareBackgroundsService()
        )
    }

    var body: some View {
        NavigationView {
            ZikrShareOptionsView(zikr: zikr) { options in
                actionHandler.handle(options, for: zikr)
            }
            .environmentObject(backgroundsService)
        }
#if os(iOS)
        .navigationViewStyle(.stack)
#endif
    }
}
