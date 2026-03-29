//
//  WindParticleView.swift
//  PaperPlane
//
//  Created by Jonathan Basuki on 23/03/26.
//

import SwiftUI

// MARK: - Wind Particle Canvas View

/// Renders wind particles as small blurred circles.
/// Particles are driven by FlyingViewModel's windParticles array.
/// Lightweight Canvas-based rendering for 60fps performance.
struct WindParticleView: View {
    
    let particles: [WindParticle]
    
    var body: some View {
        Canvas { context, size in
            for particle in particles {
                let rect = CGRect(
                    x: particle.x - particle.size / 2,
                    y: particle.y - particle.size / 2,
                    width: particle.size,
                    height: particle.size
                )
                
                context.opacity = particle.opacity
                context.addFilter(.blur(radius: particle.size * 0.3))
                
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(
                        Color.white.opacity(particle.opacity)
                    )
                )
            }
        }
        .allowsHitTesting(false)
    }
}
