//
//  FlyingView.swift
//  PaperPlane
//
//  Created by Jonathan Basuki on 23/03/26.
//

import SwiftUI
import Combine

// MARK: - Weather State

enum WeatherPhase: CaseIterable {
    case clear, cloudy, rain, heavyRain
    
    var skyDarken: Double {
        switch self {
        case .clear:     return 0.0
        case .cloudy:    return 0.12
        case .rain:      return 0.25
        case .heavyRain: return 0.38
        }
    }
    
    var cloudDarken: Double {
        switch self {
        case .clear:     return 0.0
        case .cloudy:    return 0.15
        case .rain:      return 0.30
        case .heavyRain: return 0.45
        }
    }
    
    var rainIntensity: Double {
        switch self {
        case .clear:     return 0.0
        case .cloudy:    return 0.0
        case .rain:      return 0.6
        case .heavyRain: return 1.0
        }
    }
    
    var hasLightning: Bool {
        self == .heavyRain
    }
}

// MARK: - Time of Day

enum TimeOfDay: CaseIterable {
    case day, sunset, night, sunrise
    
    var skyTopColor: Color {
        switch self {
        case .day:     return Color(red: 0.53, green: 0.78, blue: 0.92)
        case .sunset:  return Color(red: 0.85, green: 0.45, blue: 0.30)
        case .night:   return Color(red: 0.06, green: 0.08, blue: 0.18)
        case .sunrise: return Color(red: 0.90, green: 0.55, blue: 0.35)
        }
    }
    
    var skyBottomColor: Color {
        switch self {
        case .day:     return Color(red: 0.72, green: 0.88, blue: 0.95)
        case .sunset:  return Color(red: 0.95, green: 0.70, blue: 0.40)
        case .night:   return Color(red: 0.05, green: 0.06, blue: 0.14)
        case .sunrise: return Color(red: 0.95, green: 0.75, blue: 0.50)
        }
    }
    
    var groundTint: Color {
        switch self {
        case .day:     return .white
        case .sunset:  return Color(red: 1.0, green: 0.85, blue: 0.70)
        case .night:   return Color(red: 0.35, green: 0.40, blue: 0.55)
        case .sunrise: return Color(red: 1.0, green: 0.88, blue: 0.75)
        }
    }
    
    var treeTint: Color {
        switch self {
        case .day:     return .white
        case .sunset:  return Color(red: 0.95, green: 0.80, blue: 0.65)
        case .night:   return Color(red: 0.30, green: 0.35, blue: 0.50)
        case .sunrise: return Color(red: 0.95, green: 0.82, blue: 0.70)
        }
    }
    
    var mountainTint: Color {
        switch self {
        case .day:     return .white
        case .sunset:  return Color(red: 0.90, green: 0.72, blue: 0.58)
        case .night:   return Color(red: 0.25, green: 0.30, blue: 0.45)
        case .sunrise: return Color(red: 0.92, green: 0.75, blue: 0.60)
        }
    }
    
    var overlayDarken: Double {
        switch self {
        case .day:     return 0.0
        case .sunset:  return 0.05
        case .night:   return 0.30
        case .sunrise: return 0.05
        }
    }
    
    var showStars: Bool {
        self == .night
    }
    
    var showMoon: Bool {
        self == .night
    }
    
    var showSun: Bool {
        self == .day || self == .sunset || self == .sunrise
    }
    
    var sunTint: Color {
        switch self {
        case .day:     return .white
        case .sunset:  return Color(red: 1.0, green: 0.50, blue: 0.20)
        case .sunrise: return Color(red: 1.0, green: 0.55, blue: 0.25)
        case .night:   return .clear
        }
    }
    
    var cloudTint: Color {
        switch self {
        case .day:     return .white
        case .sunset:  return Color(red: 1.0, green: 0.78, blue: 0.60)
        case .night:   return Color(red: 0.35, green: 0.38, blue: 0.50)
        case .sunrise: return Color(red: 1.0, green: 0.80, blue: 0.65)
        }
    }
}

// MARK: - Main View

struct FlyingView: View {
    @StateObject private var vm = FlyingViewModel()
    @EnvironmentObject private var appState: AppState
    
    @State private var showControls = true
    @State private var controlsFadeTimer: Timer? = nil
    @State private var cloudOffset1: CGFloat = 0
    @State private var cloudOffset2: CGFloat = 0
    
    @State private var weatherPhase: WeatherPhase = .clear
    @State private var weatherTransition: Double = 0.0
    @State private var weatherTimer: Timer? = nil
    @State private var lightningFlash: Double = 0.0
    @State private var lightningTimer: Timer? = nil
    @State private var raindrops: [Raindrop] = []
    @State private var rainAnimationTimer: Timer? = nil
    
    @State private var timeOfDay: TimeOfDay = .day
    @State private var timeTransition: Double = 1.0
    @State private var dayNightTimer: Timer? = nil
    @State private var stars: [Star] = []
    
    var body: some View {
        GeometryReader { geo in
            let altPct = altitudePercent(geo: geo)
            let weatherActive = altPct > 0.50
            let effectiveWeatherTransition = weatherActive ? weatherTransition : 0.0
            
            ZStack {
                DynamicSkyView(
                    timeOfDay: timeOfDay,
                    timeTransition: timeTransition,
                    planeHeight: vm.planeY,
                    screenHeight: geo.size.height
                )
                .ignoresSafeArea()
                
                Rectangle()
                    .fill(Color.black)
                    .opacity(timeOfDay.overlayDarken * timeTransition)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 3.0), value: timeTransition)
                    .animation(.easeInOut(duration: 3.0), value: timeOfDay)
                
                Rectangle()
                    .fill(Color.black)
                    .opacity(weatherPhase.skyDarken * effectiveWeatherTransition)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 2.0), value: effectiveWeatherTransition)
                    .animation(.easeInOut(duration: 2.0), value: weatherPhase)
                
                Rectangle()
                    .fill(Color.white)
                    .opacity(lightningFlash * effectiveWeatherTransition)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                
                groundSkyOverlay(geo: geo, altPct: altPct)
                    .ignoresSafeArea()
                
                if timeOfDay.showStars {
                    StarsView(stars: stars, screenWidth: geo.size.width, screenHeight: geo.size.height)
                        .opacity(timeTransition * starsOpacity(altPct: altPct))
                        .animation(.easeInOut(duration: 3.0), value: timeTransition)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
                
                if timeOfDay.showMoon {
                    MoonView()
                        .position(
                            x: geo.size.width * 0.78,
                            y: 100 + vm.skyOffset * 0.3
                        )
                        .opacity(timeTransition * sunOpacity(altPct: altPct))
                        .animation(.easeInOut(duration: 3.0), value: timeTransition)
                }
                
                if timeOfDay == .sunset || timeOfDay == .sunrise {
                    HorizonSunView(timeOfDay: timeOfDay)
                        .position(
                            x: timeOfDay == .sunset ? geo.size.width * 0.75 : geo.size.width * 0.25,
                            y: geo.size.height * 0.68 + vm.skyOffset * 0.2
                        )
                        .opacity(timeTransition * sunOpacity(altPct: altPct))
                        .animation(.easeInOut(duration: 3.0), value: timeTransition)
                        .animation(.easeInOut(duration: 3.0), value: timeOfDay)
                }
                
                if timeOfDay == .day {
                    SunView(pulse: true)
                        .position(
                            x: geo.size.width * 0.82,
                            y: 90 + vm.skyOffset * 0.3
                        )
                        .opacity(
                            sunOpacity(altPct: altPct) *
                            (1.0 - effectiveWeatherTransition * weatherPhase.skyDarken * 3.0).clamped(to: 0...1) *
                            timeTransition
                        )
                        .animation(.easeOut(duration: 1.5), value: effectiveWeatherTransition)
                        .animation(.easeInOut(duration: 3.0), value: timeOfDay)
                }
                
                ZStack {
                    CloudLayer(
                        screenWidth: geo.size.width,
                        baseY: geo.size.height * 0.22,
                        scrollOffset: cloudOffset1,
                        scale: 1.0
                    )
                    .colorMultiply(timeOfDay.cloudTint)
                    
                    CloudLayer(
                        screenWidth: geo.size.width,
                        baseY: geo.size.height * 0.22,
                        scrollOffset: cloudOffset1,
                        scale: 1.0
                    )
                    .colorMultiply(Color(hex: "#4A5568"))
                    .opacity(weatherPhase.cloudDarken * effectiveWeatherTransition)
                    .animation(.easeInOut(duration: 2.0), value: effectiveWeatherTransition)
                }
                .opacity(cloudOpacity(altPct: altPct))
                .animation(.easeOut(duration: 0.5), value: altPct)
                .animation(.easeInOut(duration: 3.0), value: timeOfDay)
                
                ZStack {
                    CloudLayer(
                        screenWidth: geo.size.width,
                        baseY: geo.size.height * 0.13,
                        scrollOffset: cloudOffset2,
                        scale: 0.7
                    )
                    .colorMultiply(timeOfDay.cloudTint)
                    
                    CloudLayer(
                        screenWidth: geo.size.width,
                        baseY: geo.size.height * 0.13,
                        scrollOffset: cloudOffset2,
                        scale: 0.7
                    )
                    .colorMultiply(Color(hex: "#4A5568"))
                    .opacity(weatherPhase.cloudDarken * effectiveWeatherTransition)
                    .animation(.easeInOut(duration: 2.0), value: effectiveWeatherTransition)
                }
                .opacity(cloudOpacity(altPct: altPct) * 0.6)
                .animation(.easeOut(duration: 0.5), value: altPct)
                .animation(.easeInOut(duration: 3.0), value: timeOfDay)
                
                MountainView(
                    screenWidth: geo.size.width,
                    screenHeight: geo.size.height,
                    parallaxOffset: vm.treesOffset * 0.4
                )
                .colorMultiply(timeOfDay.mountainTint)
                .opacity(mountainOpacity(altPct: altPct))
                .offset(y: mountainOffset(altPct: altPct))
                .animation(.easeOut(duration: 0.5), value: altPct)
                .animation(.easeInOut(duration: 3.0), value: timeOfDay)
                
                ProgressiveGroundView(
                    screenWidth: geo.size.width,
                    screenHeight: geo.size.height,
                    parallaxOffset: vm.groundOffset,
                    altitudePct: altPct
                )
                .colorMultiply(timeOfDay.groundTint)
                .animation(.easeInOut(duration: 3.0), value: timeOfDay)
                
                ProgressiveTreeLayerView(
                    screenWidth: geo.size.width,
                    screenHeight: geo.size.height,
                    parallaxOffset: vm.treesOffset,
                    altitudePct: altPct
                )
                .colorMultiply(timeOfDay.treeTint)
                .animation(.easeInOut(duration: 3.0), value: timeOfDay)
                
                if weatherPhase.rainIntensity > 0 && weatherActive {
                    RainView(
                        raindrops: raindrops,
                        screenWidth: geo.size.width,
                        screenHeight: geo.size.height,
                        intensity: weatherPhase.rainIntensity
                    )
                    .opacity(effectiveWeatherTransition * cloudOpacity(altPct: altPct))
                    .animation(.easeInOut(duration: 1.5), value: effectiveWeatherTransition)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                }
                
                WindParticleView(particles: vm.windParticles)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .opacity(windOpacity(altPct: altPct))
                
                PaperPlaneView(
                    size: planeSize(altPct: altPct),
                    tiltAngle: safePitchAngle,
                    idleWobble: vm.idleWobble,
                    direction: planeDirection
                )
                .rotationEffect(
                    .degrees(safeRollAngle),
                    anchor: .center
                )
                .position(x: vm.planeX, y: vm.planeY)
                .shadow(
                    color: Color.black.opacity(0.12 * (1.0 - altPct * 0.5)),
                    radius: 8 + CGFloat(altPct * 4),
                    x: 0, y: 4 + CGFloat(altPct * 6)
                )
                .animation(.easeOut(duration: 0.3), value: altPct)
                .onChange(of: planeDirection) { newDir in
                    withAnimation(.easeOut(duration: 0.3)) {
                        smoothDirection = newDir
                    }
                }
                
                uiOverlay(in: geo)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
            .onAppear { setupScene(geo: geo) }
            .onDisappear {
                vm.stopFlying()
                controlsFadeTimer?.invalidate()
                weatherTimer?.invalidate()
                lightningTimer?.invalidate()
                rainAnimationTimer?.invalidate()
                dayNightTimer?.invalidate()
            }
        }
        .ignoresSafeArea()
    }
    
    /// Pitch clamped and flipped by direction, max ±25°
    private var safePitchAngle: Double {
        let raw = vm.planeTiltAngle * Double(smoothDirection)
        return raw.clamped(to: -25...25)
    }
    
    /// Roll clamped to max ±20° to prevent plane looking broken
    private var safeRollAngle: Double {
        vm.planeRollAngle.clamped(to: -20...20)
    }
    
    @ViewBuilder
    private func groundSkyOverlay(geo: GeometryProxy, altPct: Double) -> some View {
        let overlayOpacity = max(0, 1.0 - altPct / 0.35)
        LinearGradient(
            colors: [
                Color(hex: "#A8C8A0").opacity(overlayOpacity * 0.7),
                Color(hex: "#C0D8B8").opacity(overlayOpacity * 0.5),
                Color.clear
            ],
            startPoint: .bottom, endPoint: .top
        )
        .colorMultiply(timeOfDay.groundTint)
        .animation(.easeInOut(duration: 3.0), value: timeOfDay)
    }
    
    private func sunOpacity(altPct: Double) -> Double {
        ((altPct - 0.55) / 0.20).clamped(to: 0...1)
    }
    
    private func starsOpacity(altPct: Double) -> Double {
        ((altPct - 0.40) / 0.25).clamped(to: 0...1)
    }
    
    private func cloudOpacity(altPct: Double) -> Double {
        ((altPct - 0.45) / 0.20).clamped(to: 0...1)
    }
    
    private func mountainOpacity(altPct: Double) -> Double {
        ((altPct - 0.25) / 0.25).clamped(to: 0...1)
    }
    
    private func mountainOffset(altPct: Double) -> CGFloat {
        CGFloat((1.0 - mountainOpacity(altPct: altPct)) * 80)
    }
    
    private func windOpacity(altPct: Double) -> Double {
        ((altPct - 0.2) / 0.3).clamped(to: 0...1)
    }
    
    private func planeSize(altPct: Double) -> CGSize {
        let s = (1.0 - altPct * 0.45).clamped(to: 0.55...1.0)
        return CGSize(width: 72 * s, height: 45 * s)
    }
    
    @State private var smoothDirection: CGFloat = 1
    
    private var planeDirection: CGFloat {
        let roll = vm.motionService.roll
        let target: CGFloat
        if roll > 0.15 {
            target = 1
        } else if roll < -0.15 {
            target = -1
        } else {
            target = smoothDirection
        }
        return target
    }
    
    private func startWeatherCycle() {
        scheduleNextWeatherChange()
        rainAnimationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            DispatchQueue.main.async { updateRaindrops() }
        }
    }
    
    private func scheduleNextWeatherChange() {
        let delay = Double.random(in: 5...10)
        weatherTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            DispatchQueue.main.async { transitionToNextWeather() }
        }
    }
    
    private func transitionToNextWeather() {
        var nextPhase: WeatherPhase
        switch weatherPhase {
        case .clear:     nextPhase = [.cloudy, .cloudy, .rain].randomElement()!
        case .cloudy:    nextPhase = [.clear, .rain, .rain].randomElement()!
        case .rain:      nextPhase = [.cloudy, .heavyRain, .clear].randomElement()!
        case .heavyRain: nextPhase = [.rain, .cloudy].randomElement()!
        }
        
        withAnimation(.easeInOut(duration: 2.0)) { weatherTransition = 0.0 }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            weatherPhase = nextPhase
            if nextPhase.rainIntensity > 0 { spawnRaindrops(count: Int(nextPhase.rainIntensity * 80)) }
            if nextPhase.hasLightning { startLightning() } else { lightningTimer?.invalidate() }
            withAnimation(.easeInOut(duration: 2.0)) { weatherTransition = 1.0 }
        }
        scheduleNextWeatherChange()
    }
    
    private func startLightning() {
        lightningTimer?.invalidate()
        lightningTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 3...8), repeats: true) { _ in
            DispatchQueue.main.async { triggerLightning() }
        }
    }
    
    private func triggerLightning() {
        guard weatherPhase.hasLightning else { return }
        withAnimation(.easeIn(duration: 0.05)) { lightningFlash = Double.random(in: 0.3...0.6) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.3)) { lightningFlash = 0.0 }
        }
        if Bool.random() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.easeIn(duration: 0.05)) { lightningFlash = Double.random(in: 0.15...0.35) }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    withAnimation(.easeOut(duration: 0.25)) { lightningFlash = 0.0 }
                }
            }
        }
    }
    
    private func spawnRaindrops(count: Int) {
        raindrops = (0..<count).map { _ in
            Raindrop(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: -0.3...1.0),
                speed: CGFloat.random(in: 0.012...0.025),
                length: CGFloat.random(in: 8...20),
                opacity: Double.random(in: 0.2...0.5),
                windOffset: CGFloat.random(in: -0.002...0.001)
            )
        }
    }
    
    private func updateRaindrops() {
        guard weatherPhase.rainIntensity > 0 else { return }
        for i in raindrops.indices {
            raindrops[i].y += raindrops[i].speed
            raindrops[i].x += raindrops[i].windOffset
            if raindrops[i].y > 1.2 {
                raindrops[i].y = CGFloat.random(in: -0.3...(-0.05))
                raindrops[i].x = CGFloat.random(in: 0...1)
                raindrops[i].speed = CGFloat.random(in: 0.012...0.025)
                raindrops[i].length = CGFloat.random(in: 8...20)
                raindrops[i].opacity = Double.random(in: 0.2...0.5)
            }
        }
    }
    
    private func startDayNightCycle() {
        stars = (0..<60).map { _ in
            Star(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0.02...0.55),
                size: CGFloat.random(in: 1.5...3.5),
                brightness: Double.random(in: 0.4...1.0),
                twinkleSpeed: Double.random(in: 1.5...4.0)
            )
        }
        
        scheduleNextTimePhase()
    }
    
    private func scheduleNextTimePhase() {
        let duration: Double
        switch timeOfDay {
        case .day:     duration = Double.random(in: 18...25)
        case .sunset:  duration = Double.random(in: 12...18)
        case .night:   duration = Double.random(in: 18...25)
        case .sunrise: duration = Double.random(in: 12...18)
        }
        
        dayNightTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            DispatchQueue.main.async { transitionToNextTime() }
        }
    }
    
    private func transitionToNextTime() {
        withAnimation(.easeInOut(duration: 4.0)) {
            timeTransition = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            switch timeOfDay {
            case .day:     timeOfDay = .sunset
            case .sunset:  timeOfDay = .night
            case .night:   timeOfDay = .sunrise
            case .sunrise: timeOfDay = .day
            }
            
            withAnimation(.easeInOut(duration: 4.0)) {
                timeTransition = 1.0
            }
        }
        
        scheduleNextTimePhase()
    }
    
    @ViewBuilder
    private func uiOverlay(in geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Button(action: {
                    vm.stopFlying()
                    appState.navigateToFolding()
                }) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 38, height: 38)
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                
                Spacer()
                
                weatherIndicator
                    .padding(.trailing, 8)
                
                AltitudeIndicatorView(altitude: altitudePercent(geo: geo))
            }
            .padding(.horizontal, 20)
            .padding(.top, geo.safeAreaInsets.top + 48)
            
            Spacer()
            
            if showControls {
                controlPanel(safeBottom: geo.safeAreaInsets.bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showControls)
        .frame(width: geo.size.width, height: geo.size.height)
    }
    
    private var weatherIndicator: some View {
        ZStack {
            Circle().fill(.ultraThinMaterial).frame(width: 32, height: 32)
            Image(systemName: weatherIconName)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
        }
        .animation(.easeOut(duration: 0.5), value: weatherPhase)
        .animation(.easeOut(duration: 0.5), value: timeOfDay)
    }
    
    private var weatherIconName: String {
        if timeOfDay == .night {
            switch weatherPhase {
            case .clear:     return "moon.stars.fill"
            case .cloudy:    return "cloud.moon.fill"
            case .rain:      return "cloud.moon.rain.fill"
            case .heavyRain: return "cloud.bolt.rain.fill"
            }
        } else {
            switch weatherPhase {
            case .clear:     return "sun.max.fill"
            case .cloudy:    return "cloud.fill"
            case .rain:      return "cloud.rain.fill"
            case .heavyRain: return "cloud.bolt.rain.fill"
            }
        }
    }
    
    private func controlPanel(safeBottom: CGFloat) -> some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.white.opacity(0.15))
                .frame(width: 36, height: 3)
            HStack(alignment: .center, spacing: 0) {
                tiltColumn.frame(maxWidth: .infinity)
                Rectangle().fill(Color.white.opacity(0.10)).frame(width: 0.5, height: 56)
                micColumn.frame(maxWidth: .infinity)
                Rectangle().fill(Color.white.opacity(0.10)).frame(width: 0.5, height: 56)
                rollColumn.frame(maxWidth: .infinity)
            }
            .frame(height: 90)
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 24).fill(Color.black.opacity(0.15))
                RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.12), lineWidth: 0.8)
            }
        )
        .frame(width: 320)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.bottom, safeBottom + 32)
        .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 6)
    }
    
    private var tiltColumn: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.75))
                    .rotationEffect(.degrees(Double(vm.motionService.roll) * -18))
                    .animation(.easeOut(duration: 0.15), value: vm.motionService.roll)
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
            Text("Tilt to steer")
                .font(.system(size: 10, weight: .light, design: .rounded))
                .foregroundColor(.white.opacity(0.5)).kerning(0.5)
        }
    }
    
    private var micColumn: some View {
        VStack(spacing: 5) {
            micIndicator.frame(width: 44, height: 44)
            compactWaveform.frame(width: 60, height: 16)
            Text("Blow to fly ↑")
                .font(.system(size: 10, weight: .light, design: .rounded))
                .foregroundColor(.white.opacity(0.55)).kerning(0.5).lineLimit(1)
        }
    }
    
    private var micIndicator: some View {
        let vol = vm.micService.normalizedVolume
        return ZStack {
            Circle().stroke(Color.white.opacity(0.15 + 0.35 * vol), lineWidth: 1.5)
                .scaleEffect(1.0 + 0.25 * vol).animation(.easeOut(duration: 0.12), value: vol)
            Circle().fill(Color.white.opacity(0.10 + 0.15 * vol))
            Image(systemName: "mic.fill").font(.system(size: 15))
                .foregroundColor(Color.white.opacity(0.55 + 0.45 * vol))
                .animation(.easeOut(duration: 0.1), value: vol)
        }
    }
    
    private var compactWaveform: some View {
        let vol = vm.micService.normalizedVolume
        return HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { i in
                let dist = CGFloat(abs(i - 2))
                let mult = 1.0 - dist * 0.18
                Capsule().fill(Color.white.opacity(0.5))
                    .frame(width: 2, height: max(3, 14 * vol * mult))
                    .animation(.easeOut(duration: 0.08), value: vol)
            }
        }
    }
    
    private var rollColumn: some View {
        let roll = vm.motionService.roll
        return VStack(spacing: 6) {
            ZStack {
                Capsule().fill(Color.white.opacity(0.15)).frame(width: 50, height: 10)
                Circle().fill(Color.white.opacity(0.85)).frame(width: 10, height: 10)
                    .offset(x: roll * 20).animation(.easeOut(duration: 0.08), value: roll)
            }
            HStack(spacing: 12) {
                Image(systemName: "arrow.left").font(.system(size: 9))
                    .foregroundColor(.white.opacity(roll < -0.1 ? 0.9 : 0.25))
                Image(systemName: "arrow.right").font(.system(size: 9))
                    .foregroundColor(.white.opacity(roll > 0.1 ? 0.9 : 0.25))
            }.animation(.easeOut(duration: 0.1), value: roll)
            Text("Roll: \(String(format: "%.1f", Double(roll)))")
                .font(.system(size: 9, weight: .light, design: .rounded))
                .foregroundColor(.white.opacity(0.35))
        }
    }
    
    private func altitudePercent(geo: GeometryProxy) -> Double {
        let topBound: CGFloat = 80
        let bottomBound: CGFloat = geo.size.height - 160
        let pct = 1.0 - Double((vm.planeY - topBound) / (bottomBound - topBound))
        return pct.clamped(to: 0...1)
    }
    
    private func setupScene(geo: GeometryProxy) {
        vm.startFlying(screenWidth: geo.size.width, screenHeight: geo.size.height)
        
        withAnimation(.linear(duration: 28).repeatForever(autoreverses: false)) {
            cloudOffset1 = -geo.size.width * 2
        }
        withAnimation(.linear(duration: 45).repeatForever(autoreverses: false)) {
            cloudOffset2 = -geo.size.width * 2
        }
        
        controlsFadeTimer = Timer.scheduledTimer(withTimeInterval: 6, repeats: false) { _ in
            DispatchQueue.main.async { withAnimation { showControls = false } }
        }
        
        startWeatherCycle()
        startDayNightCycle()
    }
}

// MARK: - Horizon Sun View (Sunset/Sunrise)

struct HorizonSunView: View {
    let timeOfDay: TimeOfDay
    @State private var pulsing = false
    
    private var coreColor: Color {
        switch timeOfDay {
        case .sunset:  return Color(red: 0.95, green: 0.55, blue: 0.25)
        case .sunrise: return Color(red: 0.95, green: 0.60, blue: 0.30)
        default:       return Color(hex: "#FFD060")
        }
    }
    
    private var glowColor: Color {
        switch timeOfDay {
        case .sunset:  return Color(red: 0.90, green: 0.40, blue: 0.15)
        case .sunrise: return Color(red: 0.90, green: 0.50, blue: 0.20)
        default:       return Color(hex: "#FFD060")
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            glowColor.opacity(0.12),
                            glowColor.opacity(0.05),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 160
                    )
                )
                .frame(
                    width: pulsing ? 320 : 300,
                    height: pulsing ? 320 : 300
                )
                .blur(radius: 35)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            glowColor.opacity(0.18),
                            glowColor.opacity(0.06),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 90
                    )
                )
                .frame(
                    width: pulsing ? 185 : 170,
                    height: pulsing ? 185 : 170
                )
                .blur(radius: 15)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            coreColor.opacity(0.30),
                            coreColor.opacity(0.10),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 55
                    )
                )
                .frame(width: 110, height: 110)
                .blur(radius: 8)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            coreColor.opacity(0.65),
                            coreColor.opacity(0.35),
                            glowColor.opacity(0.10),
                        ],
                        center: .center,
                        startRadius: 4,
                        endRadius: 26
                    )
                )
                .frame(width: 52, height: 52)
                .blur(radius: 4)
            
            Circle()
                .fill(coreColor.opacity(0.50))
                .frame(width: 18, height: 18)
                .blur(radius: 6)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 3.0)
                .repeatForever(autoreverses: true)
            ) {
                pulsing = true
            }
        }
    }
}

// MARK: - Dynamic Sky View

struct DynamicSkyView: View {
    let timeOfDay: TimeOfDay
    let timeTransition: Double
    let planeHeight: CGFloat
    let screenHeight: CGFloat
    
    var body: some View {
        LinearGradient(
            colors: [timeOfDay.skyTopColor, timeOfDay.skyBottomColor],
            startPoint: .top,
            endPoint: .bottom
        )
        .animation(.easeInOut(duration: 4.0), value: timeOfDay)
        .animation(.easeInOut(duration: 4.0), value: timeTransition)
    }
}

// MARK: - Star Model

struct Star: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let brightness: Double
    let twinkleSpeed: Double
}

// MARK: - Stars View

struct StarsView: View {
    let stars: [Star]
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    
    var body: some View {
        ZStack {
            ForEach(stars) { star in
                StarDotView(star: star)
                    .position(
                        x: star.x * screenWidth,
                        y: star.y * screenHeight
                    )
            }
        }
    }
}

struct StarDotView: View {
    let star: Star
    @State private var twinkle = false
    
    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: star.size, height: star.size)
            .opacity(twinkle ? star.brightness : star.brightness * 0.3)
            .blur(radius: star.size > 2.5 ? 0.5 : 0)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: star.twinkleSpeed)
                    .repeatForever(autoreverses: true)
                    .delay(Double.random(in: 0...2))
                ) {
                    twinkle = true
                }
            }
    }
}

// MARK: - Moon View

struct MoonView: View {
    @State private var glowing = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#E8E8FF").opacity(0.15))
                .frame(width: glowing ? 68 : 58, height: glowing ? 68 : 58)
                .blur(radius: 10)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "#F5F5FF"),
                            Color(hex: "#D8D8E8"),
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: 16
                    )
                )
                .frame(width: 30, height: 30)
            
            Circle()
                .fill(Color(hex: "#0A0A20").opacity(0.3))
                .frame(width: 28, height: 28)
                .offset(x: 6, y: -3)
                .mask(
                    Circle().frame(width: 30, height: 30)
                )
            
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 5, height: 5)
                .offset(x: -5, y: 4)
            
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 3.5, height: 3.5)
                .offset(x: 3, y: -6)
            
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 4, height: 4)
                .offset(x: -2, y: -2)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                glowing = true
            }
        }
    }
}

// MARK: - Raindrop Model

struct Raindrop: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var speed: CGFloat
    var length: CGFloat
    var opacity: Double
    var windOffset: CGFloat
}

// MARK: - Rain View

struct RainView: View {
    let raindrops: [Raindrop]
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let intensity: Double
    
    var body: some View {
        Canvas { context, size in
            for drop in raindrops {
                let x = drop.x * size.width
                let y = drop.y * size.height
                var path = Path()
                path.move(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x - 1.5, y: y + drop.length))
                context.stroke(path, with: .color(.white.opacity(drop.opacity * intensity)), lineWidth: 1.2)
            }
        }
        .frame(width: screenWidth, height: screenHeight)
    }
}

// MARK: - Progressive Ground View

struct ProgressiveGroundView: View {
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let parallaxOffset: CGFloat
    let altitudePct: Double
    
    private var groundTopY: CGFloat {
        screenHeight * CGFloat(0.55 + altitudePct * 0.27)
    }
    private var groundHeight: CGFloat { screenHeight - groundTopY + 60 }
    private var dirtRatio: CGFloat { CGFloat(1.0 - altitudePct).clamped(to: 0...1) }
    
    var body: some View {
        ZStack(alignment: .top) {
            Rectangle().fill(
                LinearGradient(colors: [Color(hex: "#8B6914"), Color(hex: "#6B4F12"), Color(hex: "#5A3E0E")],
                               startPoint: .top, endPoint: .bottom)
            ).frame(width: screenWidth, height: groundHeight)
            
            Rectangle().fill(
                LinearGradient(colors: [Color(hex: "#80C880"), Color(hex: "#5EA85E"), Color(hex: "#4A9A4A")],
                               startPoint: .top, endPoint: .bottom)
            ).frame(width: screenWidth, height: groundHeight * CGFloat(0.65 + altitudePct * 0.30))
                .frame(maxHeight: .infinity, alignment: .top)
            
            Rectangle().fill(
                LinearGradient(colors: [Color(hex: "#4A9A4A").opacity(0.8), Color(hex: "#6B7A30"), Color(hex: "#8B6914").opacity(0.6)],
                               startPoint: .top, endPoint: .bottom)
            ).frame(width: screenWidth, height: 18 * dirtRatio)
                .offset(y: groundHeight * CGFloat(0.65 + altitudePct * 0.30) - 6)
                .opacity(Double(dirtRatio))
            
            if altitudePct < 0.5 {
                DirtTextureView(screenWidth: screenWidth, groundHeight: groundHeight,
                                grassCoverage: CGFloat(0.65 + altitudePct * 0.30))
                .opacity(Double(dirtRatio) * 0.6)
            }
            
            HillsShape().fill(
                LinearGradient(colors: [Color(hex: "#98D898"), Color(hex: "#80C880")],
                               startPoint: .top, endPoint: .bottom)
            ).frame(width: screenWidth, height: 55).offset(y: -28)
        }
        .frame(width: screenWidth, height: groundHeight)
        .position(x: screenWidth / 2, y: groundTopY + groundHeight / 2 + parallaxOffset * 0.45)
        .animation(.easeOut(duration: 0.4), value: altitudePct)
    }
}

// MARK: - Dirt Texture View

struct DirtTextureView: View {
    let screenWidth: CGFloat
    let groundHeight: CGFloat
    let grassCoverage: CGFloat
    private var dirtTopY: CGFloat { groundHeight * grassCoverage }
    
    private var pebbles: [(x: CGFloat, y: CGFloat, size: CGFloat, opacity: Double)] {
        [
            (screenWidth * 0.08, dirtTopY + 20, 4, 0.3), (screenWidth * 0.18, dirtTopY + 35, 3, 0.25),
            (screenWidth * 0.30, dirtTopY + 15, 5, 0.35), (screenWidth * 0.42, dirtTopY + 42, 3.5, 0.2),
            (screenWidth * 0.55, dirtTopY + 25, 4.5, 0.3), (screenWidth * 0.65, dirtTopY + 38, 3, 0.25),
            (screenWidth * 0.78, dirtTopY + 18, 4, 0.3), (screenWidth * 0.88, dirtTopY + 32, 5, 0.35),
            (screenWidth * 0.95, dirtTopY + 45, 3.5, 0.2), (screenWidth * 0.12, dirtTopY + 55, 4, 0.25),
            (screenWidth * 0.35, dirtTopY + 60, 3, 0.2), (screenWidth * 0.50, dirtTopY + 50, 4.5, 0.3),
            (screenWidth * 0.72, dirtTopY + 58, 3.5, 0.25), (screenWidth * 0.90, dirtTopY + 65, 4, 0.2),
        ]
    }
    
    private var roots: [(x: CGFloat, w: CGFloat, h: CGFloat)] {
        [(screenWidth*0.10,2,12),(screenWidth*0.25,1.5,16),(screenWidth*0.40,2,10),
         (screenWidth*0.55,1.5,14),(screenWidth*0.70,2,11),(screenWidth*0.85,1.5,15)]
    }
    
    var body: some View {
        ZStack {
            ForEach(pebbles.indices, id: \.self) { i in
                let p = pebbles[i]
                Ellipse().fill(Color(hex: "#A08040").opacity(p.opacity))
                    .frame(width: p.size * 1.3, height: p.size).position(x: p.x, y: p.y)
            }
            ForEach(roots.indices, id: \.self) { i in
                let r = roots[i]
                Capsule().fill(LinearGradient(colors: [Color(hex: "#4A9A4A").opacity(0.5), Color(hex: "#4A9A4A").opacity(0.0)],
                                              startPoint: .top, endPoint: .bottom))
                .frame(width: r.w, height: r.h).position(x: r.x, y: dirtTopY + r.h / 2)
            }
        }
    }
}

// MARK: - Progressive Tree Layer View

struct ProgressiveTreeLayerView: View {
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let parallaxOffset: CGFloat
    let altitudePct: Double
    
    private var treeBaseY: CGFloat { screenHeight * CGFloat(0.53 + altitudePct * 0.27) }
    private var treeScale: CGFloat { CGFloat(1.0 - altitudePct * 0.3).clamped(to: 0.7...1.0) }
    
    private var tier1Trees: [TreeRowView.TreeConfig] {
        [.init(x: screenWidth*0.15, type: .pine, scale: 1.4*treeScale, offsetY: treeBaseY),
         .init(x: screenWidth*0.50, type: .round, scale: 1.3*treeScale, offsetY: treeBaseY),
         .init(x: screenWidth*0.85, type: .pine, scale: 1.5*treeScale, offsetY: treeBaseY)]
    }
    private var tier2Trees: [TreeRowView.TreeConfig] {
        [.init(x: screenWidth*0.04, type: .round, scale: 1.2*treeScale, offsetY: treeBaseY),
         .init(x: screenWidth*0.32, type: .pine, scale: 1.6*treeScale, offsetY: treeBaseY),
         .init(x: screenWidth*0.68, type: .round, scale: 1.4*treeScale, offsetY: treeBaseY)]
    }
    private var tier3Trees: [TreeRowView.TreeConfig] {
        [.init(x: screenWidth*0.22, type: .pine, scale: 1.1*treeScale, offsetY: treeBaseY),
         .init(x: screenWidth*0.42, type: .pine, scale: 1.3*treeScale, offsetY: treeBaseY),
         .init(x: screenWidth*0.58, type: .round, scale: 1.2*treeScale, offsetY: treeBaseY),
         .init(x: screenWidth*0.76, type: .pine, scale: 1.0*treeScale, offsetY: treeBaseY),
         .init(x: screenWidth*0.94, type: .round, scale: 1.3*treeScale, offsetY: treeBaseY)]
    }
    
    private var tier2Opacity: Double { ((altitudePct - 0.05) / 0.10).clamped(to: 0...1) }
    private var tier3Opacity: Double { ((altitudePct - 0.15) / 0.10).clamped(to: 0...1) }
    
    var body: some View {
        ZStack {
            TreeRowView(configs: tier1Trees, parallaxOffset: parallaxOffset)
            TreeRowView(configs: tier2Trees, parallaxOffset: parallaxOffset).opacity(tier2Opacity)
            TreeRowView(configs: tier3Trees, parallaxOffset: parallaxOffset).opacity(tier3Opacity)
        }
        .allowsHitTesting(false)
        .animation(.easeOut(duration: 0.4), value: altitudePct)
    }
}

// MARK: - Supporting Views

struct SunView: View {
    let pulse: Bool; @State private var glowing = false
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: "#FFE8A0").opacity(0.3))
                .frame(width: glowing ? 70 : 58, height: glowing ? 70 : 58).blur(radius: 8)
            Circle().fill(Color(hex: "#FFD970").opacity(0.5)).frame(width: 42, height: 42).blur(radius: 3)
            Circle().fill(RadialGradient(colors: [Color(hex: "#FFF0A0"), Color(hex: "#FFD060")],
                                         center: .center, startRadius: 2, endRadius: 18))
            .frame(width: 34, height: 34)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) { glowing = true }
        }
    }
}

struct CloudLayer: View {
    let screenWidth: CGFloat; let baseY: CGFloat; let scrollOffset: CGFloat; let scale: CGFloat
    private var clouds: [(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat)] {
        [(screenWidth*0.15, baseY, 110, 38), (screenWidth*0.52, baseY-18, 145, 46),
         (screenWidth*0.88, baseY+12, 92, 32), (screenWidth*1.28, baseY-8, 125, 42),
         (screenWidth*1.68, baseY+6, 108, 36), (screenWidth*2.05, baseY-14, 118, 40)]
    }
    var body: some View {
        ZStack {
            ForEach(clouds.indices, id: \.self) { i in
                let c = clouds[i]
                CloudShape().fill(Color.white.opacity(0.88))
                    .frame(width: c.w * scale, height: c.h * scale)
                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 3)
                    .position(x: c.x + scrollOffset, y: c.y)
            }
        }.allowsHitTesting(false)
    }
}

struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path(); let w = rect.width; let h = rect.height
        path.addEllipse(in: CGRect(x: w*0.08, y: h*0.30, width: w*0.34, height: h*0.70))
        path.addEllipse(in: CGRect(x: w*0.28, y: h*0.02, width: w*0.40, height: h*0.78))
        path.addEllipse(in: CGRect(x: w*0.56, y: h*0.22, width: w*0.36, height: h*0.62))
        path.addRect(CGRect(x: w*0.08, y: h*0.50, width: w*0.84, height: h*0.50))
        return path
    }
}

struct MountainView: View {
    let screenWidth: CGFloat; let screenHeight: CGFloat; let parallaxOffset: CGFloat
    private var groundTopY: CGFloat { screenHeight * 0.80 }
    var body: some View {
        ZStack {
            RoundedMountainShape(peaks: [.init(x: 0.25, height: 0.60, width: 0.90), .init(x: 0.75, height: 0.48, width: 0.85)])
                .fill(LinearGradient(colors: [Color(hex: "#B0C8B8"), Color(hex: "#9CBC9C")], startPoint: .top, endPoint: .bottom))
                .frame(width: screenWidth*1.4, height: screenHeight*0.30)
                .position(x: screenWidth*0.5, y: groundTopY - screenHeight*0.10 + parallaxOffset*0.15)
            RoundedMountainShape(peaks: [.init(x: 0.12, height: 0.50, width: 0.60), .init(x: 0.48, height: 0.78, width: 0.75), .init(x: 0.85, height: 0.58, width: 0.65)])
                .fill(LinearGradient(colors: [Color(hex: "#8AAE94"), Color(hex: "#72A07E")], startPoint: .top, endPoint: .bottom))
                .frame(width: screenWidth*1.2, height: screenHeight*0.28)
                .position(x: screenWidth*0.5, y: groundTopY - screenHeight*0.06 + parallaxOffset*0.30)
            RoundedMountainShape(peaks: [.init(x: 0.08, height: 0.55, width: 0.70), .init(x: 0.45, height: 0.40, width: 0.65), .init(x: 0.82, height: 0.50, width: 0.70)])
                .fill(LinearGradient(colors: [Color(hex: "#6E9C78"), Color(hex: "#5C8C68")], startPoint: .top, endPoint: .bottom))
                .frame(width: screenWidth*1.2, height: screenHeight*0.14)
                .position(x: screenWidth*0.5, y: groundTopY - screenHeight*0.01 + parallaxOffset*0.40)
        }.allowsHitTesting(false)
    }
}

struct RoundedMountainShape: Shape {
    struct Peak { let x: CGFloat; let height: CGFloat; let width: CGFloat }
    let peaks: [Peak]
    func path(in rect: CGRect) -> Path {
        let w = rect.width; let h = rect.height
        var path = Path(); path.move(to: CGPoint(x: 0, y: h))
        let steps = 200; var silhouette: [CGPoint] = []
        for step in 0...steps {
            let fraction = CGFloat(step) / CGFloat(steps); let px = fraction * w; var minY = h
            for peak in peaks {
                let centerX = peak.x * w; let halfW = peak.width * w * 0.5
                let peakY = h * (1.0 - peak.height); let dist = (px - centerX) / halfW
                if abs(dist) <= 1.0 {
                    let t = cos(dist * .pi / 2); let y = h - t * t * (h - peakY); minY = min(minY, y)
                }
            }
            silhouette.append(CGPoint(x: px, y: minY))
        }
        if let first = silhouette.first { path.addLine(to: first) }
        for i in 1..<silhouette.count {
            let prev = silhouette[i-1]; let curr = silhouette[i]
            path.addQuadCurve(to: CGPoint(x: (prev.x+curr.x)/2, y: (prev.y+curr.y)/2), control: prev)
        }
        if let last = silhouette.last { path.addLine(to: last) }
        path.addLine(to: CGPoint(x: w, y: h)); path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }
}

struct HillsShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path(); let w = rect.width; let h = rect.height
        path.move(to: CGPoint(x: 0, y: h))
        path.addCurve(to: CGPoint(x: w*0.28, y: h*0.18),
                       control1: CGPoint(x: w*0.08, y: h*0.85), control2: CGPoint(x: w*0.16, y: h*0.04))
        path.addCurve(to: CGPoint(x: w*0.58, y: h*0.28),
                       control1: CGPoint(x: w*0.38, y: h*0.30), control2: CGPoint(x: w*0.48, y: h*0.48))
        path.addCurve(to: CGPoint(x: w*0.82, y: h*0.06),
                       control1: CGPoint(x: w*0.68, y: h*0.08), control2: CGPoint(x: w*0.74, y: h*(-0.08)))
        path.addCurve(to: CGPoint(x: w, y: h*0.22),
                       control1: CGPoint(x: w*0.90, y: h*0.20), control2: CGPoint(x: w*0.95, y: h*0.32))
        path.addLine(to: CGPoint(x: w, y: h))
        path.closeSubpath()
        return path
    }
}

struct AltitudeIndicatorView: View {
    let altitude: Double
    var body: some View {
        VStack(spacing: 3) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.20))
                    .frame(width: 5, height: 52)
                RoundedRectangle(cornerRadius: 3).fill(
                    LinearGradient(colors: [Color(hex: "#FFD060"), Color(hex: "#A8D8EA")],
                                   startPoint: .bottom, endPoint: .top))
                .frame(width: 5, height: max(4, 52 * altitude))
                .animation(.easeOut(duration: 0.12), value: altitude)
            }
            Image(systemName: "arrow.up").font(.system(size: 7, weight: .medium))
                .foregroundColor(.white.opacity(0.45))
        }
    }
}

struct RollIndicatorView: View {
    let roll: CGFloat
    var body: some View {
        ZStack {
            Capsule().fill(Color.white.opacity(0.20)).frame(width: 50, height: 10)
            Circle().fill(Color.white.opacity(0.85)).frame(width: 10, height: 10)
                .offset(x: roll * 20).animation(.easeOut(duration: 0.08), value: roll)
        }
    }
}

#Preview {
    FlyingView()
        .environmentObject(AppState())
}
