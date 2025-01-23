import SwiftUI
import AVFoundation

struct FloatingBubble: Identifiable {
    let id = UUID()
    var title: String
    let color: Color
    var position: CGPoint
    var size: CGFloat
    var velocity: CGPoint
}

struct FloatingBubbleView: View {
    let bubble: FloatingBubble
    let onTap: () -> Void
    @State private var glowScale: CGFloat = 1.0
    @State private var breathScale: CGFloat = 1.0
    
    // 添加 isEmoji 辅助函数
    private func isEmoji(_ text: String) -> Bool {
        return text.count == 1 && text.unicodeScalars.first?.properties.isEmoji ?? false
    }
    
    var body: some View {
        ZStack {
            // 彩虹光晕效果
            if !bubble.title.isEmpty {
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                bubble.color.opacity(0.6),
                                bubble.color.opacity(0.3),
                                bubble.color.opacity(0.6)
                            ],
                            center: .center
                        )
                    )
                    .frame(width: bubble.size, height: bubble.size)
                    .blur(radius: bubble.title.isEmpty ? 5 : 10)
                    .opacity(bubble.title.isEmpty ? 0.2 : 0.4)
                    .scaleEffect(glowScale)
            }
            
            // 气泡主体
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            bubble.color,
                            bubble.color.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: bubble.size * 0.95, height: bubble.size * 0.95)
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
                                endRadius: bubble.size * 0.5
                            )
                        )
                )
                .scaleEffect(breathScale)
            
            // 气泡文字
            if !bubble.title.isEmpty {
                Text(bubble.title)
                    .font(.system(size: isEmoji(bubble.title) ? bubble.size * 0.8 : min(bubble.size * 0.15, bubble.size * 0.15 * (10 / CGFloat(bubble.title.count)))))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 1, y: 1)
                    .scaleEffect(breathScale)
            }
        }
        .onTapGesture {
            onTap()
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
            ) {
                glowScale = 1.15
            }
            
            withAnimation(
                .easeInOut(duration: 2)
                .repeatForever(autoreverses: true)
            ) {
                breathScale = 1.05
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject var gameVM: GameViewModel
    @ObservedObject var userVM: UserViewModel
    @StateObject private var requestData = MyRequestData(level: 1)
    @StateObject private var level2Data = MyRequestData(level: 2)
    @StateObject private var level3Data = MyRequestData(level: 3)
    @StateObject private var settings = AppSettings.shared
    @State private var showGameView = false
    @State private var showLevel2View = false
    @State private var showLevel3View = false
    @State private var showRetryAlert = false
    @State private var showLearningView = false
    @State private var showPhraseGameView = false
    @State private var showSubscriptionView = false
    @State private var bubbles: [FloatingBubble] = []
    @State private var particles: [BurstParticle] = []
    @State private var clickPlayer: AVAudioPlayer?
    @State private var burstPlayer: AVAudioPlayer?
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    // 添加一个变量来跟踪气泡是否已被点击
    @State private var clickedBubbles: Set<String> = []
    
    // 添加 isEmoji 辅助函数
    private func isEmoji(_ text: String) -> Bool {
        return text.count == 1 && text.unicodeScalars.first?.properties.isEmoji ?? false
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景色
                settings.color.opacity(settings.backgroundOpacity).ignoresSafeArea()
                
                GeometryReader { geometry in
                    ZStack {
                        // 气泡
                        ForEach(bubbles) { bubble in
                            FloatingBubbleView(
                                bubble: bubble,
                                onTap: { handleBubbleTap(bubble: bubble, in: geometry) }
                            )
                            .position(
                                x: geometry.size.width * bubble.position.x,
                                y: geometry.size.height * bubble.position.y
                            )
                        }
                        
                        // 爆炸粒子
                        ForEach(particles) { particle in
                            Circle()
                                .fill(particle.color)
                                .frame(width: particle.size, height: particle.size)
                                .opacity(particle.opacity)
                                .scaleEffect(particle.scale)
                                .rotationEffect(.degrees(particle.rotation))
                                .position(particle.position)
                        }
                    }
                }
            }
            .onAppear {
                initializeBubbles()
                loadInitialData()
                setupAudioPlayers()
            }
            .onReceive(timer) { _ in
                updateBubblePositions()
                updateParticles()
            }
            .fullScreenCover(isPresented: $showGameView) {
                Level1(gameVM: gameVM, showGameView: $showGameView)
            }
            .fullScreenCover(isPresented: $showLevel2View) {
                Level2(gameVM: gameVM, showGameView: $showLevel2View)
            }
            .fullScreenCover(isPresented: $showLevel3View) {
                Level2(gameVM: gameVM, showGameView: $showLevel3View)
            }
            .fullScreenCover(isPresented: $showLearningView) {
                WordLearningView(
                    words: gameVM.currentWords,
                    showGameView: $showGameView,
                    showLearningView: $showLearningView
                )
            }
            .fullScreenCover(isPresented: $showPhraseGameView) {
                PhraseGameView()
            }
            .alert("加载失败", isPresented: $showRetryAlert) {
                Button("重试") {
                    retryLoadData()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("数据加载失败，是否重试？")
            }
            .sheet(isPresented: $showSubscriptionView) {
                SubscriptionView(userVM: userVM)
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func initializeBubbles() {
        // 主气泡
        let mainBubbles = [
            (title: "基础单词", color: Color(red: 0.9, green: 0.2, blue: 0.4), size: 120.0),
            (title: "进阶单词\n5000", color: Color(red: 0.3, green: 0.6, blue: 0.2), size: 130.0),
            (title: "高级英语单词", color: Color(red: 0.6, green: 0.4, blue: 0.9), size: 155.0),
            (title: "每日短语", color: Color(red: 0.1, green: 0.4, blue: 0.8), size: 100.0)
        ].map { bubble in
            FloatingBubble(
                title: bubble.title,
                color: bubble.color,
                position: CGPoint(
                    x: CGFloat.random(in: 0.2...0.8),
                    y: CGFloat.random(in: 0.2...0.8)
                ),
                size: bubble.size,
                velocity: CGPoint(
                    x: CGFloat.random(in: -4...4),
                    y: CGFloat.random(in: -4...4)
                )
            )
        }
        
        // 背景小气泡的多样化颜色
        let bubbleColors: [Color] = [
            Color(red: 0.4, green: 0.6, blue: 0.4),  // 蓝色
            Color(red: 0.9, green: 0.9, blue: 0.9),  // 红色
            Color(red: 0.4, green: 0.8, blue: 0.6),  // 绿色
            Color(red: 0.6, green: 0.4, blue: 0.9),  // 紫色
            Color(red: 0.9, green: 0.9, blue: 0.4),  // 橙色
//            Color(red: 0.6, green: 0.2, blue: 0.2),  // 棕色
            Color(red: 0.9, green: 0.5, blue: 0.7),  // 粉色
            Color(red: 0.5, green: 0.8, blue: 0.8)   // 青色
        ]
        
        // 添加表情数组
            let emojis = ["🐠","", "♻️", "☘️","🐸", "", "🔆"]
            
            // 背景小气泡样式设置:大小,数量,坐标
            let backgroundBubbles = (0..<15).map { _ in
                FloatingBubble(
                    title: emojis.randomElement()!, // 随机选择一个表情
                    color: bubbleColors.randomElement()!,
                    position: CGPoint(
                        x: CGFloat.random(in: 0.1...1.9),
                        y: CGFloat.random(in: 0.0...1.0)  // 修改为可以到达屏幕顶端和底部
                    ),
                    size: CGFloat.random(in: 20...80),
                    velocity: CGPoint(
                        x: CGFloat.random(in: -2...5),
                        y: CGFloat.random(in: -2...5)
                    )
                )
            }
        
        bubbles = mainBubbles + backgroundBubbles
    }
    
    private func updateBubblePositions() {
        var updatedBubbles = bubbles
        
        for i in updatedBubbles.indices {
            var newX = updatedBubbles[i].position.x + updatedBubbles[i].velocity.x / 1000
            var newY = updatedBubbles[i].position.y + updatedBubbles[i].velocity.y / 1000
            
            // 对主气泡（有标题的）使用较小的活动范围
            if !updatedBubbles[i].title.isEmpty && !updatedBubbles[i].title.contains("\n") && !isEmoji(updatedBubbles[i].title) {
                if newX < 0.1 || newX > 0.9 {
                    updatedBubbles[i].velocity.x *= -1
                    newX = max(0.1, min(0.9, newX))
                }
                if newY < 0.1 || newY > 0.9 {
                    updatedBubbles[i].velocity.y *= -1
                    newY = max(0.1, min(0.9, newY))
                }
            } else {
                // 对背景气泡使用全屏范围
                if newX < 0.0 || newX > 1.0 {
                    updatedBubbles[i].velocity.x *= -1
                    newX = max(0.0, min(1.0, newX))
                }
                if newY < 0.0 || newY > 1.0 {
                    updatedBubbles[i].velocity.y *= -1
                    newY = max(0.0, min(1.0, newY))
                }
            }
            
            updatedBubbles[i].position = CGPoint(x: newX, y: newY)
        }
        
        bubbles = updatedBubbles
    }
    
    // 加载初始数据
    private func loadInitialData() {
        print("视图加载，开始请求数据")
        requestData.requestData()
        level2Data.requestData()
        level3Data.requestData()
    }
    
    // 重试加载数据
    private func retryLoadData() {
        print("重试加载数据")
        requestData.requestData()
        level2Data.requestData()
        level3Data.requestData()
    }
    
    // 加载 Level1 数据
    private func loadLevel1Data() {
        print("点击开始游戏，尝试加载云端数据")
        requestData.requestData()
        
        // 等待云端数据加载结果
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if !requestData.funEnglishModeList.isEmpty {
                // 云端数据加载成功
                let randomWords = requestData.getRandomFiveWords()
                print("使用云端数据：\(randomWords.map { $0.english })")
                gameVM.setGameMode(isHard: false)
                gameVM.currentWords = randomWords
                showLearningView = true
            } else {
                // 云端数据加载失败，使用本地数据
                print("云端数据加载失败，尝试使用本地数据")
                let localWords = LocalDataManager.shared.getRandomFiveWords()
                if !localWords.isEmpty {
                    print("使用本地数据：\(localWords.map { $0.english })")
                    gameVM.setGameMode(isHard: false)
                    gameVM.currentWords = localWords
                    showLearningView = true
                } else {
                    print("本地数据也为空，显示重试提示")
                    showRetryAlert = true
                }
            }
        }
    }
    
    // 加载 Level2 数据
    private func loadLevel2Data() {
        print("点击开始 进阶单词5000 游戏，尝试加载云端数据")
        level2Data.requestData()
        
        // 等待云端数据加载结果
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if !level2Data.funEnglishModeList.isEmpty {
                // 云端数据加载成功
                let randomWords = level2Data.getRandomFiveWords()
                print("使用云端数据：\(randomWords.map { $0.english })")
                gameVM.setGameMode(isHard: true)
                gameVM.currentWords = randomWords
                showLearningView = true
            } else {
                // 云端数据加载失败，使用本地数据
                print("云端数据加载失败，尝试使用本地数据")
                let localWords = LocalDataManager.shared.getRandomFiveWords()
                if !localWords.isEmpty {
                    print("使用本地数据：\(localWords.map { $0.english })")
                    gameVM.setGameMode(isHard: true)
                    gameVM.currentWords = localWords
                    showLearningView = true
                } else {
                    print("本地数据也为空，显示重试提示")
                    showRetryAlert = true
                }
            }
        }
    }
    
    // 加载 Level3 数据
    private func loadLevel3Data() {
        print("点击开始 高级英语单词 游戏，尝试加载云端数据")
        level3Data.requestData()
        
        // 等待云端数据加载结果
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if !level3Data.funEnglishModeList.isEmpty {
                // 云端数据加载成功
                let randomWords = level3Data.getRandomFiveWords()
                print("使用云端数据：\(randomWords.map { $0.english })")
                gameVM.setGameMode(isHard: true)
                gameVM.currentWords = randomWords
                showLearningView = true
            } else {
                // 云端数据加载失败，使用本地数据
                print("云端数据加载失败，尝试使用本地数据")
                let localWords = LocalDataManager.shared.getRandomFiveWords()
                if !localWords.isEmpty {
                    print("使用本地数据：\(localWords.map { $0.english })")
                    gameVM.setGameMode(isHard: true)
                    gameVM.currentWords = localWords
                    showLearningView = true
                } else {
                    print("本地数据也为空，显示重试提示")
                    showRetryAlert = true
                }
            }
        }
    }
    
    private func handleBubbleTap(bubble: FloatingBubble, in geometry: GeometryProxy) {
        let position = CGPoint(
            x: geometry.size.width * bubble.position.x,
            y: geometry.size.height * bubble.position.y
        )
        
        if bubble.title.isEmpty {
            // 普通气泡点击效果
            clickPlayer?.currentTime = 0
            clickPlayer?.play()
            createSmallBurst(at: position, color: bubble.color)
        } else {
            // 主气泡点击效果
            burstPlayer?.currentTime = 0
            burstPlayer?.play()
            createBigBurst(at: position, color: bubble.color)
            
            // 延迟进入游戏界面，等待爆炸效果和音效播放完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if bubble.title == "基础单词" {
                    loadLevel1Data()
                } else if bubble.title == "进阶单词\n5000" || bubble.title == "高级英语单词" {
                    if IAPManager.shared.hasFullAccess {
                        if bubble.title == "进阶单词\n5000" {
                            loadLevel2Data()
                        } else {
                            loadLevel3Data()
                        }
                    } else {
                        showSubscriptionView = true
                    }
                } else if bubble.title == "每日短语" {
                    showPhraseGameView = true
                }
            }
        }
    }
    
    private func setupAudioPlayers() {
        // 设置普通点击音效
        if let clickSoundURL = Bundle.main.url(forResource: "gugugu", withExtension: "mp3") {
            do {
                clickPlayer = try AVAudioPlayer(contentsOf: clickSoundURL)
                clickPlayer?.prepareToPlay()
            } catch {
                print("Error loading gugu sound: \(error)")
            }
        }
        
        // 设置爆炸音效
        if let burstSoundURL = Bundle.main.url(forResource: "gugugu", withExtension: "mp3") {
            do {
                burstPlayer = try AVAudioPlayer(contentsOf: burstSoundURL)
                burstPlayer?.prepareToPlay()
            } catch {
                print("Error loading gugugu sound: \(error)")
            }
        }
    }
    
    private func createSmallBurst(at position: CGPoint, color: Color) {
        var newParticles = particles
        for _ in 0..<8 {
            let angle = Double.random(in: 0...2 * .pi)
            let speed = CGFloat.random(in: 2...4)
            let velocity = CGPoint(
                x: cos(angle) * speed,
                y: sin(angle) * speed
            )
            let particle = BurstParticle(
                position: position,
                velocity: velocity,
                color: color,
                size: CGFloat.random(in: 3...6),
                opacity: 1.0
            )
            newParticles.append(particle)
        }
        particles = newParticles
    }
    
    private func createBigBurst(at position: CGPoint, color: Color) {
        var newParticles = particles
        // 创建更多、更大、更快的粒子
        for _ in 0..<20 {
            let angle = Double.random(in: 0...2 * .pi)
            let speed = CGFloat.random(in: 5...12)
            let velocity = CGPoint(
                x: cos(angle) * speed,
                y: sin(angle) * speed
            )
            let particle = BurstParticle(
                position: position,
                velocity: velocity,
                color: color,
                size: CGFloat.random(in: 5...12),
                opacity: 1.0
            )
            newParticles.append(particle)
        }
        
        // 添加一些小粒子作为点缀
        for _ in 0..<10 {
            let angle = Double.random(in: 0...2 * .pi)
            let speed = CGFloat.random(in: 3...8)
            let velocity = CGPoint(
                x: cos(angle) * speed,
                y: sin(angle) * speed
            )
            let particle = BurstParticle(
                position: position,
                velocity: velocity,
                color: color.opacity(0.6),
                size: CGFloat.random(in: 2...5),
                opacity: 0.8
            )
            newParticles.append(particle)
        }
        particles = newParticles
    }
    
    private func updateParticles() {
        var updatedParticles = [BurstParticle]()
        
        for particle in particles {
            let age = Date().timeIntervalSince(particle.createdAt)
            if age > 0.8 { continue }  // 缩短粒子生命周期
            
            var updatedParticle = particle
            updatedParticle.position.x += particle.velocity.x
            updatedParticle.position.y += particle.velocity.y
            updatedParticle.opacity = max(0, 1 - age * 1.25)  // 加快淡出速度
            updatedParticle.scale = max(0, 1 - age * 0.8)
            updatedParticle.rotation += 8  // 加快旋转速度
            updatedParticle.velocity.y += 0.2  // 添加重力效果
            
            updatedParticles.append(updatedParticle)
        }
        
        particles = updatedParticles
    }
}

#Preview {
    ContentView(
        gameVM: GameViewModel(),
        userVM: UserViewModel()
    )
}
