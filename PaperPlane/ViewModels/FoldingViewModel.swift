//
//  FoldingViewModel.swift
//  PaperPlane
//
//  Created by Jonathan Basuki on 23/03/26.
//

import SwiftUI
import Combine

// MARK: - Fold Step Enum

enum FoldStep: Int, CaseIterable {
    case flat       = 0
    case step1      = 1
    case step2      = 2
    case step3      = 3
    case step4      = 4
    case completed  = 5

    var dragThreshold: CGFloat {
        switch self {
        case .flat:      return 55
        case .step1:     return 55
        case .step2:     return 55
        case .step3:     return 55
        case .step4:     return 60
        case .completed: return 0
        }
    }

    var primaryDragAxis: DragAxis {
        switch self {
        case .flat:      return .horizontal
        case .step1:     return .vertical
        case .step2:     return .vertical
        case .step3:     return .horizontal
        case .step4:     return .any
        case .completed: return .any
        }
    }

    enum DragAxis {
        case horizontal, vertical, any
    }

    var paperRotationAngle: Double {
        switch self {
        case .flat:      return 0
        case .step1:     return -15
        case .step2:     return -30
        case .step3:     return -45
        case .step4:     return -60
        case .completed: return -90
        }
    }

    var scale: CGFloat {
        switch self {
        case .flat:      return 1.0
        case .step1:     return 0.95
        case .step2:     return 0.90
        case .step3:     return 0.85
        case .step4:     return 0.80
        case .completed: return 0.75
        }
    }

    var instructionText: String {
        switch self {
        case .flat:      return "Drag right to fold in half.."
        case .step1:     return "Fold the top corners down.."
        case .step2:     return "Fold the edges to the center.."
        case .step3:     return "Fold in half again.."
        case .step4:     return "Crease the nose sharp.."
        case .completed: return ""
        }
    }

    var next: FoldStep? {
        FoldStep(rawValue: self.rawValue + 1)
    }

    var isCompleted: Bool { self == .completed }
}

// MARK: - FoldingViewModel

@MainActor
final class FoldingViewModel: ObservableObject {
    @Published var currentStep: FoldStep = .flat
    @Published var dragOffset: CGSize = .zero
    @Published var isDragging: Bool = false
    @Published var showStartButton: Bool = false
    @Published var paperOpacity: Double = 1.0

    private let haptics = HapticsManager.shared
    private var accumulatedDrag: CGFloat = 0

    var stepProgress: Double {
        Double(currentStep.rawValue) / Double(FoldStep.allCases.count - 1)
    }

    var isCompleted: Bool {
        currentStep == .completed
    }

    var paper3DRotationX: Double {
        let baseDeg = currentStep.paperRotationAngle
        if isDragging {
            let dragInfluence = Double(-dragOffset.height / 4)
                .clamped(to: -20...20)
            return baseDeg + dragInfluence
        }
        return baseDeg
    }

    var paper3DRotationZ: Double {
        switch currentStep {
        case .flat:      return 0
        case .step1:     return -5
        case .step2:     return -10
        case .step3:     return -15
        case .step4:     return -20
        case .completed: return 0
        }
    }

    var currentScale: CGFloat {
        let base = currentStep.scale
        if isDragging {
            let drag = effectiveDrag(from: dragOffset)
            return base * (1 - drag / 2000)
        }
        return base
    }

    /// Returns the relevant drag magnitude based on which axis this step uses.
    private func effectiveDrag(from offset: CGSize) -> CGFloat {
        switch currentStep.primaryDragAxis {
        case .horizontal:
            return abs(offset.width)
        case .vertical:
            return abs(offset.height)
        case .any:
            return max(abs(offset.height), abs(offset.width))
        }
    }

    func onDragChanged(_ value: DragGesture.Value) {
        isDragging = true
        dragOffset = value.translation
        accumulatedDrag = effectiveDrag(from: value.translation)
    }

    func onDragEnded(_ value: DragGesture.Value) {
        isDragging = false
        dragOffset = .zero

        let finalDrag = effectiveDrag(from: value.translation)

        if finalDrag >= currentStep.dragThreshold {
            advanceStep()
        }
        accumulatedDrag = 0
    }

    private func advanceStep() {
        guard let next = currentStep.next else { return }

        withAnimation(.easeInOut(duration: 0.5)) {
            currentStep = next
        }

        haptics.playFoldFeedback()

        if next == .completed {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    self?.showStartButton = true
                }
            }
        }
    }

    func reset() {
        withAnimation(.easeInOut(duration: 0.4)) {
            currentStep = .flat
            showStartButton = false
            dragOffset = .zero
            isDragging = false
        }
    }
}

// MARK: - Clamp Helper

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
