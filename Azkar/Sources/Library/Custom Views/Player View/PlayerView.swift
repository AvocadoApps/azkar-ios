import SwiftUI
import Library

struct PlayerView: View, Equatable {

    static func == (lhs: PlayerView, rhs: PlayerView) -> Bool {
        return lhs.viewModel == rhs.viewModel
    }

    @ObservedObject var viewModel: PlayerViewModel
    @Environment(\.colorTheme) var colorTheme
    
    var tintColor: Color {
        colorTheme.getColor(.accent)
    }
    var progressBarColor: Color {
        colorTheme.getColor(.accent, opacity: 0.1)
    }
    var progressBarHeight: CGFloat = 1

    private var playPauseLabel: String {
        viewModel.isPlaying
            ? String(localized: "accessibility.player.pause-audio")
            : String(localized: "accessibility.player.play-audio")
    }

    private var playPauseValue: String {
        viewModel.isPlaying
            ? String(localized: "accessibility.player.playing")
            : String(localized: "accessibility.player.paused")
    }

    var body: some View {
        VStack(spacing: 8) {
            buttonsView
                .foregroundStyle(tintColor)
            progressBar
        }
    }

    private var buttonsView: some View {
        HStack(alignment: .center, spacing: 0) {
            Text(viewModel.timeElapsed)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.tertiaryText)
                .font(Font.system(.caption, design: .monospaced))
                .accessibilityLabel(Text("accessibility.player.elapsed-time"))
                .accessibilityValue(viewModel.timeElapsed)
            Button(action: {
                self.viewModel.play()
            }, label: {
                Image(systemName: "backward.end.alt")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            })
            .frame(maxWidth: .infinity)
            .accessibilityLabel(Text("accessibility.player.restart-audio"))
            Button(action: {
                self.viewModel.togglePlayPause()
            }, label: {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 25)
            })
            .frame(maxWidth: .infinity)
            .accessibilityLabel(playPauseLabel)
            .accessibilityValue(playPauseValue)
            Button(action: {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.6)
                self.viewModel.toggleSpeed()
            }, label: {
                Text(viewModel.speed.label)
                    .minimumScaleFactor(0.2)
                    .frame(width: 30, height: 30)
                    .foregroundStyle(tintColor)
                    .font(Font.system(.body, design: .monospaced))
            })
            .frame(maxWidth: .infinity)
            .accessibilityLabel(Text("accessibility.player.playback-speed"))
            .accessibilityValue(viewModel.speed.label)
            Text(viewModel.timeRemaining)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundStyle(.tertiaryText)
                .font(Font.system(.caption, design: .monospaced))
                .accessibilityLabel(Text("accessibility.player.remaining-time"))
                .accessibilityValue(viewModel.timeRemaining)
        }
        .padding(.horizontal)
    }

    private var progressBar: some View {
        ProgressBar(value: viewModel.progress, maxValue: 1, backgroundColor: progressBarColor, foregroundStyle: tintColor)
        .frame(height: progressBarHeight)
        .accessibilityLabel(Text("accessibility.player.playback-progress"))
        .accessibilityValue(
            String(
                format: String(localized: "accessibility.player.progress-percent"),
                locale: Locale.current,
                Int(viewModel.progress * 100)
            )
        )
    }

}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView(viewModel: PlayerViewModel(
            title: "",
            subtitle: "",
            audioURL: URL(string: "https://google.com")!,
            timings: [],
            player: .test
        ))
        .previewDevice(.init(stringLiteral: "iPhone 11 Pro"))
    }
}
