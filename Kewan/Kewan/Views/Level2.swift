//
//  LevelOneView.swift
//  Kewan
//
//  Created by Zhongxin qiu on 2024/11/30.
//

import SwiftUI

struct Level2: View {
    @ObservedObject var gameVM: GameViewModel
    @StateObject private var audioVM = AudioViewModel()
    @Environment(\.dismiss) var dismiss
    @Binding var showGameView: Bool 
    @StateObject private var settings = AppSettings.shared
    
    // 保存初始选择的单词
    @State private var initialWords: [MyModel] = []
    
    // 气泡位置状态
    @State private var bubblePositions: [String: CGPoint] = [:]
    @State private var bubbleColors: [String: Color] = [:]
    @State private var bubbleSizes: [String: CGFloat] = [:]
    @State private var bubbleVelocities: [String: CGPoint] = [:]
    @State private var animationTimer: Timer?
    @State private var particles: [BurstParticle] = []
    
    // 动画效果
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.0
    @State private var animatedScore: Double = 0  // 添加动画分数状态
    @State private var scoreTimer: Timer?  // 添加计分动画计时器
    
    let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .mint,.cyan,.yellow]
    
    // 使用 Level2 的本地数据
    @StateObject private var requestData = MyRequestData(level: 2)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景色
                settings.color.opacity(settings.backgroundOpacity).ignoresSafeArea()
                
                // 顶部信息栏
                VStack {
                    HStack {
                        Button(action: {
                            cleanup()
                            dismiss()
                        }) {
                            //返回按钮
                        }
                        Spacer()
                    }
                    .padding()
                    
                    Spacer()
                }
                
                // 粒子效果
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .opacity(particle.opacity)
                        .scaleEffect(particle.scale)
                        .rotationEffect(.degrees(particle.rotation))
                        .position(particle.position)
                }
                
                // 气泡
                ForEach(gameVM.currentWords) { word in
                    let enKey = word.id + "_en"
                    let cnKey = word.id + "_cn"
                    
                    // 英文气泡
                    if let position = bubblePositions[enKey] {
                        LevelBubbleView(
                            word: word.english,
                            color: bubbleColors[enKey] ?? colors.randomElement()!,
                            position: position,
                            bubbleId: enKey,
                            size: bubbleSizes[enKey] ?? 150,
                            gameVM: gameVM,
                            audioVM: audioVM
                        )
                    }

                    // 中文气泡
                    if let position = bubblePositions[cnKey] {
                        LevelBubbleView(
                            word: word.chinese,
                            color: bubbleColors[cnKey] ?? colors.randomElement()!,
                            position: position,
                            bubbleId: cnKey,
                            size: bubbleSizes[cnKey] ?? 150,
                            gameVM: gameVM,
                            audioVM: audioVM
                        )
                    }
                }
                
                // 完成动画层
                if gameVM.isShowingCompletionAnimation {
                    // 半透明黑色背景
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    
                    // 使用 GeometryReader 来确保绝对定位
                    GeometryReader { geometry in
                        // 固定布局容器
                        VStack(spacing: 0) {
                            // 分数显示区域 - 固定在屏幕中间
                            VStack(spacing: 0) {
                                Spacer()
                                Text("Score: \(String(format: "%.1f", animatedScore))")
                                    .font(.system(size: 46, weight: .bold))
                                    .foregroundColor(.white)
                                    .opacity(opacity)
                                    .frame(width: geometry.size.width, height: 60)
                                    .background(Color.clear)
                                Spacer()
                            }
                            .frame(height: geometry.size.height * 0.7)
                            
                            // 按钮区域 - 固定在底部
                            if gameVM.showContinueOptions {
                                VStack {
                                    HStack {
                                        Button(action: {
                                            cleanup()
                                            initialWords.removeAll()
                                            dismiss()
                                        }) {
                                            Text("返回主菜单")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                                .padding()
                                                .frame(width: 160, height: 50)
                                                .cornerRadius(10)
                                        }
                                        
                                        Spacer()
                                            .frame(width: 20)
                                        
                                        Button(action: {
                                            if gameVM.isGameCompleted {
                                                print("点击重新游戏按钮")
                                                // 重置游戏状态
                                                stopAnimation()
                                                bubblePositions.removeAll()
                                                bubbleColors.removeAll()
                                                bubbleSizes.removeAll()
                                                bubbleVelocities.removeAll()
                                                particles.removeAll()
                                                
                                                // 重置游戏状态
                                                gameVM.currentLevel = 2
                                                gameVM.isGameCompleted = false
                                                gameVM.isListeningMode = false
                                                gameVM.isShowingCompletionAnimation = false
                                                gameVM.showContinueOptions = false
                                                
                                                // 使用保存的初始单词
                                                if !initialWords.isEmpty {
                                                    print("重新使用保存的单词：\(initialWords.map { $0.english }.joined(separator: ", "))")
                                                    gameVM.currentWords = initialWords
                                                } else {
                                                    print("没有保存的单词，使用新单词")
                                                    gameVM.startNewGame(level: 2)
                                                    initialWords = gameVM.currentWords
                                                }
                                                
                                                // 重新初始化游戏
                                                initializeBubbles()
                                                startAnimation()
                                            } else {
                                                print("点击听力练习按钮")
                                                gameVM.continueToListeningMode()
                                            }
                                        }) {
                                            Text(gameVM.isGameCompleted ? "重新练习" : "听力练习")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                                .padding()
                                                .frame(width: 160, height: 50)
                                                .cornerRadius(10)
                                        }
                                    }
                                    .frame(height: 70)
                                }
                                .frame(height: geometry.size.height * 0.3)
                                .padding(.horizontal, 30)
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: gameVM.matchedPair) { newValue in
            if let pair = newValue {
                handleMatchEffect(firstId: pair.firstId, secondId: pair.secondId)
            }
        }
        .onChange(of: gameVM.isShowingCompletionAnimation) { newValue in
            if newValue {
                playCompletionAnimation()
            }
        }
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.width > 100 {
                        cleanupAndDismiss()
                    }
                }
        )
        .onAppear {
            // 直接使用 ContentView 传入的数据开始游戏
            print("Level2 onAppear")
            gameVM.currentLevel = 2
            
            if initialWords.isEmpty {
                // 首次加载游戏，保存初始单词
                print("Level2: 首次加载游戏数据")
                gameVM.startNewGame(level: 2)
                initialWords = gameVM.currentWords
                print("首次保存初始单词：\(initialWords.map { $0.english }.joined(separator: ", "))")
            } else {
                // 已有保存的单词，直接使用
                print("Level2: 使用保存的初始单词")
                gameVM.currentWords = initialWords
                print("使用保存的单词：\(initialWords.map { $0.english }.joined(separator: ", "))")
            }
            
            initializeBubbles()
            startAnimation()
        }
        .onDisappear {
            cleanup()
        }
    }
}

#Preview("Level2 Preview") {
    NavigationView {
        Level2(gameVM: {
            let vm = GameViewModel()
            // 使用静态测试数据，避免在预览中进行实际的数据获取
            vm.currentWords = [
                MyModel(id: "1", english: "Apple", chinese: "苹果"),
                MyModel(id: "2", english: "Banana", chinese: "香蕉"),
                MyModel(id: "3", english: "Orange", chinese: "橙子"),
                MyModel(id: "4", english: "Grape", chinese: "葡萄"),
                MyModel(id: "5", english: "Peach", chinese: "桃子")
            ]
            return vm
        }(),
        showGameView: .constant(true))
    }
}

// 添加所有必要的方法
extension Level2 {
    // 生成随机位置
    private func randomPosition(in geometry: GeometryProxy) -> CGPoint {
        CGPoint(
            x: CGFloat.random(in: 50...(geometry.size.width - 50)),
            y: CGFloat.random(in: 100...(geometry.size.height - 100))
        )
    }
    
    // 初始化气泡
    private func initializeBubbles() {
        bubblePositions.removeAll()
        bubbleColors.removeAll()
        bubbleSizes.removeAll()
        bubbleVelocities.removeAll()
        particles.removeAll()
        
        let screenBounds = UIScreen.main.bounds
        let minSize: CGFloat = 120
        let maxSize: CGFloat = 150
        
        for word in gameVM.currentWords {
            let enKey = word.id + "_en"
            let cnKey = word.id + "_cn"
            
            // 设置随机颜色
            var availableColors = colors
            let englishColorIndex = Int.random(in: 0..<availableColors.count)
            let englishColor = availableColors.remove(at: englishColorIndex)
            bubbleColors[enKey] = englishColor
            
            let chineseColorIndex = Int.random(in: 0..<availableColors.count)
            let chineseColor = availableColors[chineseColorIndex]
            bubbleColors[cnKey] = chineseColor
            
            // 设置随机大小
            bubbleSizes[enKey] = CGFloat.random(in: minSize...maxSize)
            bubbleSizes[cnKey] = CGFloat.random(in: minSize...maxSize)
            
            // 设置初始位置
            bubblePositions[enKey] = CGPoint(
                x: CGFloat.random(in: 50...(screenBounds.width - 50)),
                y: CGFloat.random(in: 100...(screenBounds.height - 100))
            )
            bubblePositions[cnKey] = CGPoint(
                x: CGFloat.random(in: 50...(screenBounds.width - 50)),
                y: CGFloat.random(in: 100...(screenBounds.height - 100))
            )
            
            // 设置初始速度
            let baseSpeed: CGFloat = 30
            bubbleVelocities[enKey] = CGPoint(
                x: CGFloat.random(in: -baseSpeed...baseSpeed),
                y: CGFloat.random(in: -baseSpeed...baseSpeed)
            )
            bubbleVelocities[cnKey] = CGPoint(
                x: CGFloat.random(in: -baseSpeed...baseSpeed),
                y: CGFloat.random(in: -baseSpeed...baseSpeed)
            )
        }
    }
    
    // 检查位置是否有效
    private func isValidPosition(_ position: CGPoint, usedPositions: Set<String>) -> Bool {
        let minDistance: CGFloat = 100 // 最小间距
        
        for usedPos in usedPositions {
            let components = usedPos.split(separator: ",")
            if components.count == 2,
               let x = Double(components[0]),
               let y = Double(components[1]) {
                let usedPoint = CGPoint(x: x, y: y)
                let distance = hypot(position.x - usedPoint.x, position.y - usedPoint.y)
                if distance < minDistance {
                    return false
                }
            }
        }
        return true
    }
    
    // 创建破裂效果
    private func createBurstEffect(at position: CGPoint, color: Color) {
        // 主要粒子
        for _ in 0..<40 {
            let angle = Double.random(in: 0...2 * .pi)
            let speed = CGFloat.random(in: 3...10)
            let velocity = CGPoint(
                x: CGFloat(Darwin.cos(angle)) * speed,
                y: CGFloat(Darwin.sin(angle)) * speed
            )
            let particle = BurstParticle(
                position: position,
                velocity: velocity,
                color: color,
                size: CGFloat.random(in: 5...15),
                opacity: 1.0,
                scale: 1.0,
                rotation: Double.random(in: 0...360)
            )
            particles.append(particle)
        }
        
        // 添加小型点缀粒子
        for _ in 0..<30 {
            let angle = Double.random(in: 0...2 * .pi)
            let speed = CGFloat.random(in: 2...8)
            let velocity = CGPoint(
                x: CGFloat(Darwin.cos(angle)) * speed,
                y: CGFloat(Darwin.sin(angle)) * speed
            )
            let particle = BurstParticle(
                position: position,
                velocity: velocity,
                color: color.opacity(0.6),
                size: CGFloat.random(in: 2...8),
                opacity: 0.8,
                scale: 1.0,
                rotation: Double.random(in: 0...360)
            )
            particles.append(particle)
        }
    }
    
    // 更新粒子
    private func updateParticles() {
        for index in (0..<particles.count).reversed() {
            var particle = particles[index]
            
            // 更新位置
            particle.position.x += particle.velocity.x * 0.7
            particle.position.y += particle.velocity.y * 0.7
            
            // 添加重力效果
            particle.velocity.y += 0.1
            
            // 更新旋转
            particle.rotation += 3
            
            // 更新缩放和透明度 - 加快衰减速度
            particle.scale = max(0, particle.scale - 0.02)  // 从0.005改为0.02
            particle.opacity = max(0, particle.opacity - 0.02)  // 从0.005改为0.02
            
            if particle.opacity <= 0 {
                particles.remove(at: index)
            } else {
                particles[index] = particle
            }
        }
    }
    
    // 处理匹配效果
    private func handleMatchEffect(firstId: String, secondId: String) {
        if let firstPosition = bubblePositions[firstId],
           let secondPosition = bubblePositions[secondId],
           let firstColor = bubbleColors[firstId],
           let secondColor = bubbleColors[secondId] {
            
            createBurstEffect(at: firstPosition, color: firstColor)
            createBurstEffect(at: secondPosition, color: secondColor)
            
            audioVM.playMatchSound()
        }
    }
    
    // 开始动画
    private func startAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            for word in gameVM.currentWords {
                let enKey = word.id + "_en"
                let cnKey = word.id + "_cn"
                
                updateBubble(key: enKey)
                updateBubble(key: cnKey)
            }
            updateParticles()
        }
    }
    
    // 更新单个气泡
    private func updateBubble(key: String) {
        guard var position = bubblePositions[key],
              var velocity = bubbleVelocities[key],
              !gameVM.isBubbleSelected(key) else { return }
        
        let deltaTime: CGFloat = 0.016
        position.x += velocity.x * deltaTime
        position.y += velocity.y * deltaTime
        
        let screenBounds = UIScreen.main.bounds
        let margin: CGFloat = 50
        let dampingFactor: CGFloat = 0.95 // 减小反弹力度
        
        // 边界碰撞检测
        if position.x < margin {
            position.x = margin
            velocity.x = abs(velocity.x) * dampingFactor
        } else if position.x > screenBounds.width - margin {
            position.x = screenBounds.width - margin
            velocity.x = -abs(velocity.x) * dampingFactor
        }
        
        if position.y < margin {
            position.y = margin
            velocity.y = abs(velocity.y) * dampingFactor
        } else if position.y > screenBounds.height - margin {
            position.y = screenBounds.height - margin
            velocity.y = -abs(velocity.y) * dampingFactor
        }
        
        // 添加轻微随机扰动
        velocity.x += CGFloat.random(in: -2...2)
        velocity.y += CGFloat.random(in: -2...2)
        
        // 限制最大速度
        let maxSpeed: CGFloat = 60
        let currentSpeed = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
        if currentSpeed > maxSpeed {
            velocity.x = velocity.x / currentSpeed * maxSpeed
            velocity.y = velocity.y / currentSpeed * maxSpeed
        }
        
        withAnimation(.linear(duration: deltaTime)) {
            bubblePositions[key] = position
            bubbleVelocities[key] = velocity
        }
    }
    
    // 停止动画
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    // 设置游戏
    private func setupGame() {
        // 移除 startNewGame 调用，只初始化气泡和动画
        initializeBubbles()
        startAnimation()
    }
    
    // 清理资源
    private func cleanup() {
        animationTimer?.invalidate()
        animationTimer = nil
        scoreTimer?.invalidate() // 清理计分动画计时器
        scoreTimer = nil
        particles.removeAll()
        bubblePositions.removeAll()
        bubbleVelocities.removeAll()
    }
    
    // 清理并返回
    private func cleanupAndDismiss() {
        cleanup()
        dismiss()
    }
    
    // 播放完成动画
    private func playCompletionAnimation() {
        audioVM.playGoodSound()
        
        // 创建多组烟花
        for _ in 0...8 {
            let screenBounds = UIScreen.main.bounds
            let position = CGPoint(
                x: CGFloat.random(in: screenBounds.width * 0.2...screenBounds.width * 0.8),
                y: CGFloat.random(in: screenBounds.height * 0.2...screenBounds.height * 0.8)
            )
            createBurstEffect(at: position, color: colors.randomElement()!)
        }
        
        // 重置动画分数为0
        animatedScore = 0
        
        // 先显示分数文本
        withAnimation(.easeOut(duration: 0.5)) {
            opacity = 1
            scale = 1.5
        }
        
        // 延迟0.5秒后开始分数动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 创建计时器，每0.1秒增加一分
            scoreTimer?.invalidate() // 确保之前的计时器被清理
            scoreTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                if animatedScore < gameVM.score {
                    // 计算下一个分数值，每次增加3分，但不超过最终分数
                                       let nextScore = min(animatedScore + 3, gameVM.score)
                                       animatedScore = nextScore
                                       audioVM.playScoreSound() // 播放得分音效
                    // 如果达到最终分数，停止计时器
                                        if animatedScore >= gameVM.score {
                                            timer.invalidate()
                                            scoreTimer = nil
                                        }
                }
            }
        }
    }
    
    private func createBurst(at position: CGPoint, color: Color) {
        for _ in 0..<10 {
            let angle = Double.random(in: 0...2 * .pi)
            let speed = CGFloat.random(in: 2...5)
            let velocity = CGPoint(
                x: CGFloat(Darwin.cos(angle)) * speed,
                y: CGFloat(Darwin.sin(angle)) * speed
            )
            let particle = BurstParticle(
                position: position,
                velocity: velocity,
                color: color,
                size: CGFloat.random(in: 3...8)
            )
            particles.append(particle)
        }
    }
    
    // 重新开始游戏
    private func restartGame() {
        print("重新开始游戏，使用当前单词")
        stopAnimation()
        
        // 保存当前单词
        let currentWords = gameVM.currentWords
        
        // 重置所有状态
        bubblePositions.removeAll()
        bubbleColors.removeAll()
        bubbleSizes.removeAll()
        bubbleVelocities.removeAll()
        particles.removeAll()
        
        gameVM.isGameCompleted = false
        gameVM.isListeningMode = false
        gameVM.isShowingCompletionAnimation = false
        gameVM.showContinueOptions = false
        
        // 确保使用相同的单词
        gameVM.currentWords = currentWords
        
        initializeBubbles()
        startAnimation()
    }
}
