import SwiftUI

// 定义 MatchedPair 结构体
struct MatchedPair: Equatable {
    let firstId: String
    let secondId: String
}

class GameViewModel: ObservableObject {
    @Published var currentWords: [MyModel] = []
    @Published var selectedBubbleId: String?
    @Published var matchedPair: MatchedPair?
    @Published var isShowingCompletionAnimation = false
    @Published var showContinueOptions = false
    @Published var isListeningMode = false
    @Published var isGameCompleted = false
    @Published var currentLevel = 1
    @Published var score: Double = 0
    @Published var isHardMode = false
    
    private var savedWords: [MyModel] = []
    private var allWords: [MyModel] = []
    private let coreDataManager = CoreDataManager.shared
    private var gameStartTime: Date?
    private var currentRoundScore: Double = 0
    private var currentUserId: String?
    
    init(userId: String? = nil) {
        self.currentUserId = userId
    }
    
    func setUserId(_ userId: String?) {
        self.currentUserId = userId
        print("设置用户ID: \(userId ?? "nil")")
    }
    
    // 开始新游戏
    func startNewGame(level: Int) {
        currentLevel = level
        selectedBubbleId = nil
        matchedPair = nil
        isShowingCompletionAnimation = false
        showContinueOptions = false
        isGameCompleted = false
        score = 0
        currentRoundScore = 0
        gameStartTime = Date()
        
        if !isListeningMode {
            if currentWords.count > 5 {
                print("使用完整词库初始化游戏")
                allWords = currentWords
                let randomWords = allWords.shuffled().prefix(5)
                currentWords = Array(randomWords)
                savedWords = currentWords.map { $0 }
                print("选择的单词: \(currentWords.map { $0.english })")
            } else {
                print("使用当前单词继续游戏")
                savedWords = currentWords.map { $0 }
            }
        } else {
            print("进入听力模式")
            currentWords = savedWords.map { $0 }
            print("听力模式使用单词: \(currentWords.map { $0.english })")
        }
    }
    
    // 处理匹配
    private func handleMatch(firstId: String, secondId: String) {
        let wordId = firstId.replacingOccurrences(of: "_en", with: "")
                           .replacingOccurrences(of: "_cn", with: "")
        
        // 根据不同模式和关卡给予不同分数
        let points: Double
        if isHardMode {
            // "我超难的"模式
            points = !isListeningMode ? 10 : 15  // 第一轮10分，听力15分
        } else {
            // "气泡英语"模式
            points = !isListeningMode ? 5 : 7    // 第一轮5分，听力7分
        }
        
        // 累积分数但不立即显示
        currentRoundScore += points
        
        matchedPair = MatchedPair(firstId: firstId, secondId: secondId)
        
        // 保存匹配的单词到学习记录
        if let word = currentWords.first(where: { $0.id == wordId }) {
            saveLearnedWord(word)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.currentWords.removeAll(where: { $0.id == wordId })
            self.selectedBubbleId = nil
            self.matchedPair = nil
            
            // 检查是否完成所有匹配
            if self.currentWords.isEmpty {
                if !self.isListeningMode {
                    // 第一轮完成，显示动画和选项
                    self.isShowingCompletionAnimation = true
                    // 在这里更新显示的分数
                    self.score = self.currentRoundScore
                    self.saveGameScore()  // 保存识字部分分数
                    
                    // 2.5秒后显示选项按钮
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        self.showContinueOptions = true
                    }
                } else {
                    // 听力模式完成，显示最终完成动画
                    self.isGameCompleted = true
                    self.isShowingCompletionAnimation = true
                    // 在这里更新显示的分数
                    self.score = self.currentRoundScore
                    self.saveGameScore()  // 保存听力部分分数
                    
                    // 2.5秒后显示选项按钮
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        self.showContinueOptions = true
                    }
                }
            }
        }
    }
    
    // 保存游戏分数
    private func saveGameScore() {
        guard let startTime = gameStartTime else { return }
        let totalTime = Date().timeIntervalSince(startTime)
        
        // 保存当前轮次的分数
        let roundedScore = Int(currentRoundScore * 10)  // 将分数乘以10转为整数存储
        print("保存游戏分数: \(roundedScore) 分, 模式: \(isHardMode ? "困难" : "简单"), 阶段: \(isListeningMode ? "听力" : "识字"), 用户ID: \(currentUserId ?? "nil")")
        
        // 检查是否有有效的用户ID
        if currentUserId == nil {
            print("警告: 没有有效的用户ID，分数可能无法正确保存")
        }
        
        coreDataManager.saveGameScore(
            score: Int16(roundedScore),
            level: Int16(isHardMode ? 1 : 0),
            totalTime: totalTime,
            userId: currentUserId
        )
        
        // 保存后重置当前轮次分数
        currentRoundScore = 0
    }
    
    // 保存学习的单词
    private func saveLearnedWord(_ word: MyModel) {
        // 检查单词是否已存在
        let existingWords = coreDataManager.fetchLearnedWords(userId: currentUserId)
        if let existingWord = existingWords.first(where: { $0.english == word.english }) {
            // 如果单词已存在，增加复习次数
            coreDataManager.updateWordReviewCount(existingWord)
        } else {
            // 如果是新单词，保存到 CoreData，包括音标
            coreDataManager.saveLearnedWord(
                english: word.english,
                chinese: word.chinese,
                phonetic: word.phonetic,  // 传入音标数据
                userId: currentUserId
            )
        }
    }
    
    // 继续到听力模式
    func continueToListeningMode() {
        isShowingCompletionAnimation = false
        showContinueOptions = false
        isListeningMode = true
        currentRoundScore = 0  // 重置当前轮次分数
        gameStartTime = Date()  // 重置开始时间
        startListeningMode()
    }
    
    // 开始听力模式
    private func startListeningMode() {
        print("开始听力模式")
        isListeningMode = true
        currentWords = savedWords
        print("听力模式单词数量: \(currentWords.count)")
    }
    
    // 清理资源
    func cleanupAll() {
        let savedUserId = currentUserId  // 保存用户ID
        reset()
        currentUserId = savedUserId  // 恢复用户ID
        allWords.removeAll()
    }
    
    // 重置状态
    func reset() {
        let savedUserId = currentUserId  // 保存用户ID
        currentLevel = 1
        selectedBubbleId = nil
        matchedPair = nil
        isShowingCompletionAnimation = false
        isListeningMode = false
        showContinueOptions = false
        isGameCompleted = false
        score = 0
        currentRoundScore = 0
        currentWords.removeAll()
        savedWords.removeAll()
        currentUserId = savedUserId  // 恢复用户ID
    }
    
    // 检查气泡是否被选中
    func isBubbleSelected(_ bubbleId: String) -> Bool {
        return selectedBubbleId == bubbleId
    }
    
    // 处理气泡选择
    func selectBubble(id: String) {
        if let currentSelectedId = selectedBubbleId {
            if currentSelectedId == id {
                selectedBubbleId = nil
            } else {
                if checkMatch(firstId: currentSelectedId, secondId: id) {
                    handleMatch(firstId: currentSelectedId, secondId: id)
                } else {
                    selectedBubbleId = id
                }
            }
        } else {
            selectedBubbleId = id
        }
    }
    
    // 检查是否匹配
    private func checkMatch(firstId: String, secondId: String) -> Bool {
        let firstWordId = firstId.replacingOccurrences(of: "_en", with: "")
                                .replacingOccurrences(of: "_cn", with: "")
        let secondWordId = secondId.replacingOccurrences(of: "_en", with: "")
                                 .replacingOccurrences(of: "_cn", with: "")
        
        return firstWordId == secondWordId &&
               ((firstId.hasSuffix("_en") && secondId.hasSuffix("_cn")) ||
                (firstId.hasSuffix("_cn") && secondId.hasSuffix("_en")))
    }
    
    // 重置分数的方法
    func resetScore() {
        score = 0
        UserDefaults.standard.set(0, forKey: "totalScore")
    }
    
    // 添加设置游戏模式的方法
    func setGameMode(isHard: Bool) {
        isHardMode = isHard
    }
}
