//
//  HapticsManager.swift
//  PaperPlane
//
//  Created by Jonathan Basuki on 23/03/26.
//
//  Wraps Core Haptics (CHHapticEngine) with
//  pre-defined patterns for folding & flying events.
//  Falls back to UIImpactFeedbackGenerator if unavailable.
//

import Foundation
import CoreHaptics
import UIKit

final class HapticsManager {
    // MARK: - Singleton
    static let shared = HapticsManager()
    private init() { prepareEngine() }
    
    // MARK: - Private
    private var engine: CHHapticEngine?
    private var isSupported: Bool = false
    
    // MARK: - Setup
    private func prepareEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("Haptics not supported on this device.")
            isSupported = false
            return
        }
        
        isSupported = true
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Failed to create haptic engine: \(error)")
        }
        
        // Auto-restart on engine stop
        engine?.stoppedHandler = { [weak self] reason in
            print("Haptic engine stopped: \(reason)")
            self?.restartEngine()
        }
        
        engine?.resetHandler = { [weak self] in
            print("Haptic engine reset")
            self?.restartEngine()
        }
    }
    
    private func restartEngine() {
        do {
            try engine?.start()
        } catch {
            print("Haptic engine restart failed: \(error)")
        }
    }
    
    // MARK: - Public Patterns
    /// Played each time a fold step completes
    func playFoldFeedback() {
        guard isSupported, let engine = engine else {
            // Fallback
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            
            return
        }
        
        do {
            let sharpness = CHHapticEventParameter(
                parameterID: .hapticSharpness, value: 0.6
            )
            let intensity = CHHapticEventParameter(
                parameterID: .hapticIntensity, value: 0.8
            )
            
            // Two-tap pattern: thud + click
            let thud = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensity, sharpness],
                relativeTime: 0
            )
            let click = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                ],
                relativeTime: 0.1
            )
            
            let pattern = try CHHapticPattern(events: [thud, click], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Fold haptic failed: \(error)")
        }
    }
    
    /// Played when takeoff begins
    func playTakeoffFeedback() {
        guard isSupported, let engine = engine else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
            return
        }
        
        do {
            var events: [CHHapticEvent] = []
            
            // Rising intensity sweep
            for i in 0..<5 {
                let t = Double(i) * 0.06
                let intensityVal = Float(0.2 + Double(i) * 0.16)
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensityVal),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: t
                )
                events.append(event)
            }
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Takeoff haptic failed: \(error)")
        }
    }
    
    /// Light continuous rumble while blowing
    func playWindFeedback(intensity: Float) {
        guard isSupported, let engine = engine else { return }
        guard intensity > 0.1 else { return }
        
        do {
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity * 0.3),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0,
                duration: 0.1
            )
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            
            try player.start(atTime: CHHapticTimeImmediate)
        } catch { }
    }
}
