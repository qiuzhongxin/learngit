import AVFoundation

class AudioViewModel: ObservableObject {
    private var popPlayer: AVAudioPlayer?    // 气泡破裂音效
    private var guguPlayer: AVAudioPlayer?   // 配对成功音效
    private var goodPlayer: AVAudioPlayer?   // 完成音效
    private let synthesizer = AVSpeechSynthesizer()
    private let audioSession = AVAudioSession.sharedInstance()
    
    init() {
        setupAudio()
        // 只设置混音类别，不激活会话，不降低其他音频音量
        do {
            try audioSession.setCategory(.playback, mode: .default, options: .mixWithOthers)
        } catch {
            print("Error setting audio session category: \(error.localizedDescription)")
        }
    }
    
    // 初始化音频
    private func setupAudio() {
        // 设置点击音效
        if let popURL = Bundle.main.url(forResource: "gugu", withExtension: "mp3") {
            do {
                popPlayer = try AVAudioPlayer(contentsOf: popURL)
                popPlayer?.prepareToPlay()
            } catch {
                print("Error loading pop sound: \(error.localizedDescription)")
            }
        }
        
        // 设置配对成功音效
        if let guguURL = Bundle.main.url(forResource: "gugugu", withExtension: "mp3") {
            do {
                guguPlayer = try AVAudioPlayer(contentsOf: guguURL)
                guguPlayer?.prepareToPlay()
            } catch {
                print("Error loading gugu sound: \(error.localizedDescription)")
            }
        }
        
        // 设置完成音效
        if let goodURL = Bundle.main.url(forResource: "good", withExtension: "mp3") {
            do {
                goodPlayer = try AVAudioPlayer(contentsOf: goodURL)
                goodPlayer?.prepareToPlay()
            } catch {
                print("Error loading good sound: \(error.localizedDescription)")
            }
        }
    }
    
    // 播放英语单词
    func playEnglishWord(_ word: String, forceUseSamantha: Bool = false) {
        // 停止当前播放
        synthesizer.stopSpeaking(at: .immediate)
        
        // 移除括号及其内容
        var cleanWord = word
        // 移除英文括号及其内容
        cleanWord = cleanWord.replacingOccurrences(of: "\\([^)]*\\)", with: "", options: .regularExpression)
        // 移除中文括号及其内容
        cleanWord = cleanWord.replacingOccurrences(of: "（[^）]*）", with: "", options: .regularExpression)
        // 移除音标
        cleanWord = cleanWord.replacingOccurrences(of: "/[^/]+/", with: "", options: .regularExpression)
        // 移除多余的空格
        cleanWord = cleanWord.trimmingCharacters(in: .whitespaces)
        
        let utterance = AVSpeechUtterance(string: cleanWord)
        
        // 如果是短语，强制使用Samantha语音
        if forceUseSamantha {
            utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Samantha-compact")
        } else {
            // 获取用户选择的语音
            let selectedVoiceId = AppSettings.shared.selectedVoice
            print("使用语音ID: \(selectedVoiceId)")
            
            if let voice = AVSpeechSynthesisVoice(identifier: selectedVoiceId) {
                utterance.voice = voice
                print("成功设置语音: \(voice.identifier)")
            } else {
                print("无法创建语音，使用默认语音")
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            }
        }
        
        utterance.rate = 0.45
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1
        
        synthesizer.speak(utterance)
    }
    
    // 播放点击音效
    func playPopSound() {
        popPlayer?.volume = 1.0
        popPlayer?.currentTime = 0
        popPlayer?.play()
    }
    
    // 播放配对成功音效
    func playMatchSound() {
        guguPlayer?.volume = 1.0
        guguPlayer?.currentTime = 0
        guguPlayer?.play()
    }
    
    // 播放完成音效
    func playGoodSound() {
        goodPlayer?.volume = 0.8  // 保持正常音量
        goodPlayer?.currentTime = 0
        goodPlayer?.play()
    }
    
    // 播放得分音效
    func playScoreSound() {
        // 可以选择以下音效之一：
        // 1104: 清脆的点击音
        // 1057: 轻快的提示音
        // 1075: 清晰的提示音
        // 1070: 柔和的提示音
        // 1013: 明快的提示音
        let systemSoundID: SystemSoundID = 1001  // 使用清脆的点击音
        AudioServicesPlaySystemSound(systemSoundID)
    }
    
    // 清理音频会话
    func cleanup() {
        synthesizer.stopSpeaking(at: .immediate)
        popPlayer?.stop()
        guguPlayer?.stop()
        goodPlayer?.stop()
    }
    
    deinit {
        cleanup()
    }
}
