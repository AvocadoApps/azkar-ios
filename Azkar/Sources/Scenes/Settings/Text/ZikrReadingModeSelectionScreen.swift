import SwiftUI
import Combine
import FactoryKit
import Library

private let minScale = 0.45
private let maxScale = 1.0

struct ZikrReadingModeSelectionScreen: View {
    
    let zikr: Zikr
    private let zikrViewModel: ZikrViewModel
    
    init(
        zikr: Zikr,
        mode: Binding<ZikrReadingMode>,
        player: Player
    ) {
        let preferences = Container.shared.preferences()
        self.zikr = zikr
        _mode = mode
        zikrViewModel = ZikrViewModel(
            zikr: zikr,
            isNested: false,
            hadith: nil,
            preferences: preferences,
            player: player
        )
    }
    
    @Binding var mode: ZikrReadingMode
    
    var body: some View {
        VStack(spacing: 20) {
            pickerView
                .padding()
            modesView
        }
        .onChange(of: mode) { _ in
            zikrViewModel.pausePlayer()
        }
        .background(.background, ignoreSafeArea: .all)
    }
    
    var pickerView: some View {
        Picker(
            selection: $mode.animation(.spring),
            content: {
                ForEach(ZikrReadingMode.allCases) { mode in
                    Text(mode.title)
                }
            }
        )
        .pickerStyle(.segmented)
    }
    
    private var modesView: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                if mode == .normal {
                    createZikrView(mode: .normal, proxy: proxy)
                        .transition(.move(edge: .leading).combined(with: .opacity).combined(with: .scale(scale: 0.5)))
                }
                if mode == .lineByLine {
                    createZikrView(mode: .lineByLine, proxy: proxy)
                        .transition(.move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.5)))
                }
            }
        }
    }
    
    private func createZikrView(
        mode: ZikrReadingMode,
        proxy: GeometryProxy
    ) -> some View {
        ZikrView(
            viewModel: zikrViewModel
        )
        .environment(\.zikrReadingMode, mode)
        .onDisappear {
            zikrViewModel.pausePlayer()
        }
    }
    
}

private struct ZikrReadingModeSelectionScreenPreview: View {
    @State var mode: ZikrReadingMode = .normal
    
    var body: some View {
        ZikrReadingModeSelectionScreen(
            zikr: .placeholder(),
            mode: $mode,
            player: .test
        )
    }
}

#Preview {
    ZikrReadingModeSelectionScreenPreview()
}
