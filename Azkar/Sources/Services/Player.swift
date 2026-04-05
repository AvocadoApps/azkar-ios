//
//  Player.swift
//  mp3quran
//
//  Created by Abdurahim Jauzee on 30.10.2019.
//  Copyright © 2019 Jawziyya Ltd. All rights reserved.
//

import Foundation
import AudioPlayer
import UIKit.UIImage

extension AudioPlayerState {
    var isPlaying: Bool {
        switch self {
        case .buffering, .playing, .waitingForConnection:
            return true
        default:
            return false
        }
    }
}

final class Player: NSObject, ObservableObject {

    enum Speed {
        case verySlow, slow, normal, fast, veryFast

        var label: String {
            return "\(value)x"
        }

        static func fromRate(_ rate: Float) -> Speed {
            switch rate {
            case 0..<0.5: return verySlow
            case ...0.99: return slow
            case 1.01...: return fast
            case 1.501...: return .veryFast
            default: return normal
            }
        }

        var value: Float {
            switch self {
            case .verySlow:
                return 0.6
            case .slow:
                return 0.8
            case .normal:
                return 1
            case .fast:
                return 1.3
            case .veryFast:
                return 1.5
            }
        }
        
        var next: Speed {
            switch self {
            case .verySlow: return .slow
            case .slow: return .normal
            case .normal: return .fast
            case .fast: return .veryFast
            case .veryFast: return .verySlow
            }
        }
    }

    static var test: Player {
        return Player(player: AudioPlayer())
    }

    private let audioPlayer: AudioPlayer

    @Published var isPlaying = false
    @Published var progress = 0.0
    @Published var currentAudioId = 0
    @Published var currentItemTitle = ""
    @Published var currentItemSubtitle = ""
    @Published var timeElapsed: Double = 0
    @Published var timeRemaining: Double = 0
    @Published var timeElapsedAdjusted: Double = 0
    @Published var timeRemainingAdjusted: Double = 0
    @Published var speed: Speed = .normal
    
    var currentItemURL: URL? {
        return audioPlayer.currentItem?.highestQualityURL.url
    }
    
    func adjustedTime(time: TimeInterval, speed: Speed) -> TimeInterval {
        time - (time * (Double(speed.value) - 1))
    }

    init(player: AudioPlayer) {
        self.audioPlayer = player
        super.init()
        audioPlayer.delegate = self
        speed = Speed.fromRate(audioPlayer.rate)
        isPlaying = audioPlayer.state == .playing
    }

    func playAudio(_ url: URL, title: String, subtitle: String?) {
        guard let item = AudioItem(highQualitySoundURL: url) else {
            return
        }
        item.title = title
        item.artist = subtitle
        playItem(item)
    }
    
    func playItem(_ item: AudioItem, atVolume volume: Float) {
        let previousVolume = audioPlayer.volume
        audioPlayer.volume = volume
        playItem(item)
        audioPlayer.volume = previousVolume
    }

    func playItem(_ item: AudioItem) {
        audioPlayer.play(item: item)
    }

    func seek(_ time: TimeInterval) {
        audioPlayer.seek(to: time)
    }

    func isPlayingItemAtURL(_ url: URL) -> Bool {
        audioPlayer.currentItem?.highestQualityURL.url == url
    }

    func stop() {
        audioPlayer.stop()
    }

    func seek(to fraction: Double) {
      guard let duration = audioPlayer.currentItemDuration else {
        return
      }
      let time = duration * Double(fraction)
      seek(to: time)
    }

    func adjustProgressionBy(_ interval: TimeInterval) {
        guard let currentTime = audioPlayer.currentItemProgression else {
            return
        }
        seek(currentTime + interval)
    }
    
    func resume() {
        audioPlayer.resume()
    }
    
    func pause() {
        audioPlayer.pause()
    }

    func togglePlayMode() {
        if audioPlayer.state == .playing {
            audioPlayer.pause()
        } else if audioPlayer.state == .paused {
            audioPlayer.resume()
        }
    }

    func setPlayingSpeed(_ speed: Speed) {
        self.speed = speed
        audioPlayer.rate = speed.value
    }

}

extension Player: AudioPlayerDelegate {

    func audioPlayer(_ audioPlayer: AudioPlayer, didChangeStateFrom from: AudioPlayerState, to state: AudioPlayerState) {
        
        isPlaying = state.isPlaying
        
        let values = (fromState: from, toState: state)
        switch values {
        case (.buffering, .playing):
            currentItemTitle = audioPlayer.currentItem?.title ?? ""
            currentItemSubtitle = audioPlayer.currentItem?.artist ?? ""
            
        case (.playing, .stopped):
            timeElapsed = 0
            timeRemaining = audioPlayer.currentItemDuration ?? 0
            timeRemainingAdjusted = adjustedTime(time: (audioPlayer.currentItemDuration ?? 0), speed: speed)
            progress = 0

        default:
            break
        }
    }

    func audioPlayer(_ audioPlayer: AudioPlayer, didUpdateProgressionTo time: TimeInterval, percentageRead: Float) {
        progress = Double(percentageRead/100)
        timeElapsed = time
        timeElapsedAdjusted = adjustedTime(time: time, speed: speed)

        timeRemaining = (audioPlayer.currentItemDuration ?? 0) - time
        timeRemainingAdjusted = adjustedTime(time: timeRemaining, speed: speed)
    }

}
