//
//  TreeShape.swift
//  PaperPlane
//
//  Created by Jonathan Basuki on 23/03/26.
//

import SwiftUI

// MARK: - Tree Shapes

/// Draws simple stylized trees using SwiftUI Path.
/// Two variants: round-top and triangular pine.

struct RoundTreeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let w = rect.width
        let h = rect.height
        
        let trunkWidth  = w * 0.2
        let trunkHeight = h * 0.3
        let trunkRect = CGRect(
            x: (w - trunkWidth) / 2,
            y: h - trunkHeight,
            width: trunkWidth,
            height: trunkHeight
        )
        path.addRoundedRect(in: trunkRect, cornerSize: CGSize(width: 2, height: 2))
        
        let foliageRect = CGRect(
            x: w * 0.05,
            y: 0,
            width: w * 0.9,
            height: h * 0.75
        )
        path.addEllipse(in: foliageRect)
        
        return path
    }
}

struct PineTreeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let w = rect.width
        let h = rect.height
        
        path.addRect(CGRect(
            x: w * 0.4, y: h * 0.78,
            width: w * 0.2, height: h * 0.22
        ))
        
        path.move(to: CGPoint(x: w / 2,  y: 0))
        path.addLine(to: CGPoint(x: 0,    y: h * 0.45))
        path.addLine(to: CGPoint(x: w,    y: h * 0.45))
        path.closeSubpath()
        
        path.move(to: CGPoint(x: w / 2,  y: h * 0.1))
        path.addLine(to: CGPoint(x: w * 0.08, y: h * 0.58))
        path.addLine(to: CGPoint(x: w * 0.92, y: h * 0.58))
        path.closeSubpath()
        
        path.move(to: CGPoint(x: w / 2,  y: h * 0.2))
        path.addLine(to: CGPoint(x: w * 0.18, y: h * 0.72))
        path.addLine(to: CGPoint(x: w * 0.82, y: h * 0.72))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Tree View Component

struct TreeView: View {
    enum TreeType {
        case round, pine
    }
    
    var type: TreeType = .round
    var width: CGFloat = 40
    var height: CGFloat = 60
    
    /// Parallax vertical offset
    var offsetY: CGFloat = 0
    
    private var foliageColor: Color {
        Color(hex: "#7EC8A0").opacity(0.85)
    }
    
    private var trunkColor: Color {
        Color(hex: "#A0785A")
    }
    
    var body: some View {
        ZStack {
            switch type {
            case .round:
                RoundedRectangle(cornerRadius: 2)
                    .fill(trunkColor)
                    .frame(width: width * 0.2, height: height * 0.3)
                    .offset(y: height * 0.35)
                
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#8DD4A8"),
                                Color(hex: "#5FAE7A")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: width, height: height * 0.75)
                    .offset(y: -height * 0.1)
                
                Ellipse()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: width * 0.5, height: height * 0.35)
                    .offset(x: -width * 0.1, y: -height * 0.2)
                    .blur(radius: 2)
                
            case .pine:
                PineTreeShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#6BBF8A"),
                                Color(hex: "#4A9462")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: width, height: height)
            }
        }
        .frame(width: width, height: height)
        .offset(y: offsetY)
    }
}

// MARK: - Tree Row (Multiple Trees)

struct TreeRowView: View {
    struct TreeConfig: Identifiable {
        let id = UUID()
        var x: CGFloat
        var type: TreeView.TreeType
        var scale: CGFloat
        var offsetY: CGFloat
    }
    
    let configs: [TreeConfig]
    let parallaxOffset: CGFloat
    
    var body: some View {
        ZStack {
            ForEach(configs) { config in
                TreeView(
                    type: config.type,
                    width: 35 * config.scale,
                    height: 55 * config.scale,
                    offsetY: parallaxOffset * config.scale
                )
                .position(x: config.x, y: config.offsetY)
            }
        }
    }
}
