import SwiftUI

// 游戏气泡视图
struct GameBubbleView: View {
    let word: String
    let color: Color
    let position: CGPoint
    let bubbleId: String
    let size: CGFloat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        ZStack {
            // 气泡主体
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            color,
                            color.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.8),
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: size * 0.5
                            )
                        )
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
            
            // 文字
            Text(word)
                .font(.system(size: size * 0.2))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .frame(width: size * 0.8, height: size * 0.8)
        }
        .position(position)
        .onTapGesture(perform: action)
    }
}

// 爆炸粒子
struct BurstParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGPoint
    var color: Color
    var size: CGFloat
    var opacity: CGFloat
    var scale: CGFloat
    var rotation: Double
    let createdAt = Date()
    
    init(position: CGPoint, velocity: CGPoint, color: Color, size: CGFloat, opacity: CGFloat = 1.0, scale: CGFloat = 1.0, rotation: Double = 0.0) {
        self.position = position
        self.velocity = velocity
        self.color = color
        self.size = size
        self.opacity = opacity
        self.scale = scale
        self.rotation = rotation
    }
} 