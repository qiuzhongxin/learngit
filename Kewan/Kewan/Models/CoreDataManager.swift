import CoreData
import CloudKit

class CoreDataManager {
    static let shared = CoreDataManager()
    
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "GameData")
        
        // 配置 CloudKit 同步
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
        
        // 只在用户登录 iCloud 时启用 CloudKit
        if FileManager.default.ubiquityIdentityToken != nil {
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.qiuzx.Kewan"
            )
            
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            
            // 启用自动同步
            do {
                try container.initializeCloudKitSchema()
            } catch {
                print("Note: CloudKit schema initialization skipped - user not signed into iCloud")
            }
        } else {
            description.cloudKitContainerOptions = nil
            print("Note: CloudKit disabled - user not signed into iCloud")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private init() {}
    
    // MARK: - Game Score Methods
    
    func saveGameScore(score: Int16, level: Int16, totalTime: TimeInterval, userId: String?) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 查找今天是否已有记录
        let request: NSFetchRequest<GameScore> = GameScore.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@ AND userId == %@ AND level == %d",
                                      today as NSDate,
                                      calendar.date(byAdding: .day, value: 1, to: today)! as NSDate,
                                      userId ?? "",
                                      level)
        
        do {
            let existingScores = try viewContext.fetch(request)
            if let existingScore = existingScores.first {
                // 如果今天已有记录，更新分数
                existingScore.score += score
                existingScore.totalTime += totalTime
            } else {
                // 如果今天没有记录，创建新记录
                let newScore = GameScore(context: viewContext)
                newScore.id = UUID()
                newScore.score = score
                newScore.level = level
                newScore.totalTime = totalTime
                newScore.date = Date()
                newScore.userId = userId
            }
            
            try viewContext.save()
        } catch {
            print("Error saving game score: \(error)")
        }
    }
    
    func fetchGameScores(userId: String?) -> [GameScore] {
        let request: NSFetchRequest<GameScore> = GameScore.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GameScore.date, ascending: false)]
        
        if let userId = userId {
            request.predicate = NSPredicate(format: "userId == %@", userId)
        }
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching game scores: \(error)")
            return []
        }
    }
    
    // MARK: - Learned Word Methods
    
    // 清理30天前的学习记录
    private func cleanupOldRecords() {
        let calendar = Calendar.current
        guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) else { return }
        
        let request: NSFetchRequest<LearnedWord> = LearnedWord.fetchRequest()
        request.predicate = NSPredicate(format: "learningDate < %@", thirtyDaysAgo as NSDate)
        
        do {
            let oldRecords = try viewContext.fetch(request)
            for record in oldRecords {
                viewContext.delete(record)
            }
            try viewContext.save()
            print("Cleaned up \(oldRecords.count) old word records")
        } catch {
            print("Error cleaning up old records: \(error)")
        }
    }
    
    func saveLearnedWord(english: String, chinese: String, phonetic: String? = nil, userId: String?) {
        // 先清理旧记录
        cleanupOldRecords()
        
        let newWord = LearnedWord(context: viewContext)
        newWord.id = UUID()
        newWord.english = english
        newWord.chinese = chinese
        newWord.phonetic = phonetic
        newWord.learningDate = Date()
        newWord.reviewCount = 1
        newWord.userId = userId
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving learned word: \(error)")
        }
    }
    
    func fetchLearnedWords(userId: String?) -> [LearnedWord] {
        // 只获取30天内的记录
        let calendar = Calendar.current
        guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) else { return [] }
        
        let request: NSFetchRequest<LearnedWord> = LearnedWord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \LearnedWord.learningDate, ascending: false)]
        
        var predicates: [NSPredicate] = [
            NSPredicate(format: "learningDate >= %@", thirtyDaysAgo as NSDate)
        ]
        
        if let userId = userId {
            predicates.append(NSPredicate(format: "userId == %@", userId))
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching learned words: \(error)")
            return []
        }
    }
    
    func updateWordReviewCount(_ word: LearnedWord) {
        // 先清理旧记录
        cleanupOldRecords()
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 查找今天是否已有这个单词的记录
        let request: NSFetchRequest<LearnedWord> = LearnedWord.fetchRequest()
        request.predicate = NSPredicate(
            format: "english == %@ AND userId == %@ AND learningDate >= %@ AND learningDate < %@",
            word.english,
            word.userId ?? "",
            today as NSDate,
            calendar.date(byAdding: .day, value: 1, to: today)! as NSDate
        )
        
        do {
            let todayWords = try viewContext.fetch(request)
            
            if let existingWord = todayWords.first {
                // 如果今天已有记录，增加复习次数
                existingWord.reviewCount += 1
                print("Updated review count for today's word: \(word.english)")
            } else {
                // 如果今天没有记录，创建新记录，保留音标数据
                let newWord = LearnedWord(context: viewContext)
                newWord.id = UUID()
                newWord.english = word.english
                newWord.chinese = word.chinese
                newWord.phonetic = word.phonetic  // 保留原有音标
                newWord.learningDate = Date()
                newWord.reviewCount = 1
                newWord.userId = word.userId
                print("Created new record for today's word: \(word.english)")
            }
            
            try viewContext.save()
        } catch {
            print("Error updating word review count: \(error)")
        }
    }
    
    func deleteAllUserData(userId: String) {
        let context = viewContext
        
        // 删除用户的游戏分数记录
        let scoresFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "GameScore")
        scoresFetch.predicate = NSPredicate(format: "userId == %@", userId)
        
        // 删除用户的学习记录
        let wordsFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "LearnedWord")
        wordsFetch.predicate = NSPredicate(format: "userId == %@", userId)
        
        do {
            // 删除分数记录
            let scoreBatchDelete = NSBatchDeleteRequest(fetchRequest: scoresFetch)
            try context.execute(scoreBatchDelete)
            
            // 删除学习记录
            let wordsBatchDelete = NSBatchDeleteRequest(fetchRequest: wordsFetch)
            try context.execute(wordsBatchDelete)
            
            // 保存更改
            try context.save()
        } catch {
            print("Error deleting user data: \(error)")
        }
    }
}
