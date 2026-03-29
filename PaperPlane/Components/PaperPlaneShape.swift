//
//  PaperPlaneShape.swift
//  PaperPlane
//
//  Created by Jonathan Basuki on 23/03/26.
//

import SwiftUI

// MARK: - Paper Plane Shape (Path-based)
// Draws the paper plane using pure SwiftUI Path.
// Two variants:
//   - PaperPlaneShape: The final morphed origami plane
//   - FlyingPlaneView: Animated plane for FlyingView

/// Main paper plane outline shape
struct PaperPlaneShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let w = rect.width
        let h = rect.height
        
        // Main body (fuselage) - plane points to the right
        let nose        = CGPoint(x: w,       y: h * 0.5)
        let topWingTip  = CGPoint(x: w * 0.1, y: 0)
        let topWingBase = CGPoint(x: w * 0.5, y: h * 0.45)
        let tailTop     = CGPoint(x: 0,       y: h * 0.2)
        let tailBottom  = CGPoint(x: 0,       y: h * 0.8)
        let botWingBase = CGPoint(x: w * 0.5, y: h * 0.55)
        let botWingTip  = CGPoint(x: w * 0.1, y: h)
        
        // Top wing
        path.move(to: nose)
        path.addLine(to: topWingTip)
        path.addLine(to: tailTop)
        path.addLine(to: topWingBase)
        path.addLine(to: nose)
        
        // Bottom wing
        path.move(to: nose)
        path.addLine(to: botWingBase)
        path.addLine(to: tailBottom)
        path.addLine(to: botWingTip)
        path.addLine(to: nose)
        
        return path
    }
}

// MARK: - Plane Body Fill (multi-layer for depth)

/// Solid filled body shape for paper plane
struct PaperPlaneBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: w,       y: h * 0.5))   // Nose
        path.addLine(to: CGPoint(x: w * 0.1, y: 0))       // Top wing tip
        path.addLine(to: CGPoint(x: 0,       y: h * 0.2)) // Tail top
        path.addLine(to: CGPoint(x: w * 0.4, y: h * 0.5)) // Body center
        path.addLine(to: CGPoint(x: 0,       y: h * 0.8)) // Tail bottom
        path.addLine(to: CGPoint(x: w * 0.1, y: h))       // Bot wing tip
        path.addLine(to: CGPoint(x: w,       y: h * 0.5)) // Back to nose
        
        return path
    }
}

// MARK: - Upper Wing Shape (lighter tone)

/// Upper wing shape with lighter fill for depth effect
struct PlaneUpperWingShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: w,       y: h * 0.5))
        path.addLine(to: CGPoint(x: w * 0.1, y: 0))
        path.addLine(to: CGPoint(x: 0,       y: h * 0.2))
        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.45))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Fold Line (center crease)

/// Center fold line shape for paper plane crease
struct PlaneFoldLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: w, y: h * 0.5))
        path.addLine(to: CGPoint(x: 0, y: h * 0.5))
        
        return path
    }
}

// MARK: - Complete Paper Plane View Component

/// Composable paper plane view with shadow, fill, highlight, and outline
struct PaperPlaneView: View {
    
    /// Size of the plane
    var size: CGSize = CGSize(width: 80, height: 50)
    
    /// Tilt angle in degrees (positive = nose up)
    var tiltAngle: Double = 0
    
    /// Scale for idle breathing
    var idleWobble: Double = 0
    
    /// Flip for direction (1 = right, -1 = left)
    var direction: CGFloat = 1
    
    var body: some View {
        ZStack {
            // Shadow
            PaperPlaneBodyShape()
                .fill(Color.black.opacity(0.08))
                .frame(width: size.width, height: size.height)
                .blur(radius: 4)
                .offset(x: 4, y: 5)
            
            // Body fill
            PaperPlaneBodyShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "#FAFAF5"),
                            Color(hex: "#EEE8D8")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size.width, height: size.height)
            
            // Upper wing highlight
            PlaneUpperWingShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            Color(hex: "#F5F0E8").opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size.width, height: size.height)
            
            // Outline
            PaperPlaneShape()
                .stroke(
                    Color(hex: "#C8C0B0"),
                    style: StrokeStyle(lineWidth: 1.2, lineJoin: .round)
                )
                .frame(width: size.width, height: size.height)
            
            // Center crease
            PlaneFoldLine()
                .stroke(
                    Color(hex: "#C8C0B0").opacity(0.5),
                    style: StrokeStyle(
                        lineWidth: 0.8,
                        dash: [3, 2]
                    )
                )
                .frame(width: size.width, height: size.height)
        }
        .scaleEffect(x: direction, y: 1)
        .rotationEffect(.degrees(tiltAngle))
        .offset(y: idleWobble)
        .animation(
            .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
            value: idleWobble
        )
    }
}

// MARK: - Plane Morph Transition View

/// Used on FoldingView when paper morphs into plane
struct PlaneMorphView: View {
    @State private var appeared = false
    
    var body: some View {
        PaperPlaneView(size: CGSize(width: 160, height: 100))
            .scaleEffect(appeared ? 1.0 : 0.3)
            .opacity(appeared ? 1.0 : 0)
            .rotation3DEffect(
                .degrees(appeared ? 0 : -180),
                axis: (x: 0, y: 1, z: 0)
            )
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    appeared = true
                }
            }
    }
}
