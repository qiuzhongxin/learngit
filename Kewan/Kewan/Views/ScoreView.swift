//
//  ScoreView.swift
//  Kewan
//
//  Created by Zhongxin qiu on 2024/11/30.
//

import SwiftUI
import CoreData

struct ScoreView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var userVM: UserViewModel
    @State private var expandedDates: Set<Date> = []
    @State private var refreshID = UUID()
    
    // 使用 @FetchRequest 替代直接获取
    @FetchRequest private var gameScores: FetchedResults<GameScore>
    @FetchRequest private var learnedWords: FetchedResults<LearnedWord>
    
    init(userVM: UserViewModel) {
        self.userVM = userVM
        
        // 初始化 FetchRequest
        let gameScoresPredicate = NSPredicate(format: "userId == %@", userVM.userId as CVarArg)
        let learnedWordsPredicate = NSPredicate(format: "userId == %@", userVM.userId as CVarArg)
        
        _gameScores = FetchRequest(
            entity: GameScore.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \GameScore.date, ascending: false)],
            predicate: gameScoresPredicate
        )
        
        _learnedWords = FetchRequest(
            entity: LearnedWord.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \LearnedWord.learningDate, ascending: false)],
            predicate: learnedWordsPredicate
        )
    }
    
    // 分组展示的学习记录
    private var groupedWords: [(date: Date, words: [LearnedWord], isExpanded: Bool)] {
        let grouped = Dictionary(grouping: Array(learnedWords)) { word in
            Calendar.current.startOfDay(for: word.learningDate)
        }
        let sortedGroups = grouped.map { (date: $0.key, words: $0.value, isExpanded: false) }
        return sortedGroups.sorted { $0.date > $1.date }
    }
    
    private var lastSevenDays: [Date] {
        (0..<7).map { days in
            Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                // 每周得分环形图
                Section {
                    WeeklyScoreRingsView(scores: Array(gameScores))
                        .frame(height: 500)
                        .listRowInsets(EdgeInsets())
                        .background(Color.black.opacity(0.03))
                        .id(refreshID)
                }
                .listRowBackground(Color.clear)
                
                // 总分数统计
                Section(header: Text("游戏分数统计")) {
                    let totalScore = Double(gameScores.reduce(0) { $0 + Int($1.score) }) / 10.0
                    let easyScores = gameScores.filter { $0.level == 0 }
                    let hardScores = gameScores.filter { $0.level == 1 }
                    
                    let easyTotal = Double(easyScores.reduce(0) { $0 + Int($1.score) }) / 10.0
                    let hardTotal = Double(hardScores.reduce(0) { $0 + Int($1.score) }) / 10.0
                    
                    HStack {
                        Text("总分")
                        Spacer()
                        Text("\(Int(totalScore))")
                            .foregroundColor(.orange)
                            .bold()
                    }
                    
                    HStack {
                        Text("基础单词")
                        Spacer()
                        Text("\(Int(easyTotal))")
                            .foregroundColor(.blue)
                            .bold()
                    }
                    
                    HStack {
                        Text("高级英语单词")
                        Spacer()
                        Text("\(Int(hardTotal))")
                            .foregroundColor(.purple)
                            .bold()
                    }
                }
                
                // 单词学习统计
                Section(header: Text("单词学习统计")) {
                    let totalWords = learnedWords.count
                    let totalReviews = learnedWords.reduce(0) { $0 + Int($1.reviewCount) }
                    let avgReviews = totalWords > 0 ? Double(totalReviews) / Double(totalWords) : 0
                    
                    HStack {
                        Text("已学单词")
                        Spacer()
                        Text("\(totalWords)")
                            .foregroundColor(.green)
                            .bold()
                    }
                    
                    HStack {
                        Text("复习次数")
                        Spacer()
                        Text("\(totalReviews)")
                            .foregroundColor(.blue)
                            .bold()
                    }
                    
                    HStack {
                        Text("平均复习")
                        Spacer()
                        Text(String(format: "%.1f", avgReviews))
                            .foregroundColor(.orange)
                            .bold()
                    }
                }
                
                // 按日期分组显示学习记录
                Section(header: Text("学习记录")) {
                    ForEach(groupedWords, id: \.date) { group in
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { expandedDates.contains(group.date) },
                                set: { isExpanded in
                                    if isExpanded {
                                        expandedDates.insert(group.date)
                                    } else {
                                        expandedDates.remove(group.date)
                                    }
                                }
                            )
                        ) {
                            // 单词列表
                            ForEach(group.words, id: \.id) { word in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(word.english)
                                            .font(.system(size: 16, weight: .medium))
                                        if let phonetic = word.phonetic {
                                            Text(phonetic)
                                                .font(.system(size: 14))
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        Button(action: {
                                            DictionaryService.shared.playWord(word.english)
                                            // 更新复习次数
                                            CoreDataManager.shared.updateWordReviewCount(word)
                                            // 增加游戏分数
                                            CoreDataManager.shared.saveGameScore(
                                                score: 10,
                                                level: 0,
                                                totalTime: 0,
                                                userId: userVM.userId
                                            )
                                            // 强制刷新视图
                                            refreshID = UUID()
                                        }) {
                                            Image(systemName: "speaker.wave.2")
                                                .foregroundColor(.blue)
                                        }
                                        Text("复习: \(word.reviewCount)")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                    Text(word.chinese)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                    HStack {
                                        Spacer()
                                        // 添加收藏按钮
                                        FavoriteStarsView(word: word)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        } label: {
                            HStack {
                                Text(formatDate(group.date))
                                    .font(.headline)
                                Spacer()
                                Text("\(group.words.count) 个单词")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("学习记录")
            .listStyle(InsetGroupedListStyle())
            .onAppear {
                // 视图出现时刷新数据
                refreshID = UUID()
            }
            .refreshable {
                // 下拉刷新
                refreshID = UUID()
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        
        if Calendar.current.isDateInToday(date) {
            return "今天"
        } else if Calendar.current.isDateInYesterday(date) {
            return "昨天"
        } else {
            formatter.dateFormat = "M月d日"
            return formatter.string(from: date)
        }
    }
}

// 添加收藏星级视图
struct FavoriteStarsView: View {
    let word: LearnedWord
    @StateObject private var wordStore = WordStore.shared
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { level in
                Image(systemName: level <= (wordStore.getFavoriteLevel(for: word.english)) ? "heart.fill" : "heart")
                    .foregroundColor(level <= (wordStore.getFavoriteLevel(for: word.english)) ? .red : .gray)
                    .font(.system(size: 12))
                    .onTapGesture {
                        wordStore.updateFavorite(for: word.english, level: level)
                    }
            }
        }
    }
}

#Preview {
    let context = CoreDataManager.shared.viewContext
    return ScoreView(userVM: UserViewModel())
        .environment(\.managedObjectContext, context)
}
