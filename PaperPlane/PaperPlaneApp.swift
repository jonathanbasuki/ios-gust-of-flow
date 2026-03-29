//
//  PaperPlaneApp.swift
//  PaperPlane
//
//  Created by Jonathan Basuki on 23/03/26.
//

import SwiftUI
import Combine

// MARK: - App Navigation State
enum AppScreen {
    case folding
    case flying
}

// MARK: - Root App State (ObservableObject for nav)
final class AppState: ObservableObject {
    @Published var currentScreen: AppScreen = .folding
    
    func navigateToFlying() {
        withAnimation(.easeInOut(duration: 0.6)) {
            currentScreen = .flying
        }
    }
    
    func navigateToFolding() {
        withAnimation(.easeInOut(duration: 0.6)) {
            currentScreen = .folding
        }
    }
}

// MARK: - App Entry
@main
struct PaperPlaneApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}

// MARK: - Root View (Navigation Container)
struct RootView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            switch appState.currentScreen {
            case .folding:
                FoldingView()
                    .transition(
                        .asymmetric(
                            insertion: .opacity,
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )
            case .flying:
                FlyingView()
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
            }
        }
        // Smooth screen-level transitions
        .animation(.easeInOut(duration: 0.5), value: appState.currentScreen)
    }
}
