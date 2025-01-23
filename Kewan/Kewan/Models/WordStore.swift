import Foundation
import CloudKit
import CoreData

class WordStore: ObservableObject {
    static let shared = WordStore()
    private let container: NSPersistentContainer
    private let favoritesKey = "wordFavorites"
    
    @Published var favorites: [String: Int] = [:]
    
    private init() {
        // 初始化本地数据
        if let savedFavorites = UserDefaults.standard.dictionary(forKey: favoritesKey) as? [String: Int] {
            favorites = savedFavorites
        }
        
        // 设置本地存储
        container = NSPersistentContainer(name: "WordFavorites")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Error loading persistent stores: \(error)")
                return
            }
            
            self.container.viewContext.automaticallyMergesChangesFromParent = true
        }
        
        // 加载本地存储的数据
        loadFromLocalStorage()
    }
    
    // 统一使用英文单词作为标识符
    func updateFavorite(for word: String, level: Int) {
        print("更新收藏: \(word) -> \(level)星")
        if favorites[word] == level {
            favorites.removeValue(forKey: word)
            print("取消收藏: \(word)")
        } else {
            favorites[word] = level
            print("设置收藏: \(word) -> \(level)星")
        }
        
        // 保存到本地
        UserDefaults.standard.set(favorites, forKey: favoritesKey)
        saveToLocalStorage()
        
        // 通知数据更新
        objectWillChange.send()
    }
    
    // 获取单词的收藏等级
    func getFavoriteLevel(for word: String) -> Int {
        return favorites[word] ?? 0
    }
    
    private func saveToLocalStorage() {
        let context = container.viewContext
        
        // 创建或更新记录
        let fetchRequest = NSFetchRequest<WordFavorite>(entityName: "WordFavorite")
        
        do {
            let existingRecords = try context.fetch(fetchRequest)
            let record = existingRecords.first ?? WordFavorite(context: context)
            record.favoritesData = try? JSONEncoder().encode(favorites)
            
            try context.save()
            print("收藏数据保存成功，当前收藏数: \(favorites.count)")
        } catch {
            print("Error saving to local storage: \(error)")
        }
    }
    
    private func loadFromLocalStorage() {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<WordFavorite>(entityName: "WordFavorite")
        
        do {
            let records = try context.fetch(fetchRequest)
            if let record = records.first,
               let data = record.favoritesData,
               let savedFavorites = try? JSONDecoder().decode([String: Int].self, from: data) {
                self.favorites = savedFavorites
                UserDefaults.standard.set(self.favorites, forKey: self.favoritesKey)
                print("从本地存储加载收藏数据成功，收藏数: \(favorites.count)")
            }
        } catch {
            print("Error loading from local storage: \(error)")
        }
    }
} 