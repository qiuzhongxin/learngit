////
////  WalkingCorpseView.swift
////  Kewan
////
////  Created by Zhongxin qiu on 2024/12/27.
////
//
//import SwiftUI
//
//struct WalkingCorpseView: View {
//    @State private var currentFrame = 1
//    @State private var currentWords: [Word] = []
//    @State private var selectedBubbleId: String?
//    @State private var matchedPairs: Set<String> = []
//    @State private var isZombieExploding = false
//    @State private var particles: [BurstParticle] = []
//    @State private var timer: Timer?
//    @State private var bubblePositions: [String: CGPoint] = [:]
//    @State private var bubbleVelocities: [String: CGPoint] = [:]
//    @State private var animationTimer: Timer?
//    @State private var matchCount: Int = 0
//    @State private var zombieOffset: CGSize = .zero
//    @State private var zombiePosition: CGPoint = .zero
//    @State private var zombieScale: CGFloat = 1.0
//    @State private var isGameOver = false
//    @State private var remainingTime: Int = 10
//    @State private var countdownTimer: Timer?
//    @State private var zombieVelocity: CGPoint = .zero
//    
//    // 添加气泡颜色数组
//    private let bubbleColors: [Color] = [
//        Color(red: 0.2, green: 0.8, blue: 0.2),  // 蓝绿色
//        Color(red: 0.9, green: 0.2, blue: 0.9),  // 白色
//        Color(red: 0.4, green: 0.8, blue: 0.6),  // 绿色
//        Color(red: 0.6, green: 0.4, blue: 0.9),  // 紫色
//        Color(red: 0.9, green: 0.9, blue: 0.2),  // 黄色
//        Color(red: 0.9, green: 0.5, blue: 0.7),  // 粉色
//        Color(red: 0.5, green: 0.8, blue: 0.8)   // 青色
//    ]
//    
//    @State private var bubbleColorMap: [String: Color] = [:]  // 存储每个气泡的颜色
//    
//    let frameTimer = Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()
//    
//    var body: some View {
//        GeometryReader { geometry in
//            ZStack {
//                Color.mint.opacity(0.6).ignoresSafeArea()
//                
//                // 倒计时显示
//                VStack {
//                    Text("\(remainingTime)")
//                        .font(.system(size: 40, weight: .bold))
//                        .foregroundColor(.white)
//                        .padding()
//                    Spacer()
//                }
//                
//                // 僵尸
//                if !isZombieExploding {
//                    Image("jiangshi\(currentFrame)")
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .frame(width: 200 * zombieScale, height: 200 * zombieScale)
//                        .position(zombiePosition)
//                        .offset(zombieOffset)
//                        .onReceive(frameTimer) { _ in
//                            currentFrame = currentFrame == 1 ? 2 : 1
//                            if !isGameOver {
//                                updateZombiePosition(in: geometry)
//                            }
//                        }
//                }
//                
//                // 英语和中文气泡
//                ForEach(currentWords) { word in
//                    // 英语气泡
//                    if !matchedPairs.contains("\(word.id)_en") {
//                        GameBubbleView(
//                            word: word.english,
//                            color: bubbleColorMap["\(word.id)_en"] ?? .blue,
//                            position: bubblePositions["\(word.id)_en"] ?? CGPoint(x: geometry.size.width * 0.25, y: geometry.size.height * 0.7),
//                            bubbleId: "\(word.id)_en",
//                            size: 100,
//                            isSelected: selectedBubbleId == "\(word.id)_en"
//                        ) {
//                            handleBubbleTap(id: "\(word.id)_en")
//                        }
//                    }
//                    
//                    // 中文气泡
//                    if !matchedPairs.contains("\(word.id)_cn") {
//                        GameBubbleView(
//                            word: word.chinese,
//                            color: bubbleColorMap["\(word.id)_cn"] ?? .green,
//                            position: bubblePositions["\(word.id)_cn"] ?? CGPoint(x: geometry.size.width * 0.75, y: geometry.size.height * 0.7),
//                            bubbleId: "\(word.id)_cn",
//                            size: 100,
//                            isSelected: selectedBubbleId == "\(word.id)_cn"
//                        ) {
//                            handleBubbleTap(id: "\(word.id)_cn")
//                        }
//                    }
//                }
//                
//                // 爆炸粒子效果
//                ForEach(particles) { particle in
//                    Circle()
//                        .fill(particle.color)
//                        .frame(width: particle.size, height: particle.size)
//                        .opacity(particle.opacity)
//                        .position(particle.position)
//                }
//            }
//        }
//        .onAppear {
//            loadRandomWords()
//            initializeBubblePositions()
//            initializeBubbleColors()  // 初始化气泡颜色
//            startAnimation()
//            startCountdown()
//            initializeZombie()
//            isGameOver = false
//        }
//        .onDisappear {
//            stopAnimation()
//            stopCountdown()
//            timer?.invalidate()
//            timer = nil
//        }
//    }
//    
//    private func startAnimation() {
//        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
//            updateBubblePositions()
//        }
//    }
//    
//    private func stopAnimation() {
//        animationTimer?.invalidate()
//        animationTimer = nil
//    }
//    
//    private func updateBubblePositions() {
//        let screenBounds = UIScreen.main.bounds
//        let margin: CGFloat = 50
//        let dampingFactor: CGFloat = 0.95
//        
//        for word in currentWords {
//            let enKey = "\(word.id)_en"
//            let cnKey = "\(word.id)_cn"
//            
//            updateBubble(key: enKey, screenBounds: screenBounds, margin: margin, dampingFactor: dampingFactor)
//            updateBubble(key: cnKey, screenBounds: screenBounds, margin: margin, dampingFactor: dampingFactor)
//        }
//    }
//    
//    private func updateBubble(key: String, screenBounds: CGRect, margin: CGFloat, dampingFactor: CGFloat) {
//        guard var position = bubblePositions[key],
//              var velocity = bubbleVelocities[key],
//              !matchedPairs.contains(key) else { return }
//        
//        let deltaTime: CGFloat = 0.016
//        
//        // 更新位置
//        position.x += velocity.x * deltaTime
//        position.y += velocity.y * deltaTime
//        
//        // 边界碰撞检测
//        if position.x < margin {
//            position.x = margin
//            velocity.x = abs(velocity.x) * dampingFactor
//        } else if position.x > screenBounds.width - margin {
//            position.x = screenBounds.width - margin
//            velocity.x = -abs(velocity.x) * dampingFactor
//        }
//        
//        if position.y < margin {
//            position.y = margin
//            velocity.y = abs(velocity.y) * dampingFactor
//        } else if position.y > screenBounds.height - margin {
//            position.y = screenBounds.height - margin
//            velocity.y = -abs(velocity.y) * dampingFactor
//        }
//        
//        // 添加随机扰动
//        velocity.x += CGFloat.random(in: -2...2)
//        velocity.y += CGFloat.random(in: -2...2)
//        
//        // 限制最大速度
//        let maxSpeed: CGFloat = 50
//        let currentSpeed = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
//        if currentSpeed > maxSpeed {
//            velocity.x = velocity.x / currentSpeed * maxSpeed
//            velocity.y = velocity.y / currentSpeed * maxSpeed
//        }
//        
//        withAnimation(.linear(duration: deltaTime)) {
//            bubblePositions[key] = position
//            bubbleVelocities[key] = velocity
//        }
//    }
//    
//    private func initializeBubblePositions() {
//        bubblePositions.removeAll()
//        bubbleVelocities.removeAll()
//        
//        let screenBounds = UIScreen.main.bounds
//        let safeMargin: CGFloat = 80
//        
//        // 创建网格布局
//        let columns: Int = 4
//        let rows: Int = 3
//        let cellWidth = (screenBounds.width - 2 * safeMargin) / CGFloat(columns)
//        let cellHeight = (screenBounds.height - 2 * safeMargin) / CGFloat(rows)
//        
//        var usedPositions: Set<String> = []
//        
//        for word in currentWords {
//            // 为英文气泡找位置和设置初始速度
//            repeat {
//                let col = Int.random(in: 0..<columns)
//                let row = Int.random(in: 0..<rows)
//                let x = safeMargin + cellWidth * CGFloat(col) + CGFloat.random(in: 0...cellWidth/2)
//                let y = safeMargin + cellHeight * CGFloat(row) + CGFloat.random(in: 0...cellHeight/2)
//                let position = CGPoint(x: x, y: y)
//                let positionKey = "\(Int(x)),\(Int(y))"
//                
//                if !usedPositions.contains(positionKey) {
//                    let enKey = "\(word.id)_en"
//                    bubblePositions[enKey] = position
//                    bubbleVelocities[enKey] = randomInitialVelocity()
//                    usedPositions.insert(positionKey)
//                    break
//                }
//            } while true
//            
//            // 为中文气泡找位置和设置初始速度
//            repeat {
//                let col = Int.random(in: 0..<columns)
//                let row = Int.random(in: 0..<rows)
//                let x = safeMargin + cellWidth * CGFloat(col) + CGFloat.random(in: 0...cellWidth/2)
//                let y = safeMargin + cellHeight * CGFloat(row) + CGFloat.random(in: 0...cellHeight/2)
//                let position = CGPoint(x: x, y: y)
//                let positionKey = "\(Int(x)),\(Int(y))"
//                
//                if !usedPositions.contains(positionKey) {
//                    let cnKey = "\(word.id)_cn"
//                    bubblePositions[cnKey] = position
//                    bubbleVelocities[cnKey] = randomInitialVelocity()
//                    usedPositions.insert(positionKey)
//                    break
//                }
//            } while true
//        }
//    }
//    
//    private func randomInitialVelocity() -> CGPoint {
//        let baseSpeed: CGFloat = 30
//        return CGPoint(
//            x: CGFloat.random(in: -baseSpeed...baseSpeed),
//            y: CGFloat.random(in: -baseSpeed...baseSpeed)
//        )
//    }
//    
//    private func loadRandomWords() {
//        if let url = Bundle.main.url(forResource: "WalkingCorpseJson", withExtension: "json"),
//           let jsonData = try? Data(contentsOf: url),
//           let words = try? JSONDecoder().decode([Word].self, from: jsonData) {
//            // 随机选择5个单词
//            let shuffledWords = words.shuffled()
//            currentWords = Array(shuffledWords.prefix(5))
//        }
//    }
//    
//    private func handleBubbleTap(id: String) {
//        if let selected = selectedBubbleId {
//            let selectedWordId = String(selected.split(separator: "_")[0])
//            let tappedWordId = String(id.split(separator: "_")[0])
//            
//            if selectedWordId == tappedWordId && selected != id {
//                // 获取两个气泡的位置
//                if let pos1 = bubblePositions[selected],
//                   let pos2 = bubblePositions[id] {
//                    // 在两个气泡位置创建破裂效果
//                    createBurstEffect(at: pos1)
//                    createBurstEffect(at: pos2)
//                }
//                
//                // 匹配成功
//                matchedPairs.insert(selected)
//                matchedPairs.insert(id)
//                selectedBubbleId = nil
//                
//                // 增加匹配计数并触发僵尸晃动效果
//                matchCount += 1
//                shakeZombie()
//                
//                // 检查是否完成所有匹配
//                if matchCount >= 5 {
//                    // 玩家胜利
//                    stopCountdown()
//                    withAnimation(.easeInOut(duration: 0.5)) {
//                        isZombieExploding = true
//                    }
//                    
//                    // 延迟重置游戏
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                        resetGame()
//                    }
//                }
//            } else {
//                selectedBubbleId = id
//            }
//        } else {
//            selectedBubbleId = id
//        }
//    }
//    
//    private func createBurstEffect(at position: CGPoint) {
//        for _ in 0..<15 {
//            let angle = Double.random(in: 0...2 * .pi)
//            let speed = CGFloat.random(in: 2...5)
//            let velocity = CGPoint(
//                x: CGFloat(cos(angle)) * speed,
//                y: CGFloat(sin(angle)) * speed
//            )
//            let particle = BurstParticle(
//                position: position,
//                velocity: velocity,
//                color: bubbleColors.randomElement()!,  // 使用气泡颜色数组中的随机颜色
//                size: CGFloat.random(in: 3...8)
//            )
//            particles.append(particle)
//        }
//        
//        // 更新粒子位置
//        timer?.invalidate()
//        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
//            for i in (0..<particles.count).reversed() {
//                particles[i].position.x += particles[i].velocity.x
//                particles[i].position.y += particles[i].velocity.y
//                particles[i].opacity -= 0.02
//                
//                if particles[i].opacity <= 0 {
//                    particles.remove(at: i)
//                }
//            }
//            
//            if particles.isEmpty {
//                timer?.invalidate()
//                timer = nil
//            }
//        }
//    }
//    
//    private func shakeZombie() {
//        let duration = 0.1
//        let strength: CGFloat = 10.0
//        
//        // 快速左右晃动
//        withAnimation(.easeInOut(duration: duration)) {
//            zombieOffset = CGSize(width: strength, height: 0)
//        }
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
//            withAnimation(.easeInOut(duration: duration)) {
//                zombieOffset = CGSize(width: -strength, height: 0)
//            }
//            
//            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
//                withAnimation(.easeInOut(duration: duration)) {
//                    zombieOffset = CGSize(width: strength/2, height: 0)
//                }
//                
//                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
//                    withAnimation(.easeInOut(duration: duration)) {
//                        zombieOffset = .zero
//                    }
//                }
//            }
//        }
//    }
//    
//    private func gameOver() {
//        isGameOver = true
//        
//        // 创建所有气泡的爆炸效果并将它们添加到匹配集合中（使它们消失）
//        for word in currentWords {
//            if let pos1 = bubblePositions["\(word.id)_en"],
//               !matchedPairs.contains("\(word.id)_en") {
//                createBurstEffect(at: pos1)
//                matchedPairs.insert("\(word.id)_en")
//            }
//            if let pos2 = bubblePositions["\(word.id)_cn"],
//               !matchedPairs.contains("\(word.id)_cn") {
//                createBurstEffect(at: pos2)
//                matchedPairs.insert("\(word.id)_cn")
//            }
//        }
//        
//        // 僵尸移动到屏幕中央并变大
//        let screenBounds = UIScreen.main.bounds
//        let centerPosition = CGPoint(x: screenBounds.width / 2, y: screenBounds.height / 2)
//        
//        // 先等待气泡爆炸效果完成，再移动僵尸
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//            withAnimation(.easeInOut(duration: 1.0)) {
//                zombiePosition = centerPosition
//                zombieScale = 3.0
//            }
//            
//            // 延迟重置游戏
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                resetGame()
//            }
//        }
//    }
//    
//    private func resetGame() {
//        isZombieExploding = false
//        particles.removeAll()
//        matchCount = 0
//        zombieOffset = .zero
//        isGameOver = false
//        matchedPairs.removeAll()
//        loadRandomWords()
//        initializeBubblePositions()
//        initializeBubbleColors()  // 重置气泡颜色
//        initializeZombie()
//        startCountdown()
//    }
//    
//    private func startCountdown() {
//        remainingTime = 10
//        countdownTimer?.invalidate()
//        
//        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
//            if remainingTime > 0 {
//                remainingTime -= 1
//                if remainingTime == 0 && !isGameOver {
//                    gameOver()
//                }
//            }
//        }
//    }
//    
//    private func stopCountdown() {
//        countdownTimer?.invalidate()
//        countdownTimer = nil
//    }
//    
//    private func initializeZombie() {
//        // 设置僵尸初始位置（屏幕中上方）
//        let screenBounds = UIScreen.main.bounds
//        zombiePosition = CGPoint(
//            x: screenBounds.width / 2,
//            y: screenBounds.height / 4
//        )
//        
//        // 设置随机初始速度
//        zombieVelocity = CGPoint(
//            x: CGFloat.random(in: -50...50),
//            y: CGFloat.random(in: -50...50)
//        )
//        
//        zombieScale = 1.0
//    }
//    
//    private func updateZombiePosition(in geometry: GeometryProxy) {
//        let deltaTime: CGFloat = 0.8
//        let margin: CGFloat = 100
//        
//        // 更新位置
//        var newPosition = zombiePosition
//        newPosition.x += zombieVelocity.x * deltaTime
//        newPosition.y += zombieVelocity.y * deltaTime
//        
//        // 边界碰撞检测
//        if newPosition.x < margin {
//            newPosition.x = margin
//            zombieVelocity.x = abs(zombieVelocity.x)
//        } else if newPosition.x > geometry.size.width - margin {
//            newPosition.x = geometry.size.width - margin
//            zombieVelocity.x = -abs(zombieVelocity.x)
//        }
//        
//        if newPosition.y < margin {
//            newPosition.y = margin
//            zombieVelocity.y = abs(zombieVelocity.y)
//        } else if newPosition.y > geometry.size.height - margin {
//            newPosition.y = geometry.size.height - margin
//            zombieVelocity.y = -abs(zombieVelocity.y)
//        }
//        
//        // 添加随机扰动
//        zombieVelocity.x += CGFloat.random(in: -5...5)
//        zombieVelocity.y += CGFloat.random(in: -5...5)
//        
//        // 限制最大速度
//        let maxSpeed: CGFloat = 100
//        let currentSpeed = sqrt(zombieVelocity.x * zombieVelocity.x + zombieVelocity.y * zombieVelocity.y)
//        if currentSpeed > maxSpeed {
//            zombieVelocity.x = zombieVelocity.x / currentSpeed * maxSpeed
//            zombieVelocity.y = zombieVelocity.y / currentSpeed * maxSpeed
//        }
//        
//        withAnimation(.linear(duration: deltaTime)) {
//            zombiePosition = newPosition
//        }
//    }
//    
//    private func initializeBubbleColors() {
//        bubbleColorMap.removeAll()
//        for word in currentWords {
//            bubbleColorMap["\(word.id)_en"] = bubbleColors.randomElement()!
//            bubbleColorMap["\(word.id)_cn"] = bubbleColors.randomElement()!
//        }
//    }
//}
//
//#Preview {
//    WalkingCorpseView()
//}
