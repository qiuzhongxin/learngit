import SwiftUI
import AVFoundation

struct PhraseGameView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var settings = AppSettings.shared
    @State private var currentWords: [Word] = []
    @State private var selectedBubbleId: String?
    @State private var matchedPairs: Set<String> = []
    @State private var particles: [BurstParticle] = []
    @State private var timer: Timer?
    @State private var bubblePositions: [String: CGPoint] = [:]
    @State private var bubbleVelocities: [String: CGPoint] = [:]
    @State private var animationTimer: Timer?
    @State private var matchCount: Int = 0
    @State private var isGameOver = false
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var matchPlayer: AVAudioPlayer?
    @State private var score: Int = 0
    
    private let bubbleColors: [Color] = [ .purple, .mint,.indigo, .blue, .pink]
    
    @State private var bubbleColorMap: [String: Color] = [:]
    @State private var bubbleSizes: [String: CGFloat] = [:]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                settings.color.opacity(settings.backgroundOpacity)
                    .ignoresSafeArea()
                    .gesture(
                        DragGesture()
                            .onEnded { gesture in
                                if gesture.translation.width > 100 {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                    )
                
                // 分数显示
                VStack {
                    HStack {
                        Spacer()
//                        Text("Score: \(score)")
//                            .font(.title)
//                            .foregroundColor(.white)
//                            .padding()
                    }
                    Spacer()
                }
                
                // 匹配进度显示
                VStack {
                    Text("\(matchCount)/3")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                    Spacer()
                }
                
                // 英语和中文气泡
                ForEach(currentWords) { word in
                    // 英语气泡
                    if !matchedPairs.contains("\(word.id)_en") {
                        GameBubbleView(
                            word: word.english,
                            color: bubbleColorMap["\(word.id)_en"] ?? .blue,
                            position: bubblePositions["\(word.id)_en"] ?? CGPoint(x: geometry.size.width * 0.25, y: geometry.size.height * 0.7),
                            bubbleId: "\(word.id)_en",
                            size: bubbleSizes["\(word.id)_en"] ?? 150,
                            isSelected: selectedBubbleId == "\(word.id)_en"
                        ) {
                            handleBubbleTap(id: "\(word.id)_en")
                        }
                    }
                    
                    // 中文气泡
                    if !matchedPairs.contains("\(word.id)_cn") {
                        GameBubbleView(
                            word: word.chinese,
                            color: bubbleColorMap["\(word.id)_cn"] ?? .green,
                            position: bubblePositions["\(word.id)_cn"] ?? CGPoint(x: geometry.size.width * 0.75, y: geometry.size.height * 0.7),
                            bubbleId: "\(word.id)_cn",
                            size: bubbleSizes["\(word.id)_cn"] ?? 150,
                            isSelected: selectedBubbleId == "\(word.id)_cn"
                        ) {
                            handleBubbleTap(id: "\(word.id)_cn")
                        }
                    }
                }
                
                // 爆炸粒子效果
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .opacity(particle.opacity)
                        .position(particle.position)
                }
                
                // 游戏结束显示
                if isGameOver {
                    ZStack {
                        // 半透明黑色背景
//                        Color.black.opacity(0.5)
//                            .ignoresSafeArea()
//                        
                        VStack(spacing: 50) {
                            Spacer()
                            
                            HStack(spacing: 50) {
                                Button {
                                    presentationMode.wrappedValue.dismiss()
                                } label: {
                                    Text("返回主菜单")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                Button {
                                    resetGame()
                                } label: {
                                    Text("继续游戏")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                }
                            }
                            
//                            Spacer()
                        }
                    }
                    .padding(50)
                }
            }
        }
        .onAppear {
            loadRandomWords()
            initializeBubblePositions()
            initializeBubbleColors()
            startAnimation()
            setupAudioPlayer()
        }
        .onDisappear {
            stopAnimation()
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func startAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            updateBubblePositions()
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func updateBubblePositions() {
        let screenBounds = UIScreen.main.bounds
        let margin: CGFloat = 50
        let dampingFactor: CGFloat = 0.95
        
        for word in currentWords {
            let enKey = "\(word.id)_en"
            let cnKey = "\(word.id)_cn"
            
            updateBubble(key: enKey, screenBounds: screenBounds, margin: margin, dampingFactor: dampingFactor)
            updateBubble(key: cnKey, screenBounds: screenBounds, margin: margin, dampingFactor: dampingFactor)
        }
    }
    
    private func updateBubble(key: String, screenBounds: CGRect, margin: CGFloat, dampingFactor: CGFloat) {
        guard var position = bubblePositions[key],
              var velocity = bubbleVelocities[key],
              !matchedPairs.contains(key) else { return }
        
        let deltaTime: CGFloat = 0.016
        
        // 更新位置
        position.x += velocity.x * deltaTime
        position.y += velocity.y * deltaTime
        
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
        
        // 添加随机扰动
        velocity.x += CGFloat.random(in: -2...2)
        velocity.y += CGFloat.random(in: -2...2)
        
        // 限制最大速度
        let maxSpeed: CGFloat = 50
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
    
    private func initializeBubblePositions() {
        bubblePositions.removeAll()
        bubbleVelocities.removeAll()
        
        let screenBounds = UIScreen.main.bounds
        let safeMargin: CGFloat = 80
        
        // 创建网格布局
        let columns: Int = 4
        let rows: Int = 3
        let cellWidth = (screenBounds.width - 2 * safeMargin) / CGFloat(columns)
        let cellHeight = (screenBounds.height - 2 * safeMargin) / CGFloat(rows)
        
        var usedPositions: Set<String> = []
        
        for word in currentWords {
            // 为英文气泡找位置
            repeat {
                let col = Int.random(in: 0..<columns)
                let row = Int.random(in: 0..<rows)
                let x = safeMargin + cellWidth * CGFloat(col) + CGFloat.random(in: 0...cellWidth/2)
                let y = safeMargin + cellHeight * CGFloat(row) + CGFloat.random(in: 0...cellHeight/2)
                let position = CGPoint(x: x, y: y)
                let positionKey = "\(Int(x)),\(Int(y))"
                
                if !usedPositions.contains(positionKey) {
                    let enKey = "\(word.id)_en"
                    bubblePositions[enKey] = position
                    bubbleVelocities[enKey] = randomInitialVelocity()
                    usedPositions.insert(positionKey)
                    break
                }
            } while true
            
            // 为中文气泡找位置
            repeat {
                let col = Int.random(in: 0..<columns)
                let row = Int.random(in: 0..<rows)
                let x = safeMargin + cellWidth * CGFloat(col) + CGFloat.random(in: 0...cellWidth/2)
                let y = safeMargin + cellHeight * CGFloat(row) + CGFloat.random(in: 0...cellHeight/2)
                let position = CGPoint(x: x, y: y)
                let positionKey = "\(Int(x)),\(Int(y))"
                
                if !usedPositions.contains(positionKey) {
                    let cnKey = "\(word.id)_cn"
                    bubblePositions[cnKey] = position
                    bubbleVelocities[cnKey] = randomInitialVelocity()
                    usedPositions.insert(positionKey)
                    break
                }
            } while true
        }
    }
    
    private func randomInitialVelocity() -> CGPoint {
        let baseSpeed: CGFloat = 30
        return CGPoint(
            x: CGFloat.random(in: -baseSpeed...baseSpeed),
            y: CGFloat.random(in: -baseSpeed...baseSpeed)
        )
    }
    
    private func loadRandomWords() {
        // 从URL加载数据
        guard let url = URL(string: "https://www.myjsons.com/v/46253769") else { 
            loadLocalWords()
            return 
        }
        
        // 创建带超时的URLRequest
        var request = URLRequest(url: url)
        request.timeoutInterval = 1.0 // 1秒超时
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // 如果有错误或者响应状态码不是200，使用本地数据
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                self.loadLocalWords()
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let data = data,
                  let words = try? JSONDecoder().decode([Word].self, from: data) else {
                print("Invalid response or data, using local data")
                self.loadLocalWords()
                return
            }
            
            DispatchQueue.main.async {
                // 随机选择3个单词
                let shuffledWords = words.shuffled()
                currentWords = Array(shuffledWords.prefix(3))
                // 初始化新的气泡位置和颜色
                initializeBubblePositions()
                initializeBubbleColors()
            }
        }
        task.resume()
    }
    
    private func loadLocalWords() {
        DispatchQueue.main.async {
            if let url = Bundle.main.url(forResource: "PhraseGamejson", withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let words = try? JSONDecoder().decode([Word].self, from: data) {
                // 随机选择3个单词
                let shuffledWords = words.shuffled()
                self.currentWords = Array(shuffledWords.prefix(3))
                // 初始化新的气泡位置和颜色
                self.initializeBubblePositions()
                self.initializeBubbleColors()
            } else {
                print("Error loading local words data")
            }
        }
    }
    
    private func handleBubbleTap(id: String) {
        // 如果点击的是英语气泡，播放发音
        if id.hasSuffix("_en") {
            let wordId = String(id.split(separator: "_")[0])
            handleEnglishBubbleTap(wordId: wordId)
        }
        
        if selectedBubbleId == id {
            // 如果点击已选中的气泡，取消选择
            selectedBubbleId = nil
            return
        }
        
        if let currentSelectedId = selectedBubbleId {
            // 检查匹配
            if checkMatch(firstId: currentSelectedId, secondId: id) {
                handleMatch(firstId: currentSelectedId, secondId: id)
            } else {
                // 如果不匹配，选择新气泡
                selectedBubbleId = id
            }
        } else {
            // 没有选中的气泡，选择当前气泡
            selectedBubbleId = id
        }
    }
    
    private func playWord(_ word: String) {
        let utterance = AVSpeechUtterance(string: word)
        // 强制使用 Samantha 语音
        utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Samantha-compact")
        utterance.rate = 0.45
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1
        
        synthesizer.speak(utterance)
    }
    
    private func createBurstEffect(at position: CGPoint) {
        for _ in 0..<15 {
            let angle = Double.random(in: 0...2 * .pi)
            let speed = CGFloat.random(in: 2...5)
            let velocity = CGPoint(
                x: CGFloat(cos(angle)) * speed,
                y: CGFloat(sin(angle)) * speed
            )
            let particle = BurstParticle(
                position: position,
                velocity: velocity,
                color: bubbleColors.randomElement()!,
                size: CGFloat.random(in: 3...8),
                opacity: 1.0,
                scale: 1.0,
                rotation: Double.random(in: 0...360)
            )
            particles.append(particle)
        }
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            for i in (0..<particles.count).reversed() {
                var particle = particles[i]
                particle.position.x += particle.velocity.x
                particle.position.y += particle.velocity.y
                particle.opacity -= 0.02
                particle.rotation += 5
                particle.scale = max(0, particle.scale - 0.01)
                
                if particle.opacity <= 0 {
                    particles.remove(at: i)
                } else {
                    particles[i] = particle
                }
            }
            
            if particles.isEmpty {
                timer?.invalidate()
                timer = nil
            }
        }
    }
    
    private func resetGame() {
        // 先停止所有动画和计时器
        stopAnimation()
        timer?.invalidate()
        timer = nil
        
        // 清理所有状态
        particles.removeAll()
        matchCount = 0
        isGameOver = false
        matchedPairs.removeAll()
        selectedBubbleId = nil
        score = 0
        currentWords.removeAll()
        bubblePositions.removeAll()
        bubbleVelocities.removeAll()
        bubbleColorMap.removeAll()
        
        // 使用 DispatchQueue.main.async 确保状态更新后再加载新数据
        DispatchQueue.main.async {
            loadRandomWords()
            startAnimation()
        }
    }
    
    private func initializeBubbleColors() {
        bubbleColorMap.removeAll()
        for word in currentWords {
            let enColor = bubbleColors.randomElement() ?? .blue
            let cnColor = bubbleColors.randomElement() ?? .blue
            bubbleColorMap["\(word.id)_en"] = enColor
            bubbleColorMap["\(word.id)_cn"] = cnColor
            
            // 初始化随机大小
            bubbleSizes["\(word.id)_en"] = CGFloat.random(in: 150...180)
            bubbleSizes["\(word.id)_cn"] = CGFloat.random(in: 120...150)
        }
    }
    
    private func setupAudioPlayer() {
        if let soundURL = Bundle.main.url(forResource: "gugugu", withExtension: "mp3") {
            do {
                matchPlayer = try AVAudioPlayer(contentsOf: soundURL)
                matchPlayer?.prepareToPlay()
            } catch {
                print("Error loading gugugu sound: \(error)")
            }
        }
    }
    
    // 添加游戏结束时的烟花效果
    private func createGameOverFireworks() {
        // 创建多组烟花
        for _ in 0...8 {  // 增加烟花数量
            let screenBounds = UIScreen.main.bounds
            let position = CGPoint(
                x: CGFloat.random(in: screenBounds.width * 0.2...screenBounds.width * 0.8),
                y: CGFloat.random(in: screenBounds.height * 0.2...screenBounds.height * 0.8)
            )
            
            // 每组烟花包含多个粒子
            for _ in 0..<40 {  // 增加粒子数量
                let angle = Double.random(in: 0...2 * .pi)
                let speed = CGFloat.random(in: 3...10)  // 降低速度范围
                let velocity = CGPoint(
                    x: cos(angle) * speed,
                    y: sin(angle) * speed
                )
                
                let particle = BurstParticle(
                    position: position,
                    velocity: velocity,
                    color: bubbleColors.randomElement()!,
                    size: CGFloat.random(in: 5...15),  // 增加粒子大小范围
                    opacity: 1.0,
                    scale: 1.0,
                    rotation: Double.random(in: 0...360)
                )
                particles.append(particle)
            }
            
            // 添加一些小型粒子作为点缀
            for _ in 0..<30 {  // 增加小粒子数量
                let angle = Double.random(in: 0...2 * .pi)
                let speed = CGFloat.random(in: 2...8)  // 降低速度范围
                let velocity = CGPoint(
                    x: cos(angle) * speed,
                    y: sin(angle) * speed
                )
                
                let particle = BurstParticle(
                    position: position,
                    velocity: velocity,
                    color: bubbleColors.randomElement()!.opacity(0.6),
                    size: CGFloat.random(in: 2...8),
                    opacity: 0.8,
                    scale: 1.0,
                    rotation: Double.random(in: 0...360)
                )
                particles.append(particle)
            }
        }
        
        // 更新粒子动画
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            for i in (0..<particles.count).reversed() {
                var particle = particles[i]
                
                // 更新位置
                particle.position.x += particle.velocity.x * 0.7  // 降低移动速度
                particle.position.y += particle.velocity.y * 0.7  // 降低移动速度
                
                // 添加较小的重力效果
                particle.velocity.y += 0.1  // 减小重力影响
                
                // 更新旋转
                particle.rotation += 3  // 降低旋转速度
                
                // 更新缩放和透明度
                particle.scale = max(0, particle.scale - 0.005)  // 减小缩放衰减速度
                particle.opacity = max(0, particle.opacity - 0.005)  // 减小透明度衰减速度
                
                if particle.opacity <= 0 {
                    particles.remove(at: i)
                } else {
                    particles[i] = particle
                }
            }
            
            if particles.isEmpty {
                timer?.invalidate()
                timer = nil
            }
        }
    }
    
    // 检查匹配
    private func checkMatch(firstId: String, secondId: String) -> Bool {
        let firstWordId = firstId.replacingOccurrences(of: "_en", with: "")
                                .replacingOccurrences(of: "_cn", with: "")
        let secondWordId = secondId.replacingOccurrences(of: "_en", with: "")
                                 .replacingOccurrences(of: "_cn", with: "")
        
        return firstWordId == secondWordId &&
               ((firstId.hasSuffix("_en") && secondId.hasSuffix("_cn")) ||
                (firstId.hasSuffix("_cn") && secondId.hasSuffix("_en")))
    }
    
    // 处理匹配成功
    private func handleMatch(firstId: String, secondId: String) {
        // 播放配对成功音效
        matchPlayer?.currentTime = 0
        matchPlayer?.play()
        
        // 获取两个气泡的位置并创建破裂效果
        if let pos1 = bubblePositions[firstId],
           let pos2 = bubblePositions[secondId] {
            createBurstEffect(at: pos1)
            createBurstEffect(at: pos2)
        }
        
        // 更新匹配状态
        matchedPairs.insert(firstId)
        matchedPairs.insert(secondId)
        selectedBubbleId = nil
        matchCount += 1
        
        // 增加分数
        score += 20
        
        // 检查游戏是否结束
        if matchCount >= 3 {
            isGameOver = true
            createGameOverFireworks()
        }
    }
    
    // 处理英文气泡点击
    private func handleEnglishBubbleTap(wordId: String) {
        if let word = currentWords.first(where: { "\($0.id)" == wordId }) {
            // 移除括号及其内容
            var cleanWord = word.english
            // 移除英文括号及其内容
            cleanWord = cleanWord.replacingOccurrences(of: "\\([^)]*\\)", with: "", options: .regularExpression)
            // 移除中文括号及其内容
            cleanWord = cleanWord.replacingOccurrences(of: "（[^）]*）", with: "", options: .regularExpression)
            // 移除音标
            cleanWord = cleanWord.replacingOccurrences(of: "/[^/]+/", with: "", options: .regularExpression)
            // 移除多余的空格
            cleanWord = cleanWord.trimmingCharacters(in: .whitespaces)
            
            playWord(cleanWord)
        }
    }
}

#Preview {
    PhraseGameView()
} 
