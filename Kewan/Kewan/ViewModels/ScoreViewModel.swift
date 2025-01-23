import SwiftUI
import CoreData

class ScoreViewModel: ObservableObject {
    @Published var groupedScores: [String: [Score]] = [:]
    private let context = CoreDataManager.shared.viewContext
    
    struct Score: Identifiable {
        let id = UUID()
        let date: Date
        let score: Double
        let words: [String]
        let level: Int16
    }
    
    func loadScores() {
        let fetchRequest: NSFetchRequest<GameScore> = GameScore.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \GameScore.date, ascending: false)]
        
        do {
            let scores = try context.fetch(fetchRequest)
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "zh_CN")
            
            var tempGroupedScores: [String: [Score]] = [:]
            
            for score in scores {
                let date = score.date
                let dateString = formatDate(date)
                
                // 获取与这个分数相关的单词
                let wordsFetch: NSFetchRequest<LearnedWord> = LearnedWord.fetchRequest()
                wordsFetch.predicate = NSPredicate(format: "learningDate >= %@ AND learningDate < %@",
                                                 Calendar.current.startOfDay(for: date) as NSDate,
                                                 Calendar.current.startOfDay(for: date.addingTimeInterval(86400)) as NSDate)
                let words = try context.fetch(wordsFetch)
                let wordStrings = words.map { $0.english }
                
                let scoreEntry = Score(
                    date: date,
                    score: Double(score.score) / 10.0,
                    words: wordStrings,
                    level: score.level
                )
                
                if tempGroupedScores[dateString] == nil {
                    tempGroupedScores[dateString] = []
                }
                tempGroupedScores[dateString]?.append(scoreEntry)
            }
            
            DispatchQueue.main.async {
                self.groupedScores = tempGroupedScores
            }
        } catch {
            print("Error fetching scores: \(error)")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "今天"
        } else if Calendar.current.isDateInYesterday(date) {
            return "昨天"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "M月d日"
            return formatter.string(from: date)
        }
    }
} 