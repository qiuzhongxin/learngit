import SwiftUI
import Foundation

class MyRequestData: ObservableObject {
    @Published var funEnglishModeList: [MyModel] = []
    private let level: Int
    
    init(level: Int = 1) {
        self.level = level
        loadLocalData()
    }
    
    func requestData() {
        loadLocalData()
    }
    
    private func loadLocalData() {
        print("📚 加载 Level \(level) 本地数据...")
        DispatchQueue.main.async { [self] in
            self.funEnglishModeList = LocalDataManager.shared.getAllWords(forLevel: self.level)
            print("✅ 已加载 Level \(self.level) 本地数据，单词数量: \(self.funEnglishModeList.count)")
        }
    }
    
    func getRandomFiveWords() -> [MyModel] {
        print("当前单词列表数量: \(funEnglishModeList.count)")
        let words = Array(funEnglishModeList.shuffled().prefix(5))
        print("已选择 5 个随机单词")
        return words
    }
}
