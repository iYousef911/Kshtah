import SwiftUI
internal import Combine

struct ParticleEffectView: View {
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var scale: CGFloat
        var opacity: Double
        var speedY: CGFloat
    }
    
    let particleCount = 20
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(Color.yellow.opacity(particle.opacity))
                        .frame(width: 8 * particle.scale, height: 8 * particle.scale)
                        .position(x: particle.x, y: particle.y)
                        .blur(radius: 2)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
            }
            .onReceive(Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()) { _ in
                updateParticles(in: geometry.size)
            }
        }
        .allowsHitTesting(false) // Pass touches through
    }
    
    func createParticles(in size: CGSize) {
        for _ in 0..<particleCount {
            particles.append(Particle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                scale: CGFloat.random(in: 0.5...1.5),
                opacity: Double.random(in: 0.3...0.8),
                speedY: CGFloat.random(in: 0.5...2.0) // Float upwards slowly
            ))
        }
    }
    
    func updateParticles(in size: CGSize) {
        for i in 0..<particles.count {
            particles[i].y -= particles[i].speedY
            
            // Fade in/out logic locally or just reset
            if particles[i].y < -10 {
                particles[i].y = size.height + 10
                particles[i].x = CGFloat.random(in: 0...size.width)
            }
        }
    }
}
