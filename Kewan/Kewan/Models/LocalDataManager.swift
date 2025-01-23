import Foundation

class LocalDataManager {
    static let shared = LocalDataManager()
    private var localWordsMap: [Int: [MyModel]] = [:]
    
    private init() {
        loadLocalData()
    }
    
    private func loadLocalData() {
        // 加载 Level 1 数据
        if let url = Bundle.main.url(forResource: "MyJsons", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            do {
                localWordsMap[1] = try JSONDecoder().decode([MyModel].self, from: data)
                print("✅ Level 1 数据加载成功: \(localWordsMap[1]?.count ?? 0) 个单词")
            } catch {
                print("❌ Level 1 数据解码错误: \(error)")
            }
        } else {
            print("❌ Level 1 数据文件未找到")
        }
        
        // 加载 Level 2 数据
        if let url = Bundle.main.url(forResource: "level2jsons", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            do {
                localWordsMap[2] = try JSONDecoder().decode([MyModel].self, from: data)
                print("✅ Level 2 数据加载成功: \(localWordsMap[2]?.count ?? 0) 个单词")
            } catch {
                print("❌ Level 2 数据解码错误: \(error)")
            }
        } else {
            print("❌ Level 2 数据文件未找到")
        }
        
        // 加载 Level 3 数据
        if let url = Bundle.main.url(forResource: "level3jsons", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            do {
                localWordsMap[3] = try JSONDecoder().decode([MyModel].self, from: data)
                print("✅ Level 3 数据加载成功: \(localWordsMap[3]?.count ?? 0) 个单词")
            } catch {
                print("❌ Level 3 数据解码错误: \(error)")
            }
        } else {
            print("❌ Level 3 数据文件未找到")
        }
    }
    
    // 获取指定关卡的所有单词
    func getAllWords(forLevel level: Int) -> [MyModel] {
        guard let words = localWordsMap[level], !words.isEmpty else {
            print("⚠️ Level \(level) 没有本地数据可用")
            return localWordsMap[1] ?? []
        }
        return words
    }
    
    func getRandomFiveWords(forLevel level: Int = 1) -> [MyModel] {
        guard let words = localWordsMap[level], !words.isEmpty else {
            print("⚠️ Level \(level) 没有本地数据可用")
            if let fallbackWords = localWordsMap[1], !fallbackWords.isEmpty {
                print("⚠️ 使用 Level 1 数据作为后备")
                return Array(fallbackWords.shuffled().prefix(5))
            }
            print("❌ 没有可用的本地数据")
            return []
        }
        
        print("✅ 从 Level \(level) 本地数据中选择单词，可用单词数: \(words.count)")
        var availableWords = words
        var result: [MyModel] = []
        
        for _ in 0..<min(5, availableWords.count) {
            let randomIndex = Int.random(in: 0..<availableWords.count)
            result.append(availableWords.remove(at: randomIndex))
        }
        
        return result
    }
} 