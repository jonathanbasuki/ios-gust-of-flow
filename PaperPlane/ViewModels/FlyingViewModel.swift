//
//  FlyingViewModel.swift
//  PaperPlane
//
//  Created by Jonathan Basuki on 23/03/26.
//

import SwiftUI
import Combine

/// Physics engine managing paper plane position, velocity, gravity, lift (mic), and tilt (motion).
/// Runs a 60fps display link update loop.
@MainActor
final class FlyingViewModel: ObservableObject {
    
    @Published var planeX: CGFloat = 0
    @Published var planeY: CGFloat = 0
    @Published var planeTiltAngle: Double = 0
    @Published var planeRollAngle: Double = 0
    @Published var isFlying: Bool = false
    @Published var windParticles: [WindParticle] = []
    
    @Published var groundOffset: CGFloat = 0
    @Published var skyOffset: CGFloat = 0
    @Published var treesOffset: CGFloat = 0
    
    let micService = MicrophoneService()
    let motionService = MotionService()
    private let haptics = HapticsManager.shared
    
    private let gravity: CGFloat = 0.15
    private let maxLift: CGFloat = 0.8
    private let horizontalSpeed: CGFloat = 1.8
    private let dampingFactor: CGFloat = 0.88
    private let maxVelocityY: CGFloat = 8.0
    
    /// Blow-steer: when blowing, plane also moves toward tilt direction
    private let blowSteerFactor: CGFloat = 1.2
    
    private let maxRollDegrees: Double = 20.0
    private let maxPitchDegrees: Double = 25.0
    private let tiltSmoothing: Double = 0.12
    
    private var velocityY: CGFloat = 0
    private var velocityX: CGFloat = 0
    
    private var currentVisualRoll: Double = 0
    private var currentVisualPitch: Double = 0
    
    var screenWidth: CGFloat = 390
    var screenHeight: CGFloat = 844
    
    private var displayLink: Timer?
    private var particleTimer: Timer?
    
    @Published var idleWobble: Double = 0
    private var idlePhase: Double = 0
    private var idleTimer: Timer?
    private var lastInputTime: Date = Date()
    
    func startFlying(screenWidth: CGFloat, screenHeight: CGFloat) {
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        
        planeX = screenWidth / 2
        planeY = screenHeight * 0.75
        isFlying = true
        
        micService.startMonitoring()
        motionService.startMonitoring()
        
        startPhysicsLoop()
        startParticleSystem()
        startIdleAnimation()
        
        haptics.playTakeoffFeedback()
    }
    
    func stopFlying() {
        isFlying = false
        displayLink?.invalidate()
        displayLink = nil
        particleTimer?.invalidate()
        particleTimer = nil
        idleTimer?.invalidate()
        idleTimer = nil
        micService.stopMonitoring()
        motionService.stopMonitoring()
    }
    
    private func startPhysicsLoop() {
        displayLink = Timer.scheduledTimer(
            withTimeInterval: 1.0 / 60.0,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updatePhysics()
            }
        }
    }
    
    private func updatePhysics() {
        guard isFlying else { return }
        
        let volume = micService.normalizedVolume
        let roll = motionService.roll
        let isBlowing = volume > 0.05
        
        let lift = volume * maxLift
        velocityY += (gravity - lift)
        velocityY = velocityY.clamped(to: -maxVelocityY...maxVelocityY)
        velocityY *= dampingFactor
        planeY += velocityY
        
        var horizontalForce = roll * horizontalSpeed
        
        if isBlowing {
            horizontalForce += roll * blowSteerFactor * volume
        }
        
        velocityX += horizontalForce
        velocityX *= dampingFactor
        velocityX = velocityX.clamped(to: -5...5)
        planeX += velocityX
        
        let targetRoll = Double(roll) * maxRollDegrees
        currentVisualRoll += (targetRoll - currentVisualRoll) * tiltSmoothing
        planeRollAngle = currentVisualRoll
        
        let velocityPitch = Double(-velocityY * 3).clamped(to: -maxPitchDegrees...maxPitchDegrees)
        
        let blowNoseUp = isBlowing ? Double(volume) * -60.0 : 40.0
        let blowRollInfluence = isBlowing ? Double(roll) * Double(volume) * -60.0 : 40.0
        
        let targetPitch = (velocityPitch + blowNoseUp + blowRollInfluence)
            .clamped(to: -maxPitchDegrees...maxPitchDegrees)
        
        currentVisualPitch += (targetPitch - currentVisualPitch) * tiltSmoothing
        planeTiltAngle = currentVisualPitch
        
        let topBound: CGFloat = 80
        let bottomBound: CGFloat = screenHeight - 120
        let leftBound: CGFloat = 40
        let rightBound: CGFloat = screenWidth - 40
        
        if planeY <= topBound {
            planeY = topBound
            velocityY = abs(velocityY) * 0.3
        }
        if planeY >= bottomBound {
            planeY = bottomBound
            velocityY = -abs(velocityY) * 0.2
        }
        if planeX <= leftBound {
            planeX = leftBound
            velocityX = abs(velocityX) * 0.2
        }
        if planeX >= rightBound {
            planeX = rightBound
            velocityX = -abs(velocityX) * 0.2
        }
        
        let heightPercent = (planeY - topBound) / (bottomBound - topBound)
        skyOffset = -heightPercent * 30
        treesOffset = -heightPercent * 50
        groundOffset = -heightPercent * 80
        
        if volume > 0.05 || abs(roll) > 0.1 {
            lastInputTime = Date()
        }
    }
    
    private func startParticleSystem() {
        particleTimer = Timer.scheduledTimer(
            withTimeInterval: 0.15,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.spawnWindParticle()
                self?.updateParticles()
            }
        }
    }
    
    private func spawnWindParticle() {
        let volume = micService.normalizedVolume
        guard volume > 0.05 else { return }
        
        let windDirection: CGFloat = velocityX > 0.5 ? -1 : (velocityX < -0.5 ? 1 : CGFloat.random(in: -1...(-0.5)))
        
        let particle = WindParticle(
            x: planeX + CGFloat.random(in: -20...20),
            y: planeY + CGFloat.random(in: -10...10),
            opacity: Double.random(in: 0.3...0.7),
            size: CGFloat.random(in: 2...6),
            velocityX: windDirection * CGFloat.random(in: 1...3),
            velocityY: CGFloat.random(in: -1...1)
        )
        windParticles.append(particle)
        
        if windParticles.count > 30 {
            windParticles.removeFirst(5)
        }
    }
    
    private func updateParticles() {
        for i in windParticles.indices.reversed() {
            windParticles[i].x += windParticles[i].velocityX
            windParticles[i].y += windParticles[i].velocityY
            windParticles[i].opacity -= 0.05
            
            if windParticles[i].opacity <= 0 {
                windParticles.remove(at: i)
            }
        }
    }
    
    private func startIdleAnimation() {
        var phase = 0.0
        idleTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0 / 30.0,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let timeSinceInput = Date().timeIntervalSince(self.lastInputTime)
                guard timeSinceInput > 2.0 else {
                    self.idleWobble = 0
                    return
                }
                phase += 0.05
                self.idleWobble = sin(phase) * 5.0
            }
        }
    }
}

// MARK: - Wind Particle Model

struct WindParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
    var size: CGFloat
    var velocityX: CGFloat
    var velocityY: CGFloat
}
