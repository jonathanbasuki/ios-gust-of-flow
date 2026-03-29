//
//  MotionService.swift
//  PaperPlane
//
//  Created by Jonathan Basuki on 23/03/26.
//

import Foundation
import CoreMotion
import Combine

/// Reads device tilt using CMMotionManager.
/// Publishes normalized roll value (-1...1):
///   -1 = fully tilted left
///   +1 = fully tilted right
final class MotionService: ObservableObject {
    
    /// Normalized roll: -1 (left) to +1 (right)
    @Published private(set) var roll: CGFloat = 0
    
    private let motionManager = CMMotionManager()
    private let updateInterval: TimeInterval = 1.0 / 60.0
    
    /// Dead zone to prevent drift and accidental small movements
    private let deadZone: Double = 0.10
    
    /// Smoothing factor for gradual response (lower = smoother/slower)
    private let smoothing: Double = 0.08
    
    /// Sensitivity multiplier to reduce effective tilt range
    /// 1.0 = full sensitivity, 0.5 = half sensitivity
    private let sensitivity: Double = 0.6
    
    private var currentRoll: Double = 0
    
    func startMonitoring() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion not available")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = updateInterval
        
        motionManager.startDeviceMotionUpdates(
            using: .xArbitraryZVertical,
            to: .main
        ) { [weak self] motionData, error in
            guard let self = self,
                  let motion = motionData,
                  error == nil else { return }
            
            self.processMotion(motion)
        }
    }
    
    private func processMotion(_ motion: CMDeviceMotion) {
        var rawRoll = motion.gravity.x
        
        if abs(rawRoll) < deadZone {
            rawRoll = 0
        }
        
        rawRoll *= sensitivity
        rawRoll = rawRoll.clamped(to: -1...1)
        
        currentRoll += (rawRoll - currentRoll) * smoothing
        
        roll = CGFloat(currentRoll)
    }
    
    func stopMonitoring() {
        motionManager.stopDeviceMotionUpdates()
        roll = 0
        currentRoll = 0
    }
}

// MARK: - Clamp for Double

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
