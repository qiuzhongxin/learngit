import Foundation
import AVFoundation

class DictionaryService {
    static let shared = DictionaryService()
    private let synthesizer = AVSpeechSynthesizer()
    
    // 获取单词音标和发音
    func fetchWordPhonetic(word: String) async throws -> String? {
        let urlString = "https://api.dictionaryapi.dev/api/v2/entries/en/\(word)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        let response = try decoder.decode([WordResponse].self, from: data)
        
        if let firstEntry = response.first,
           let firstPhonetic = firstEntry.phonetics.first(where: { !($0.text ?? "").isEmpty }) {
            return firstPhonetic.text
        }
        return nil
    }
    
    // 播放单词发音
    func playWord(_ word: String) {
        let utterance = AVSpeechUtterance(string: word)
        
        // 获取用户选择的语音
        let selectedVoiceId = AppSettings.shared.selectedVoice
        print("DictionaryService - 使用语音ID: \(selectedVoiceId)")
        
        if let voice = AVSpeechSynthesisVoice(identifier: selectedVoiceId) {
            utterance.voice = voice
            print("DictionaryService - 成功设置语音: \(voice.identifier)")
        } else {
            print("DictionaryService - 无法创建语音，使用默认语音")
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        utterance.rate = 0.4
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
}

// API 响应模型
struct WordResponse: Codable {
    let word: String
    let phonetics: [Phonetic]
}

struct Phonetic: Codable {
    let text: String?
    let audio: String?
} 
