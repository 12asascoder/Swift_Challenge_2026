import SwiftUI

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var size: CGFloat
    var opacity: Double
    var vx: CGFloat
    var vy: CGFloat
    var life: Double
}

struct ZenCanvasView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @State private var particles: [Particle] = []
    @State private var density: Double = 0.75
    @State private var displayLink: Bool = false

    let timer = Timer.publish(every: 1.0/60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.amberBG.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Zen Canvas")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Text("AMBER EXPERIENCE")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.amberSubtext)
                            .kerning(1.5)
                    }
                    Spacer()
                    Button {
                        let xp = DataStore.xpFormula(baseScore: particles.count * 5, difficulty: 1.0, streakBonus: 5)
                        dataStore.addSession(score: particles.count * 5, xpGained: xp)
                        appState.completeSession(score: particles.count * 5, xp: xp)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                            Text("Exit")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.amberCard)
                                .overlay(Capsule().stroke(Color.amberCardBorder, lineWidth: 1))
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Canvas
                GeometryReader { geo in
                    ZStack {
                        // Guide circle
                        Circle()
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            .frame(width: geo.size.width * 0.6, height: geo.size.width * 0.6)

                        if particles.isEmpty {
                            Text("TOUCH TO CREATE")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.15))
                                .kerning(3)
                        }

                        // Particles
                        Canvas { context, size in
                            for p in particles {
                                let rect = CGRect(x: p.x - p.size/2, y: p.y - p.size/2,
                                                  width: p.size, height: p.size)
                                context.opacity = p.opacity
                                context.fill(Circle().path(in: rect), with: .color(p.color))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in spawnParticles(at: value.location, density: density) }
                    )
                }

                // Controls
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "square.grid.3x3.fill")
                            .foregroundColor(.amberAccent)
                            .font(.system(size: 14))
                        Text("PARTICLE DENSITY")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .kerning(1.5)
                        Spacer()
                        Text("\(Int(density * 100))%")
                            .font(AMBERFont.mono(13, weight: .bold))
                            .foregroundColor(.amberAccent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.amberIconBG))
                    }

                    Slider(value: $density, in: 0.1...1.0)
                        .tint(.amberAccent)

                    HStack {
                        Text("MINIMAL").font(.system(size: 10)).foregroundColor(.amberSubtext)
                        Spacer()
                        Circle().fill(Color.amberSubtext).frame(width: 4, height: 4)
                        Text("OPTIMIZED FOR 60FPS").font(.system(size: 10)).foregroundColor(.amberSubtext)
                        Circle().fill(Color.amberSubtext).frame(width: 4, height: 4)
                        Spacer()
                        Text("MAX FLOW").font(.system(size: 10)).foregroundColor(.amberSubtext)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.amberCard)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.amberCardBorder, lineWidth: 1))
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 20)
            }
        }
        .onReceive(timer) { _ in updateParticles() }
    }

    private func spawnParticles(at location: CGPoint, density: Double) {
        let count = Int(density * 5) + 1
        let colors: [Color] = [.amberAccent, .cyan, .purple, .pink, .green, .white]
        let newParticles = (0..<count).map { _ in
            Particle(
                x: location.x + CGFloat.random(in: -20...20),
                y: location.y + CGFloat.random(in: -20...20),
                color: colors.randomElement()!,
                size: CGFloat.random(in: 3...8),
                opacity: Double.random(in: 0.6...1.0),
                vx: CGFloat.random(in: -1...1),
                vy: CGFloat.random(in: -2...0),
                life: Double.random(in: 0.5...1.5)
            )
        }
        particles.append(contentsOf: newParticles)
        if particles.count > 500 { particles.removeFirst(particles.count - 500) }
    }

    private func updateParticles() {
        let dt: Double = 1.0 / 60.0
        particles = particles.compactMap { p in
            var q = p
            q.x += q.vx
            q.y += q.vy
            q.life -= dt
            q.opacity = max(0, q.life / 1.5)
            return q.life > 0 ? q : nil
        }
    }
}
