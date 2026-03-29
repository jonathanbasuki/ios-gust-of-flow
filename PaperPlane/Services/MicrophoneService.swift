//
//  MicrophoneService.swift
//  PaperPlane
//
//  Created by Jonathan Basuki on 23/03/26.
//

import Foundation
import AVFoundation
import Combine

/// Detects microphone input using AVAudioEngine.
/// Converts raw PCM buffer data to normalized volume (0...1).
/// Uses a rolling average to smooth volume spikes.
final class MicrophoneService: ObservableObject {
    
    @Published private(set) var normalizedVolume: CGFloat = 0
    @Published private(set) var isBlowing: Bool = false
    
    private let audioEngine = AVAudioEngine()
    private var inputNode: AVAudioInputNode?
    
    private var windPlayer: AVAudioPlayer?
    private var windFadeTimer: Timer?
    
    private let blowThreshold: CGFloat = 0.08
    
    private var volumeBuffer: [Float] = Array(repeating: 0, count: 8)
    private var bufferIndex = 0
    
    private let minDB: Float = -50.0
    private let maxDB: Float = -10.0
    private let silenceThreshold: Float = 0.03
    
    func startMonitoring() {
        requestMicrophonePermission { [weak self] granted in
            guard granted else {
                print("Microphone permission denied.")
                return
            }
            self?.setupWindSound()
            self?.setupAudioEngine()
        }
    }
    
    private func setupAudioEngine() {
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(.playAndRecord,
                                    mode: .measurement,
                                    options: [.defaultToSpeaker, .mixWithOthers])
            try session.setActive(true)
        } catch {
            print("AVAudioSession setup failed: \(error)")
            return
        }
        
        inputNode = audioEngine.inputNode
        
        guard let inputNode = inputNode else { return }
        
        let format = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: format
        ) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        
        do {
            try audioEngine.start()
        } catch {
            print("AudioEngine start failed: \(error)")
        }
    }
    
    // MARK: - Wind Sound Setup
    
    /// Loads wind sound from bundle or generates programmatically.
    /// Place "wind_blow.mp3" or "wind_blow.wav" in bundle, or use synthesized fallback.
    private func setupWindSound() {
        if let url = Bundle.main.url(forResource: "wind_blow", withExtension: "mp3") {
            setupWindPlayer(url: url)
            return
        }
        
        if let url = Bundle.main.url(forResource: "wind_blow", withExtension: "wav") {
            setupWindPlayer(url: url)
            return
        }
        
        if let url = generateWindSoundFile() {
            setupWindPlayer(url: url)
            return
        }
        
        print("Wind sound not available")
    }
    
    private func setupWindPlayer(url: URL) {
        do {
            windPlayer = try AVAudioPlayer(contentsOf: url)
            windPlayer?.numberOfLoops = -1
            windPlayer?.volume = 0
            windPlayer?.prepareToPlay()
            windPlayer?.play()
            print("Wind sound loaded: \(url.lastPathComponent)")
        } catch {
            print("Wind player setup failed: \(error)")
        }
    }
    
    /// Generates a simple wind/white noise WAV file programmatically.
    /// No external audio file needed.
    private func generateWindSoundFile() -> URL? {
        let sampleRate: Double = 44100
        let duration: Double = 2.0
        let frameCount = Int(sampleRate * duration)
        
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("generated_wind.wav")
        
        guard let file = try? AVAudioFile(
            forWriting: url,
            settings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: sampleRate,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
            ]
        ) else { return nil }
        
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: file.processingFormat,
            frameCapacity: AVAudioFrameCount(frameCount)
        ) else { return nil }
        
        buffer.frameLength = AVAudioFrameCount(frameCount)
        
        guard let channelData = buffer.floatChannelData?[0] else { return nil }
        
        var prevSample: Float = 0
        let filterCoeff: Float = 0.85
        
        for i in 0..<frameCount {
            let noise = Float.random(in: -1...1)
            let filtered = prevSample * filterCoeff + noise * (1 - filterCoeff)
            prevSample = filtered
            
            let t = Float(i) / Float(frameCount)
            let envelope = sin(t * .pi)
            let loopSmooth: Float = 0.7 + 0.3 * envelope
            
            channelData[i] = filtered * 0.3 * loopSmooth
        }
        
        do {
            try file.write(from: buffer)
            print("Generated wind sound: \(url.lastPathComponent)")
            return url
        } catch {
            print("Failed to write wind sound: \(error)")
            return nil
        }
    }
    
    // MARK: - Audio Processing
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return }
        
        var sumOfSquares: Float = 0
        for i in 0..<frameCount {
            let sample = channelData[i]
            sumOfSquares += sample * sample
        }
        let rms = sqrt(sumOfSquares / Float(frameCount))
        
        let db = rms > 0 ? 20 * log10(rms) : minDB
        
        let clampedDB = max(minDB, min(maxDB, db))
        let normalized = CGFloat((clampedDB - minDB) / (maxDB - minDB))
        
        volumeBuffer[bufferIndex % volumeBuffer.count] = Float(normalized)
        bufferIndex += 1
        let avg = CGFloat(volumeBuffer.reduce(0, +) / Float(volumeBuffer.count))
        
        let finalVolume = avg < CGFloat(silenceThreshold) ? 0 : avg
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let wasBlowing = self.isBlowing
            self.normalizedVolume = finalVolume
            self.isBlowing = finalVolume > self.blowThreshold
            
            self.updateWindSound(volume: finalVolume, isBlowing: self.isBlowing)
            
            if self.isBlowing && !wasBlowing {
                self.onBlowStart()
            } else if !self.isBlowing && wasBlowing {
                self.onBlowStop()
            }
        }
    }
    
    // MARK: - Wind Sound Control
    
    /// Adjusts wind sound volume based on blow intensity.
    /// Maps blow volume (0.08...1.0) to wind volume (0.1...0.7).
    private func updateWindSound(volume: CGFloat, isBlowing: Bool) {
        guard let player = windPlayer else { return }
        
        if isBlowing {
            let minWindVol: Float = 0.1
            let maxWindVol: Float = 0.7
            let blowRange = 1.0 - Float(blowThreshold)
            let blowProgress = (Float(volume) - Float(blowThreshold)) / blowRange
            let targetVol = minWindVol + blowProgress * (maxWindVol - minWindVol)
            
            let currentVol = player.volume
            player.volume = currentVol + (targetVol - currentVol) * 0.3
            
        } else {
            let currentVol = player.volume
            let fadeTarget = currentVol * 0.85
            player.volume = fadeTarget < 0.01 ? 0 : fadeTarget
        }
    }
    
    private func onBlowStart() {
        windFadeTimer?.invalidate()
        windFadeTimer = nil
    }
    
    private func onBlowStop() {
        windFadeTimer?.invalidate()
        windFadeTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0 / 30.0,
            repeats: true
        ) { [weak self] timer in
            guard let self = self, let player = self.windPlayer else {
                timer.invalidate()
                return
            }
            
            DispatchQueue.main.async {
                let newVol = player.volume * 0.88
                if newVol < 0.005 {
                    player.volume = 0
                    timer.invalidate()
                    self.windFadeTimer = nil
                } else {
                    player.volume = newVol
                }
            }
        }
    }
    
    func stopMonitoring() {
        inputNode?.removeTap(onBus: 0)
        audioEngine.stop()
        
        windFadeTimer?.invalidate()
        windFadeTimer = nil
        windPlayer?.stop()
        windPlayer = nil
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.normalizedVolume = 0
            self?.isBlowing = false
        }
    }
    
    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async { completion(granted) }
        }
    }
}
