//
//  PaperShape.swift
//  PaperPlane
//

import SwiftUI

// MARK: - Color Palette

struct PaperPalette {
    static let paperWhite  = Color(hex: "#FAFAF8")
    static let paperCream  = Color(hex: "#F2EDE3")
    static let paperShade  = Color(hex: "#DDD8CC")
    static let foldLine    = Color(hex: "#B0A898").opacity(0.7)
    static let accent      = Color(hex: "#A8D8EA")
}

// MARK: - Drag Zone Definition

/// Defines interactive drag regions for each folding step.
/// Zones are generous and forgiving for better UX.
struct DragZone {
    let rect: CGRect
    let direction: DragDirection
    let arrowRotation: Double
    
    var arrowPosition: CGPoint {
        CGPoint(x: rect.midX, y: rect.midY)
    }

    enum DragDirection {
        case up, down, leading, trailing, towardCenter
    }

    /// Validates drag direction with tolerance for small movements
    func isDragDirectionValid(_ translation: CGSize) -> Bool {
        let dx = translation.width
        let dy = translation.height
        let magnitude = sqrt(dx * dx + dy * dy)
        
        guard magnitude > 5 else { return true }
        
        switch direction {
        case .up:           return dy < 0
        case .down:         return dy > 0
        case .leading:      return dx < 0
        case .trailing:     return dx > 0
        case .towardCenter: return true
        }
    }
}

// MARK: - FoldStep Drag Zones

extension FoldStep {
    var dragZone: DragZone {
        switch self {
        case .flat:
            return DragZone(
                rect: CGRect(x: 0, y: 0, width: 120, height: 280),
                direction: .trailing,
                arrowRotation: 0
            )
        case .step1:
            return DragZone(
                rect: CGRect(x: 0, y: 0, width: 200, height: 160),
                direction: .down,
                arrowRotation: 135
            )
        case .step2:
            return DragZone(
                rect: CGRect(x: 0, y: 0, width: 200, height: 200),
                direction: .down,
                arrowRotation: 160
            )
        case .step3:
            return DragZone(
                rect: CGRect(x: 0, y: 0, width: 130, height: 280),
                direction: .trailing,
                arrowRotation: 0
            )
        case .step4, .completed:
            return DragZone(
                rect: CGRect(x: 0, y: 0, width: 200, height: 280),
                direction: .down,
                arrowRotation: 0
            )
        }
    }

    func isInDragZone(_ location: CGPoint) -> Bool {
        let zone = dragZone.rect
        let padded = zone.insetBy(dx: -30, dy: -30)
        return padded.contains(location)
    }
}

// MARK: - Paper Outline Shape

struct PaperOutlineShape: Shape {
    let step: FoldStep

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()

        switch step {
        case .flat, .step1:
            path.addRoundedRect(
                in: rect,
                cornerSize: CGSize(width: step == .flat ? 6 : 4, height: step == .flat ? 6 : 4)
            )

        case .step2:
            path.move(to: CGPoint(x: w * 0.5, y: 0))
            path.addLine(to: CGPoint(x: w,     y: h * 0.35))
            path.addLine(to: CGPoint(x: w,     y: h))
            path.addLine(to: CGPoint(x: 0,     y: h))
            path.addLine(to: CGPoint(x: 0,     y: h * 0.35))
            path.closeSubpath()

        case .step3:
            path.move(to: CGPoint(x: w * 0.5, y: 0))
            path.addLine(to: CGPoint(x: w,     y: h * 0.65))
            path.addLine(to: CGPoint(x: w,     y: h))
            path.addLine(to: CGPoint(x: 0,     y: h))
            path.addLine(to: CGPoint(x: 0,     y: h * 0.65))
            path.closeSubpath()

        case .step4, .completed:
            let ox = w * 0.25
            path.move(to: CGPoint(x: ox,            y: 0))
            path.addLine(to: CGPoint(x: ox + w * 0.5, y: h * 0.35))
            path.addLine(to: CGPoint(x: ox + w * 0.5, y: h))
            path.addLine(to: CGPoint(x: ox,            y: h))
            path.closeSubpath()
        }

        return path
    }
}

// MARK: - Step 1 Fold: Fold in half vertically

struct Step1FoldFlap: Shape {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let p = progress

        let leftEdgeX = 0.0 + w * p

        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addLine(to: CGPoint(x: leftEdgeX, y: 0))
        path.addLine(to: CGPoint(x: leftEdgeX, y: h))
        path.addLine(to: CGPoint(x: w * 0.5, y: h))
        path.closeSubpath()

        return path
    }
}

// MARK: - Step 2 Fold: Top corners fold to center

struct Step2FoldFlap: Shape {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let p = progress

        let creaseTop    = CGPoint(x: w * 0.5, y: 0)
        let creaseBottom = CGPoint(x: w,        y: h * 0.35)
        let origCorner   = CGPoint(x: w, y: 0)

        let foldedCorner = CGPoint(
            x: origCorner.x + (w * 0.5 - origCorner.x) * p,
            y: origCorner.y + (h * 0.35 - origCorner.y) * p
        )

        path.move(to: creaseTop)
        path.addLine(to: foldedCorner)
        path.addLine(to: creaseBottom)
        path.closeSubpath()

        return path
    }
}

// MARK: - Step 3 Fold: Diagonal edges fold to center again

struct Step3FoldFlap: Shape {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let p = progress

        let tipTop = CGPoint(x: w * 0.5, y: 0)

        let oldPoint = CGPoint(x: w, y: h * 0.35)
        let foldedPoint = CGPoint(
            x: oldPoint.x + (w * 0.5 - oldPoint.x) * p,
            y: oldPoint.y + (h * 0.65 - oldPoint.y) * p
        )

        let creaseBottom = CGPoint(
            x: w,
            y: h * 0.35 + (h * 0.65 - h * 0.35) * p
        )

        path.move(to: tipTop)
        path.addLine(to: foldedPoint)
        path.addLine(to: creaseBottom)
        path.closeSubpath()

        return path
    }
}

// MARK: - Step 4 Fold: Fold in half → final airplane (CENTERED)

struct Step4FoldFlap: Shape {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let p = progress

        let shift = -w * 0.25 * p
        let foldLineX = w * 0.5

        let leftDiagX = (0.0 + (w - 0.0) * p) + shift
        let leftDiag = CGPoint(x: leftDiagX, y: h * 0.65)

        let leftBottomX = (0.0 + (w - 0.0) * p) + shift
        let leftBottom = CGPoint(x: leftBottomX, y: h)

        path.move(to: CGPoint(x: foldLineX + shift, y: 0))
        path.addLine(to: leftDiag)
        path.addLine(to: leftBottom)
        path.addLine(to: CGPoint(x: foldLineX + shift, y: h))
        path.closeSubpath()

        return path
    }
}

// MARK: - Crease Line Shape

struct CreaseLineShape: Shape {
    let step: FoldStep

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        switch step {
        case .flat:
            break
        case .step1:
            path.move(to: CGPoint(x: w * 0.5, y: 0))
            path.addLine(to: CGPoint(x: w * 0.5, y: h))
        case .step2:
            path.move(to: CGPoint(x: 0, y: h * 0.35))
            path.addLine(to: CGPoint(x: w * 0.5, y: 0))
            path.addLine(to: CGPoint(x: w, y: h * 0.35))
        case .step3:
            path.move(to: CGPoint(x: 0, y: h * 0.65))
            path.addLine(to: CGPoint(x: w * 0.5, y: 0))
            path.addLine(to: CGPoint(x: w, y: h * 0.65))
        case .step4:
            let ox = w * 0.25
            path.move(to: CGPoint(x: ox + w * 0.25, y: 0))
            path.addLine(to: CGPoint(x: ox + w * 0.25, y: h))
        case .completed:
            let ox = w * 0.25
            path.move(to: CGPoint(x: ox, y: 0))
            path.addLine(to: CGPoint(x: ox + w * 0.5, y: h))
        }

        return path
    }
}

// MARK: - Animated Drag Guide Arrow

struct FoldGuideArrow: View {
    let step: FoldStep
    @State private var isPulsing = false
    @State private var isFloating = false

    private let paperWidth: CGFloat = 200
    private let paperHeight: CGFloat = 280

    var body: some View {
        if step != .completed && step.rawValue <= 4 {
            let pos = arrowAnchor(for: step)

            ZStack {
                Circle()
                    .fill(PaperPalette.accent.opacity(0.12))
                    .frame(width: 50, height: 50)
                    .scaleEffect(isPulsing ? 1.6 : 0.8)
                    .opacity(isPulsing ? 0.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 1.6)
                            .repeatForever(autoreverses: false),
                        value: isPulsing
                    )

                Circle()
                    .fill(PaperPalette.accent.opacity(0.08))
                    .frame(width: 50, height: 50)
                    .scaleEffect(isPulsing ? 2.0 : 0.6)
                    .opacity(isPulsing ? 0.0 : 0.3)
                    .animation(
                        .easeInOut(duration: 1.6)
                            .repeatForever(autoreverses: false)
                            .delay(0.35),
                        value: isPulsing
                    )

                Circle()
                    .fill(PaperPalette.accent.opacity(0.25))
                    .frame(width: 28, height: 28)

                Circle()
                    .stroke(PaperPalette.accent.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 36, height: 36)

                arrowIcon(for: step.dragZone.direction)
                    .offset(arrowFloatOffset(step.dragZone.direction))
                    .animation(
                        .easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: isFloating
                    )
            }
            .position(x: pos.x, y: pos.y)
            .frame(width: paperWidth, height: paperHeight)
            .allowsHitTesting(false)
            .onAppear {
                isPulsing = true
                isFloating = true
            }
            .id(step)
        }
    }

    private func arrowAnchor(for step: FoldStep) -> CGPoint {
        switch step {
        case .flat:         return CGPoint(x: 50, y: 140)
        case .step1:        return CGPoint(x: 150, y: 40)
        case .step2:        return CGPoint(x: 150, y: 60)
        case .step3:        return CGPoint(x: 50, y: 160)
        case .step4, .completed: return CGPoint(x: 100, y: 140)
        }
    }

    @ViewBuilder
    private func arrowIcon(for direction: DragZone.DragDirection) -> some View {
        let rotation: Double = {
            switch direction {
            case .up:            return 0
            case .down:          return 180
            case .trailing:      return 90
            case .leading:       return -90
            case .towardCenter:  return 135
            }
        }()

        VStack(spacing: 2) {
            Image(systemName: "chevron.up")
                .font(.system(size: 14, weight: .semibold))
            Image(systemName: "chevron.up")
                .font(.system(size: 14, weight: .semibold))
                .opacity(0.4)
        }
        .foregroundColor(PaperPalette.accent)
        .rotationEffect(.degrees(rotation))
        .shadow(color: PaperPalette.accent.opacity(0.4), radius: 4)
    }

    private func arrowFloatOffset(_ direction: DragZone.DragDirection) -> CGSize {
        let amount: CGFloat = isFloating ? 8 : -3
        switch direction {
        case .up:            return CGSize(width: 0,       height: -amount)
        case .down:          return CGSize(width: 0,       height: amount)
        case .trailing:      return CGSize(width: amount,  height: 0)
        case .leading:       return CGSize(width: -amount, height: 0)
        case .towardCenter:  return CGSize(width: -amount * 0.7, height: amount * 0.7)
        }
    }
}

// MARK: - Drag Zone Highlight

struct DragZoneHighlight: View {
    let step: FoldStep
    @State private var glowing = false

    private let paperWidth: CGFloat = 200
    private let paperHeight: CGFloat = 280

    var body: some View {
        if step != .completed {
            let zone = step.dragZone

            RoundedRectangle(cornerRadius: 16)
                .fill(PaperPalette.accent.opacity(glowing ? 0.06 : 0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            PaperPalette.accent.opacity(glowing ? 0.15 : 0.05),
                            lineWidth: 1
                        )
                )
                .frame(width: zone.rect.width, height: zone.rect.height)
                .position(
                    x: zone.rect.midX,
                    y: zone.rect.midY
                )
                .frame(width: paperWidth, height: paperHeight)
                .allowsHitTesting(false)
                .animation(
                    .easeInOut(duration: 1.8)
                        .repeatForever(autoreverses: true),
                    value: glowing
                )
                .onAppear { glowing = true }
                .id(step)
        }
    }
}

// MARK: - Main PaperView

struct PaperView: View {
    let step: FoldStep
    let dragOffset: CGSize
    let isDragging: Bool
    let isInZone: Bool

    private let paperWidth: CGFloat = 200
    private let paperHeight: CGFloat = 280

    private var activeStep1: CGFloat { step.rawValue >= 1 ? 1 : 0 }
    private var activeStep2: CGFloat { step.rawValue >= 2 ? 1 : 0 }
    private var activeStep3: CGFloat { step.rawValue >= 3 ? 1 : 0 }
    private var activeStep4: CGFloat { step.rawValue >= 4 ? 1 : 0 }

    private var dragProgress: CGFloat {
        guard isDragging, isInZone, step != .completed else { return 0 }
        let threshold = step.dragThreshold
            
        let drag: CGFloat
        switch step.primaryDragAxis {
        case .horizontal:
            drag = abs(dragOffset.width)
        case .vertical:
            drag = abs(dragOffset.height)
        case .any:
            drag = max(abs(dragOffset.height), abs(dragOffset.width))
        }
            
        return min(drag / threshold, 0.99)
    }

    private var previewStep1: CGFloat {
        step.rawValue == 0 ? dragProgress : activeStep1
    }
    private var previewStep2: CGFloat {
        step.rawValue == 1 ? dragProgress : activeStep2
    }
    private var previewStep3: CGFloat {
        step.rawValue == 2 ? dragProgress : activeStep3
    }
    private var previewStep4: CGFloat {
        step.rawValue == 3 ? dragProgress : activeStep4
    }

    var body: some View {
        ZStack {
            PaperOutlineShape(step: step)
                .fill(Color.black.opacity(0.10))
                .frame(width: paperWidth, height: paperHeight)
                .blur(radius: 14)
                .offset(x: 4, y: 10)

            ZStack {
                basePaperLayer

                if step.rawValue >= 1 && step.rawValue <= 3 {
                    centerCreaseLine
                }

                if previewStep1 > 0 { step1Layer }
                if previewStep2 > 0 { step2Layer }
                if previewStep3 > 0 { step3Layer }
                if previewStep4 > 0 { step4Layer }

                creaseOverlay
            }
            .frame(width: paperWidth, height: paperHeight)
            .clipShape(PaperOutlineShape(step: step))

            PaperOutlineShape(step: step)
                .stroke(PaperPalette.foldLine.opacity(0.4), lineWidth: 0.8)
                .frame(width: paperWidth, height: paperHeight)

            if !isDragging {
                DragZoneHighlight(step: step)
            }

            if !isDragging {
                FoldGuideArrow(step: step)
            }

            if isDragging && !isInZone {
                wrongZoneIndicator
            }
        }
        .frame(width: paperWidth, height: paperHeight)
    }

    private var wrongZoneIndicator: some View {
        VStack(spacing: 4) {
            Image(systemName: "xmark.circle")
                .font(.system(size: 20, weight: .light))
                .foregroundColor(Color.red.opacity(0.4))

            Text("Drag here →")
                .font(.system(size: 10, weight: .light, design: .rounded))
                .foregroundColor(Color.red.opacity(0.3))
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: isDragging)
    }

    private var basePaperLayer: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        PaperPalette.paperWhite,
                        PaperPalette.paperCream
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: paperWidth, height: paperHeight)
    }

    private var centerCreaseLine: some View {
        Path { p in
            p.move(to: CGPoint(x: paperWidth * 0.5, y: 0))
            p.addLine(to: CGPoint(x: paperWidth * 0.5, y: paperHeight))
        }
        .stroke(
            PaperPalette.foldLine,
            style: StrokeStyle(lineWidth: 0.8, dash: [6, 4])
        )
        .frame(width: paperWidth, height: paperHeight)
    }

    private var step1Layer: some View {
        ZStack {
            Step1FoldFlap(progress: previewStep1)
                .fill(
                    LinearGradient(
                        colors: [
                            PaperPalette.paperShade.opacity(0.6),
                            PaperPalette.paperShade
                        ],
                        startPoint: .trailing,
                        endPoint: .leading
                    )
                )
                .frame(width: paperWidth, height: paperHeight)

            Step1FoldFlap(progress: previewStep1)
                .fill(
                    LinearGradient(
                        colors: [
                            PaperPalette.paperWhite,
                            PaperPalette.paperCream.opacity(0.9)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: paperWidth, height: paperHeight)
                .opacity(previewStep1 > 0.05 ? 0.9 : 0)

            Step1FoldFlap(progress: previewStep1)
                .stroke(PaperPalette.foldLine, lineWidth: 1.0)
                .frame(width: paperWidth, height: paperHeight)
        }
        .animation(.easeInOut(duration: 0.4), value: previewStep1)
    }

    private var step2Layer: some View {
        ZStack {
            Step2FoldFlap(progress: previewStep2)
                .fill(PaperPalette.paperShade)
                .frame(width: paperWidth, height: paperHeight)

            Step2FoldFlap(progress: previewStep2)
                .fill(
                    LinearGradient(
                        colors: [
                            PaperPalette.paperCream,
                            PaperPalette.paperWhite.opacity(0.9)
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                )
                .frame(width: paperWidth, height: paperHeight)
                .scaleEffect(x: -1, y: 1)
                .opacity(previewStep2 > 0.05 ? 1 : 0)

            Step2FoldFlap(progress: previewStep2)
                .stroke(PaperPalette.foldLine, lineWidth: 1.5)
                .frame(width: paperWidth, height: paperHeight)
        }
        .animation(.easeInOut(duration: 0.4), value: previewStep2)
    }

    private var step3Layer: some View {
        ZStack {
            Step3FoldFlap(progress: previewStep3)
                .fill(
                    LinearGradient(
                        colors: [
                            PaperPalette.paperShade.opacity(0.5),
                            PaperPalette.paperShade.opacity(0.85)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: paperWidth, height: paperHeight)

            Step3FoldFlap(progress: previewStep3)
                .fill(
                    LinearGradient(
                        colors: [
                            PaperPalette.paperWhite.opacity(0.95),
                            PaperPalette.paperCream.opacity(0.8)
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                )
                .frame(width: paperWidth, height: paperHeight)
                .scaleEffect(x: -1, y: 1)
                .opacity(previewStep3 > 0.05 ? 1 : 0)

            Step3FoldFlap(progress: previewStep3)
                .stroke(PaperPalette.foldLine, lineWidth: 1.2)
                .frame(width: paperWidth, height: paperHeight)
        }
        .animation(.easeInOut(duration: 0.4), value: previewStep3)
    }

    private var step4Layer: some View {
        ZStack {
            Step4FoldFlap(progress: previewStep4)
                .fill(
                    LinearGradient(
                        colors: [
                            PaperPalette.paperShade.opacity(0.5),
                            PaperPalette.paperShade.opacity(0.85)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: paperWidth, height: paperHeight)

            Step4FoldFlap(progress: previewStep4)
                .fill(
                    LinearGradient(
                        colors: [
                            PaperPalette.paperWhite,
                            PaperPalette.paperCream.opacity(0.9)
                        ],
                        startPoint: .trailing,
                        endPoint: .leading
                    )
                )
                .frame(width: paperWidth, height: paperHeight)
                .opacity(previewStep4 > 0.1 ? 0.85 : 0)

            Step4FoldFlap(progress: previewStep4)
                .stroke(PaperPalette.foldLine, lineWidth: 1.2)
                .frame(width: paperWidth, height: paperHeight)
        }
        .animation(.easeInOut(duration: 0.4), value: previewStep4)
    }

    private var creaseOverlay: some View {
        Canvas { context, size in
            for pastStep in FoldStep.allCases {
                guard pastStep.rawValue > 0,
                      pastStep.rawValue <= step.rawValue,
                      pastStep != .completed
                else { continue }

                if pastStep == .step1 { continue }

                let crease = CreaseLineShape(step: pastStep)
                let cPath  = crease.path(
                    in: CGRect(origin: .zero, size: size)
                )

                context.stroke(
                    cPath,
                    with: .color(PaperPalette.foldLine),
                    style: StrokeStyle(
                        lineWidth: 1,
                        dash: [5, 4]
                    )
                )
            }
        }
        .frame(width: paperWidth, height: paperHeight)
        .allowsHitTesting(false)
    }
}

// MARK: - Drag Hint Arrow (shown while dragging)

struct DragHintArrow: View {
    let dragOffset: CGSize

    var arrowOpacity: Double {
        min(abs(Double(dragOffset.height)) / 40.0, 0.7)
    }

    var isUpward: Bool { dragOffset.height < 0 }

    var body: some View {
        VStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: "chevron.up")
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(PaperPalette.accent)
                    .opacity(max(0, arrowOpacity - Double(i) * 0.2))
            }
        }
        .rotationEffect(isUpward ? .zero : .degrees(180))
        .offset(y: isUpward ? -30 : 30)
        .animation(.easeOut(duration: 0.15), value: dragOffset.height)
    }
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(
            in: CharacterSet.alphanumerics.inverted
        )
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (
                255,
                (int >> 8) * 17,
                (int >> 4 & 0xF) * 17,
                (int & 0xF) * 17
            )
        case 6:
            (a, r, g, b) = (
                255,
                int >> 16,
                int >> 8 & 0xFF,
                int & 0xFF
            )
        case 8:
            (a, r, g, b) = (
                int >> 24,
                int >> 16 & 0xFF,
                int >> 8 & 0xFF,
                int & 0xFF
            )
        default:
            (a, r, g, b) = (255, 180, 180, 180)
        }

        self.init(
            .sRGB,
            red:     Double(r) / 255,
            green:   Double(g) / 255,
            blue:    Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
