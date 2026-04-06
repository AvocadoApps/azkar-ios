//
//  PlayerViewModel.swift
//  Azkar
//
//  Created by Abdurahim Jauzee on 04.05.2020.
//  Copyright © 2020 Al Jawziyya. All rights reserved.
//

import SwiftUI
import Combine
import AVFoundation

final class PlayerViewModel: ObservableObject, Equatable {

    static func == (lhs: PlayerViewModel, rhs: PlayerViewModel) -> Bool {
        return lhs.timeRemaining == rhs.timeRemaining
            && lhs.timeElapsed == rhs.timeElapsed
            && lhs.progress == rhs.progress
            && lhs.isPlaying == rhs.isPlaying
    }

    @Published var isPlaying: Bool
    @Published var progress: Double = 0
    @Published var progressInSeconds: Double = 0
    @Published var timeElapsed = ""
    @Published var timeRemaining = ""
    @Published var speed: Player.Speed = .normal

    let audioURL: URL
    let title: String
    let subtitle: String?
    let timings: [AudioTiming]

    private let player: Player
    private var cancellables = Set<AnyCancellable>()

    init(
        title: String,
        subtitle: String?,
        audioURL: URL,
        timings: [AudioTiming],
        player: Player
    ) {
        self.audioURL = audioURL
        self.title = title
        self.subtitle = subtitle
        self.player = player
        self.timings = timings
        isPlaying = player.isPlaying
        speed = player.speed

        player.$speed
            .removeDuplicates()
            .assign(to: \.speed, on: self)
            .store(in: &cancellables)

        player.$isPlaying
            .map { $0 && player.isPlayingItemAtURL(audioURL) }
            .removeDuplicates()
            .assign(to: \.isPlaying, on: self)
            .store(in: &cancellables)

        player.$progress
            .map { progress in
                guard player.isPlayingItemAtURL(audioURL) else {
                    return 0
                }
                return progress
            }
            .removeDuplicates()
            .assign(to: &$progress)

        player.$timeElapsed
            .filter { _ in player.isPlayingItemAtURL(audioURL) }
            .removeDuplicates()
            .assign(to: &$progressInSeconds)

        let zeroTime = "00:00"
        let formatter = DateComponentsFormatter()
        formatter.formattingContext = .standalone
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        formatter.unitsStyle = .positional

        let asset = AVURLAsset(url: audioURL)
        let duration = Double(CMTimeGetSeconds(asset.duration))

        player.$timeElapsedAdjusted
            .prepend(0)
            .map {
                player.isPlayingItemAtURL(audioURL) ? $0 : 0
            }
            .removeDuplicates()
            .map { formatter.string(from: $0) ?? zeroTime }
            .assign(to: \.timeElapsed, on: self)
            .store(in: &cancellables)

        player.$timeRemainingAdjusted
            .map { time in player.isPlayingItemAtURL(audioURL) ? time : duration }
            .removeDuplicates()
            .prepend(duration)
            .map { formatter.string(from: $0) ?? zeroTime }
            .assign(to: \.timeRemaining, on: self)
            .store(in: &cancellables)
    }

    func play() {
        player.playAudio(audioURL, title: title, subtitle: subtitle)
    }

    private func resume() {
        player.resume()
    }

    func pause() {
        player.pause()
    }

    func togglePlayPause() {
        isPlaying ? pause() : (player.isPlayingItemAtURL(audioURL) ? resume() : play())
    }

    func toggleSpeed() {
        player.setPlayingSpeed(speed.next)
    }
    
    func goToTiming(at index: Int) {
        guard index < timings.count else {
            return
        }
        let timing = timings[index]
        if isPlaying {
            player.seek(timing.time)
        } else {
            play()
            player.seek(timing.time)
            pause()
        }
    }

}
