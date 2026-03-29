//
//  FoldingView.swift
//  PaperPlane
//

import SwiftUI
import Combine

struct FoldingView: View {
    @StateObject private var vm = FoldingViewModel()
    @EnvironmentObject private var appState: AppState

    @State private var titleAppeared = false
    @State private var instructionShake = false
    @State private var completionGlow = false
    @State private var stepIndicatorBounce = false

    @State private var dragStartedInZone = false
    @State private var dragStartLocation: CGPoint = .zero
    @State private var showWrongZoneHint = false

    var body: some View {
        ZStack {
            FoldingBackgroundView(progress: vm.stepProgress)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                    .padding(.top, 60)

                Spacer()

                centralCanvas

                Spacer()

                bottomSection
                    .padding(.bottom, 48)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if vm.isCompleted && vm.showStartButton {
                VStack {
                    Spacer()
                    startFlyingButton
                        .padding(.bottom, 60)
                        .transition(
                            .scale(scale: 0.7)
                                .combined(with: .opacity)
                        )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                titleAppeared = true
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Gust of Flow")
                .font(.system(size: 32, weight: .regular, design: .rounded))
                .foregroundColor(Color(hex: "#4A4A5A"))
                .opacity(titleAppeared ? 1 : 0)
                .offset(y: titleAppeared ? 0 : -20)

            Text("fold • form • fly")
                .font(.system(size: 13, weight: .light, design: .rounded))
                .foregroundColor(Color(hex: "#8A8A9A"))
                .kerning(3)
                .opacity(titleAppeared ? 1 : 0)
                .offset(y: titleAppeared ? 0 : -10)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .animation(.easeOut(duration: 0.8), value: titleAppeared)
    }

    private var centralCanvas: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32)
                .fill(Color.white.opacity(0.55))
                .frame(
                    width: cardWidth,
                    height: cardHeight
                )
                .shadow(
                    color: Color.black.opacity(0.07),
                    radius: 24, x: 0, y: 10
                )
                .animation(
                    .spring(response: 0.55, dampingFraction: 0.80),
                    value: vm.currentStep
                )

            if vm.isCompleted {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "#A8D8EA").opacity(0.35),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(completionGlow ? 1.2 : 0.85)
                        .animation(
                            .easeInOut(duration: 1.6)
                                .repeatForever(autoreverses: true),
                            value: completionGlow
                        )

                    PlaneMorphView()
                }
                .frame(width: cardWidth, height: cardHeight)
                .onAppear { completionGlow = true }
                .transition(.scale.combined(with: .opacity))

            } else {
                ZStack {
                    PaperView(
                        step: vm.currentStep,
                        dragOffset: vm.dragOffset,
                        isDragging: vm.isDragging,
                        isInZone: dragStartedInZone
                    )

                    if vm.isDragging && dragStartedInZone {
                        DragHintArrow(dragOffset: vm.dragOffset)
                            .offset(y: dragArrowOffset)
                    }
                }
                .rotation3DEffect(
                    .degrees(
                        vm.isDragging && dragStartedInZone
                            ? Double(-vm.dragOffset.height / 20)
                                .clamped(to: -6...6)
                            : 0
                    ),
                    axis: (x: 1, y: 0, z: 0),
                    perspective: 0.3
                )
                .scaleEffect(vm.currentScale)
                .shadow(
                    color: Color.black.opacity(
                        vm.isDragging && dragStartedInZone ? 0.14 : 0.06
                    ),
                    radius: vm.isDragging && dragStartedInZone ? 18 : 10,
                    x: 0,
                    y: vm.isDragging && dragStartedInZone ? 8 : 4
                )
                .gesture(foldGesture)
                .animation(.interactiveSpring(), value: vm.isDragging)
                .animation(
                    .spring(response: 0.55, dampingFraction: 0.80),
                    value: vm.currentStep
                )
            }
        }
        .frame(maxWidth: .infinity)
        .animation(
            .spring(response: 0.55, dampingFraction: 0.80),
            value: vm.isCompleted
        )
    }

    private var cardWidth: CGFloat {
        switch vm.currentStep {
        case .flat:      return 280
        case .step1:     return 290
        case .step2:     return 290
        case .step3:     return 240
        case .step4:     return 260
        case .completed: return 300
        }
    }

    private var cardHeight: CGFloat {
        switch vm.currentStep {
        case .flat:      return 360
        case .step1:     return 360
        case .step2:     return 340
        case .step3:     return 300
        case .step4:     return 280
        case .completed: return 220
        }
    }

    private var dragArrowOffset: CGFloat {
        switch vm.currentStep {
        case .flat:      return 145
        case .step1:     return 140
        case .step2:     return 130
        case .step3:     return 110
        case .step4:     return 105
        case .completed: return 80
        }
    }

    private var bottomSection: some View {
        VStack(spacing: 20) {
            stepProgressDots

            Group {
                if showWrongZoneHint {
                    Text("Drag on the highlighted area ↗")
                        .foregroundColor(Color.red.opacity(0.5))
                } else {
                    Text(vm.currentStep.instructionText)
                        .foregroundColor(Color(hex: "#6A6A7A"))
                }
            }
            .font(.system(size: 15, weight: .light, design: .rounded))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 48)
            .frame(maxWidth: .infinity)
            .offset(x: instructionShake ? 4 : 0)
            .animation(
                .easeInOut(duration: 0.08)
                    .repeatCount(4, autoreverses: true),
                value: instructionShake
            )
            .id(showWrongZoneHint ? "wrong" : "\(vm.currentStep)")
            .transition(
                .asymmetric(
                    insertion: .move(edge: .bottom)
                        .combined(with: .opacity),
                    removal: .move(edge: .top)
                        .combined(with: .opacity)
                )
            )

            if vm.currentStep.rawValue > 0 && !vm.isCompleted {
                Button(action: {
                    withAnimation(.easeInOut) {
                        vm.reset()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 11))
                        Text("Start over")
                            .font(.system(
                                size: 12,
                                weight: .light,
                                design: .rounded
                            ))
                    }
                    .foregroundColor(Color(hex: "#AAAAAA"))
                }
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.3), value: vm.currentStep)
        .animation(.easeInOut(duration: 0.2), value: showWrongZoneHint)
    }

    private var stepProgressDots: some View {
        HStack(spacing: 10) {
            ForEach(FoldStep.allCases, id: \.self) { step in
                singleDot(for: step)
            }
        }
        .frame(maxWidth: .infinity)
        .onReceive(vm.$currentStep) { _ in
            stepIndicatorBounce = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                stepIndicatorBounce = false
            }
        }
    }

    private func singleDot(for step: FoldStep) -> some View {
        let isActive  = vm.currentStep.rawValue >= step.rawValue
        let isCurrent = vm.currentStep == step

        return ZStack {
            if isCurrent {
                Circle()
                    .stroke(
                        Color(hex: "#A8D8EA").opacity(0.45),
                        lineWidth: 2
                    )
                    .frame(width: 18, height: 18)
                    .scaleEffect(stepIndicatorBounce ? 1.25 : 1.0)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.55),
                        value: stepIndicatorBounce
                    )
            }

            Circle()
                .fill(
                    isActive
                        ? Color(hex: "#A8D8EA")
                        : Color(hex: "#DDDDDD")
                )
                .frame(
                    width:  isCurrent ? 11 : 7,
                    height: isCurrent ? 11 : 7
                )
        }
        .frame(width: 20, height: 20)
        .animation(
            .spring(response: 0.4, dampingFraction: 0.6),
            value: vm.currentStep
        )
    }

    private var startFlyingButton: some View {
        Button(action: {
            appState.navigateToFlying()
        }) {
            HStack(spacing: 12) {
                Text("Start Flying")
                    .font(.system(
                        size: 18,
                        weight: .medium,
                        design: .rounded
                    ))
                    .foregroundColor(.white)

                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 16)
            .background(buttonBackground)
            .shadow(
                color: Color(hex: "#A8D8EA").opacity(0.55),
                radius: 18, x: 0, y: 7
            )
        }
        .buttonStyle(BouncyButtonStyle())
    }

    private var buttonBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(hex: "#7FC4D4").opacity(0.4))
                .blur(radius: 10)
                .padding(-6)

            RoundedRectangle(cornerRadius: 30)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "#A8D8EA"),
                            Color(hex: "#92c7d4")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 30)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.22),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
        }
    }

    private var foldGesture: some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .local)
            .onChanged { value in
                if !vm.isDragging {
                    let paperW: CGFloat = 200
                    let paperH: CGFloat = 280
                    let paperOriginX = (cardWidth - paperW) / 2
                    let paperOriginY = (cardHeight - paperH) / 2

                    let localStart = CGPoint(
                        x: value.startLocation.x - paperOriginX,
                        y: value.startLocation.y - paperOriginY
                    )

                    dragStartLocation = localStart
                    dragStartedInZone = vm.currentStep.isInDragZone(localStart)

                    if !dragStartedInZone {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showWrongZoneHint = true
                        }
                    } else {
                        showWrongZoneHint = false
                    }
                }

                if dragStartedInZone {
                    vm.onDragChanged(value)
                } else {
                    vm.isDragging = true
                    vm.dragOffset = value.translation
                }
            }
            .onEnded { value in
                if dragStartedInZone {
                    vm.onDragEnded(value)

                    let drag: CGFloat
                    switch vm.currentStep.primaryDragAxis {
                    case .horizontal:
                        drag = abs(value.translation.width)
                    case .vertical:
                        drag = abs(value.translation.height)
                    case .any:
                        drag = max(abs(value.translation.height), abs(value.translation.width))
                    }

                    if !vm.isCompleted
                        && drag > 15
                        && drag < vm.currentStep.dragThreshold {
                        instructionShake = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            instructionShake = false
                        }
                    }
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        vm.isDragging = false
                        vm.dragOffset = .zero
                    }

                    instructionShake = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        instructionShake = false
                    }
                }

                dragStartedInZone = false

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showWrongZoneHint = false
                    }
                }
            }
    }
}

// MARK: - Folding Background View

struct FoldingBackgroundView: View {
    let progress: Double

    private var topColor: Color {
        let r = (0.98 - progress * 0.08).clamped(to: 0...1)
        let g = (0.97 - progress * 0.05).clamped(to: 0...1)
        let b = (0.96 + progress * 0.04).clamped(to: 0...1)
        return Color(red: r, green: g, blue: b)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "#F5F5F8"),
                    Color(hex: "#D0E9F2"),
                    Color(hex: "#F5F5F8"),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .animation(.easeInOut(duration: 0.7), value: progress)

            Group {
                blobCircle(size: 300, x: -100, y: -280, opacity: 0.06)
                blobCircle(size: 250, x:  120, y: -180, opacity: 0.04)
                blobCircle(size: 350, x:  -60, y:  120, opacity: 0.04)
                blobCircle(size: 280, x:  130, y:  250, opacity: 0.05)
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "#A8D8EA")
                                .opacity(progress * 0.18),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 220
                    )
                )
                .frame(width: 440, height: 440)
                .offset(y: -120)
                .blur(radius: 30)
        }
    }

    private func blobCircle(
        size: CGFloat,
        x: CGFloat,
        y: CGFloat,
        opacity: Double
    ) -> some View {
        Circle()
            .fill(Color.white.opacity(opacity))
            .frame(width: size, height: size)
            .offset(x: x, y: y)
            .blur(radius: 40)
    }
}

// MARK: - Bouncy Button Style

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(
                .spring(response: 0.28, dampingFraction: 0.6),
                value: configuration.isPressed
            )
    }
}

#Preview {
    FoldingView()
        .environmentObject(AppState())
}
