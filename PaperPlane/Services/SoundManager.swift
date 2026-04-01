//
//  SoundManager.swift
//  PaperPlane
//
//  Created by Jonathan Basuki on 01/04/26.
//

import AVFoundation
import SwiftUI
import Combine

final class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    private var players: [String: AVAudioPlayer] = [:]
    
    @Published var isMuted: Bool = false {
        didSet {
            UserDefaults.standard.set(isMuted, forKey: "soundMuted")
        }
    }
    
    // ─── Sesuaikan nama file kamu di sini ───
    // Key = FoldStep.rawValue, Value = (filename, extension, volume)
    private let soundMap: [Int: (name: String, ext: String, volume: Float)] = [
        1: ("sfx_fold", "mp3", 0.6),
        2: ("sfx_fold", "mp3", 0.6),
        3: ("sfx_fold", "mp3", 0.65),
        4: ("sfx_fold", "mp3", 0.7),
        5: ("sfx_fold", "mp3", 0.8),
    ]
    
    // Drag slide sound
    private let slideSoundFile = (name: "sfx_fold", ext: "mp3", volume: Float(0.3))
    
    // MARK: - Init
    private init() {
        isMuted = UserDefaults.standard.bool(forKey: "soundMuted")
        setupAudioSession()
        preloadAll()
    }
    
    // MARK: - Audio Session
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }
    
    // MARK: - Preload All Sounds
    private func preloadAll() {
        // Preload fold sounds
        for (_, info) in soundMap {
            loadSound(name: info.name, ext: info.ext, volume: info.volume)
        }
        
        // Preload slide sound
        loadSound(
            name: slideSoundFile.name,
            ext: slideSoundFile.ext,
            volume: slideSoundFile.volume
        )
    }
    
    private func loadSound(name: String, ext: String, volume: Float) {
        guard let url = Bundle.main.url(
            forResource: name,
            withExtension: ext
        ) else {
            print("File not found: \(name).\(ext)")
            print("   Pastikan file ada di Copy Bundle Resources!")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.prepareToPlay()
            players[name] = player
            print("Loaded: \(name).\(ext)")
        } catch {
            print("Failed to load \(name): \(error)")
        }
    }
    
    // MARK: - Play Fold Sound
    func playFoldSound(for step: FoldStep) {
        guard !isMuted else { return }
        
        guard let info = soundMap[step.rawValue] else { return }
        play(info.name)
    }
    
    // MARK: - Play Slide Sound (saat drag)
    func playSlideSound() {
        guard !isMuted else { return }
        play(slideSoundFile.name)
    }
    
    // MARK: - Core Play
    private func play(_ name: String) {
        guard let player = players[name] else {
            print("Player not found for: \(name)")
            return
        }
        
        // Reset ke awal jika sedang playing
        player.currentTime = 0
        player.play()
    }
    
    // MARK: - Play dengan custom volume (0.0 - 1.0)
    func play(_ name: String, volume: Float) {
        guard !isMuted, let player = players[name] else { return }
        player.volume = min(max(volume, 0), 1)
        player.currentTime = 0
        player.play()
    }
    
    // MARK: - Stop
    func stopAll() {
        for player in players.values {
            player.stop()
        }
    }
    
    func stop(_ name: String) {
        players[name]?.stop()
    }
    
    // MARK: - Toggle Mute
    func toggleMute() {
        isMuted.toggle()
    }
}
