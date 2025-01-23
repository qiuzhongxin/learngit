import SwiftUI

// 创建一个颜色选择的存储类
class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @AppStorage("backgroundColor") var backgroundColor: String = "purple"
    @AppStorage("backgroundOpacity") var backgroundOpacity: Double = 0.5
    @AppStorage("scores") private var scoresData: Data = Data()
    @AppStorage("learnedPhrases") private var learnedPhrasesData: Data = Data()
    @AppStorage("selectedVoice") var selectedVoice: String = "com.apple.ttsbundle.Samantha-compact"
    
    // 可用的语音选项
    let voiceOptions: [(String, String)] = [
        ("Samantha (美式女声)", "com.apple.ttsbundle.Samantha-compact"),
        ("Alex (美式男声)", "com.apple.ttsbundle.Alex-compact"),
        ("Daniel (英式男声)", "com.apple.voice.compact.en-GB.Daniel"),
        ("Karen (澳式女声)", "com.apple.voice.compact.en-AU.Karen")
    ]
    
    @Published var scores: [Int] = []
    @Published var learnedPhrases: [Word] = []
    
    init() {
        if let decodedScores = try? JSONDecoder().decode([Int].self, from: scoresData) {
            scores = decodedScores
        }
        if let decodedPhrases = try? JSONDecoder().decode([Word].self, from: learnedPhrasesData) {
            learnedPhrases = decodedPhrases
        }
    }
    
    func addScore(_ score: Int) {
        scores.append(score)
        if let encodedScores = try? JSONEncoder().encode(scores) {
            scoresData = encodedScores
        }
        objectWillChange.send()
    }
    
    func addLearnedPhrase(_ phrase: Word) {
        if !learnedPhrases.contains(where: { $0.id == phrase.id }) {
            learnedPhrases.append(phrase)
            if let encodedPhrases = try? JSONEncoder().encode(learnedPhrases) {
                learnedPhrasesData = encodedPhrases
            }
            objectWillChange.send()
        }
    }
    
    // 获取实际的 Color 对象
    var color: Color {
        switch backgroundColor {
        case "green": return .green
        case "blue": return .blue
        case "yellow": return .yellow
        case "purple": return .purple
        case "red": return .red
        case "black": return .black
        case "white": return .white
        case "orange": return .orange
        case "mint": return.mint
        case "pink": return.pink
        default: return .purple
        }
    }
} 
