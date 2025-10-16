//
//  StockApp+DesignSystem.swift
//  Stock (Now QuantumScalp)
//
//  Liquid Glass Design System - iOS 26 Liquid Interface
//

import SwiftUI

// MARK: - Liquid Glass Design System

struct LiquidGlassDesign {
    // Core colors using Liquid Glass palette
    static let primary: Color = Color(hex: "6366F1")      // Quantum Blue
    static let secondary: Color = Color(hex: "8B5CF6")    // Quantum Purple
    static let accent: Color = Color(hex: "06B6D4")       // Quantum Cyan
    static let surface: Color = Color(hex: "F8FAFC")      // Liquid Ice
    static let background: Color = Color(hex: "0F0F0F")   // Liquid Void

    // Dynamic gradients
    static let quantumGradient = LinearGradient(
        colors: [primary, secondary, accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let liquidGradient = LinearGradient(
        colors: [Color(hex: "1E293B"), Color(hex: "334155"), Color(hex: "0F172A")],
        startPoint: .top,
        endPoint: .bottom
    )

    // Morphological glass effects
    static func glassMorphology(cornerRadius: CGFloat = 20) -> some ViewModifier {
        return GlassMorphologyModifier(cornerRadius: cornerRadius)
    }

    static func liquidGlow(intensity: Double = 1.0) -> some View {
        ZStack {
            // Base layer
            Color.clear

            // Liquid glowing particles
            LiquidParticleSystem(intensity: intensity)
        }
    }
}

struct GlassMorphologyModifier: ViewModifier {
    let cornerRadius: CGFloat
    @State private var blurIntensity: CGFloat = 20
    @State private var opacity: Double = 0.7

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(opacity))
                    .blur(radius: blurIntensity / 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.8),
                                        Color.white.opacity(0.2),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Liquid Particle System

struct LiquidParticleSystem: View {
    let intensity: Double
    @State private var particles: [LiquidParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ForEach(particles) { particle in
                LiquidParticleView(particle: particle, size: geometry.size)
            }
        }
        .onAppear {
            initializeParticles()
        }
    }

    private func initializeParticles() {
        particles = (0..<Int(intensity * 20)).map { _ in
            LiquidParticle.random()
        }
    }
}

struct LiquidParticle: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var size: Double
    var opacity: Double
    var color: Color

    static func random() -> LiquidParticle {
        LiquidParticle(
            x: Double.random(in: 0...300),
            y: Double.random(in: 0...400),
            size: Double.random(in: 2...6),
            opacity: Double.random(in: 0.3...0.8),
            color: [LiquidGlassDesign.primary,
                   LiquidGlassDesign.secondary,
                   LiquidGlassDesign.accent].randomElement()!
        )
    }
}

struct LiquidParticleView: View {
    let particle: LiquidParticle
    let size: CGSize

    var body: some View {
        Circle()
            .fill(particle.color.opacity(particle.opacity))
            .frame(width: particle.size, height: particle.size)
            .position(x: particle.x, y: particle.y)
            .blur(radius: particle.size / 4)
    }
}

// MARK: - Quantum Stock Card

struct QuantumStockCard: View {
    let symbol: String
    let name: String
    let price: Double
    let change: Double
    let changePercent: Double

    var body: some View {
        ZStack {
            // Liquid glass background
            RoundedRectangle(cornerRadius: 20)
                .modifier(LiquidGlassDesign.glassMorphology())
                .frame(height: 120)

            // Content overlay
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(symbol)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text(name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("$\(price, specifier: "%.2f")")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)

                        HStack(spacing: 4) {
                            Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                                .foregroundColor(change >= 0 ? .green : .red)
                                .font(.caption)

                            Text("\(change >= 0 ? "+" : "")\(change, specifier: "%.2f") (\(changePercent, specifier: "%.1f")%)")
                                .font(.caption)
                                .foregroundColor(change >= 0 ? .green : .red)
                        }
                    }
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 3)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(change >= 0 ? Color.green : Color.red)
                            .frame(width: min(geometry.size.width * abs(changePercent) / 5, geometry.size.width), height: 3)
                    }
                }
                .frame(height: 8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Application Brand Update

struct QuantumScalpTheme {
    static let appName = "QuantumScalp"
    static let tagline = "AI-Powered Quantum Trading"

    static let brandColors: [Color] = [
        LiquidGlassDesign.primary,
        LiquidGlassDesign.secondary,
        LiquidGlassDesign.accent
    ]

    static func applyTheme() {
        #if os(iOS)
        // Apply Liquid Glass theme globally
        UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .light

        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        #endif
    }
}
