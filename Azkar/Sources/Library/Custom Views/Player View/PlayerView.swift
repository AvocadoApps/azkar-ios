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
            elapsedTimeView
            playbackControls
            remainingTimeView
        }
        .padding(.horizontal)
    }

    private var elapsedTimeView: some View {
        Text(viewModel.timeElapsed)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.tertiaryText)
            .font(Font.system(.caption, design: .monospaced))
            .accessibilityLabel(Text("accessibility.player.elapsed-time"))
            .accessibilityValue(viewModel.timeElapsed)
    }

    private var remainingTimeView: some View {
        Text(viewModel.timeRemaining)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .foregroundStyle(.tertiaryText)
            .font(Font.system(.caption, design: .monospaced))
            .accessibilityLabel(Text("accessibility.player.remaining-time"))
            .accessibilityValue(viewModel.timeRemaining)
    }

    @ViewBuilder
    private var playbackControls: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: 10) {
                HStack(alignment: .center, spacing: 10) {
                    restartButton
                    playPauseButton
                    speedButton
                }
            }
            .frame(maxWidth: .infinity)
        } else {
            HStack(alignment: .center, spacing: 0) {
                restartButton
                playPauseButton
                speedButton
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var restartButton: some View {
        Button(action: {
            self.viewModel.play()
        }, label: {
            Image(systemName: "backward.end.alt")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
                .glassEffectCompat(.regular.interactive(), in: Circle())
        })
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
        .accessibilityLabel(Text("accessibility.player.restart-audio"))
    }

    private var playPauseButton: some View {
        Button(action: {
            self.viewModel.togglePlayPause()
        }, label: {
            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 25)
                .frame(width: 50, height: 50)
                .contentShape(Circle())
                .glassEffectCompat(.regular.tint(tintColor.opacity(0.2)).interactive(), in: Circle())
        })
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
        .accessibilityLabel(playPauseLabel)
        .accessibilityValue(playPauseValue)
    }

    private var speedButton: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.6)
            self.viewModel.toggleSpeed()
        }, label: {
            Text(viewModel.speed.label)
                .minimumScaleFactor(0.2)
                .frame(width: 30, height: 30)
                .foregroundStyle(tintColor)
                .font(Font.system(.body, design: .monospaced))
                .frame(width: 44, height: 44)
                .contentShape(Circle())
                .glassEffectCompat(.regular.interactive(), in: Circle())
        })
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
        .accessibilityLabel(Text("accessibility.player.playback-speed"))
        .accessibilityValue(viewModel.speed.label)
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
