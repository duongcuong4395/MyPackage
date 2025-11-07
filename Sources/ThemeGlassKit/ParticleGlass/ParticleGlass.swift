//
//  ParticleGlass.swift
//  MyLibrary
//
//  Created by Macbook on 7/11/25.
//

import SwiftUI

// MARK: - Optimized Particle System
@available(iOS 14.0, *)
public struct ParticleGlass: View {
    @State private var particles: [Particle] = []
    @State private var timer: Timer?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var perfMonitor = PerformanceMonitor()
    
    private var particleCount: Int {
        switch perfMonitor.deviceTier {
        case .high: return 20
        case .medium: return 10
        case .low: return 5
        }
    }
    
    public init() {}
    
    public var body: some View {
        ZStack {
            if !reduceMotion && perfMonitor.deviceTier != .low {
                ForEach(particles.indices, id: \.self) { index in
                    if particles.indices.contains(index) {
                        Circle()
                            .fill(Color.white.opacity(0.6))
                            .frame(width: particles[index].size, height: particles[index].size)
                            .position(particles[index].position)
                            .opacity(particles[index].opacity)
                    }
                }
            }
        }
        .onAppear(perform: startParticles)
        .onDisappear(perform: stopParticles)
    }
    
    private func startParticles() {
        guard !reduceMotion else { return }
        createParticles()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [self] _ in
            Task { @MainActor in
                animateParticles()
            }
            
        }
    }
    
    private func stopParticles() {
        timer?.invalidate()
        timer = nil
    }
    
    private func createParticles() {
        particles = (0..<particleCount).map { _ in
            Particle(
                position: CGPoint(
                    x: Double.random(in: 0...400),
                    y: Double.random(in: 0...800)
                ),
                size: Double.random(in: 2...8),
                opacity: Double.random(in: 0.2...0.8)
            )
        }
    }
    
    private func animateParticles() {
        withAnimation(.linear(duration: 0.1)) {
            for i in particles.indices {
                particles[i].position.y -= Double.random(in: 1...3)
                particles[i].opacity *= 0.995
                
                if particles[i].position.y < -10 || particles[i].opacity < 0.1 {
                    particles[i] = Particle(
                        position: CGPoint(
                            x: Double.random(in: 0...400),
                            y: 810
                        ),
                        size: Double.random(in: 2...8),
                        opacity: Double.random(in: 0.2...0.8)
                    )
                }
            }
        }
    }
}

struct Particle: Equatable {
    var position: CGPoint
    let size: Double
    var opacity: Double
}
