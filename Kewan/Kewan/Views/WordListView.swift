import SwiftUI
import AVFoundation
import CoreData

struct WordListView: View {
    @StateObject private var audioVM = AudioViewModel()
    @StateObject private var wordStore = WordStore.shared
    @State private var selectedStarLevel: Int? = nil
    @Environment(\.managedObjectContext) private var viewContext
    
    // 使用 FetchRequest 获取学习记录
    @FetchRequest(
        entity: LearnedWord.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \LearnedWord.learningDate, ascending: false)]
    ) private var learnedWords: FetchedResults<LearnedWord>
    
    var filteredWords: [LearnedWord] {
        // 先获取所有收藏的单词，并按英文去重
        let favoriteWords = learnedWords.filter { word in
            wordStore.getFavoriteLevel(for: word.english) > 0
        }
        
        // 使用Dictionary的grouping来去重，保留最新的记录
        let uniqueWords = Dictionary(grouping: favoriteWords) { $0.english }
            .compactMap { $1.first }
        
        if let level = selectedStarLevel {
            // 按星级过滤
            return uniqueWords.filter { word in
                wordStore.getFavoriteLevel(for: word.english) == level
            }
        } else {
            // 显示所有收藏的单词
            return uniqueWords
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    Button(action: {
                        selectedStarLevel = nil
                    }) {
                        Text("全部收藏")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedStarLevel == nil ? Color.blue.opacity(0.2) : Color.clear)
                            .foregroundColor(selectedStarLevel == nil ? .blue : .primary)
                            .cornerRadius(16)
                    }
                    
                    ForEach(1...5, id: \.self) { level in
                        Button(action: {
                            selectedStarLevel = (selectedStarLevel == level) ? nil : level
                        }) {
                            Text("\(level)星")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedStarLevel == level ? Color.blue.opacity(0.2) : Color.clear)
                                .foregroundColor(selectedStarLevel == level ? .blue : .primary)
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(UIColor.systemBackground))
            
            if filteredWords.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text(selectedStarLevel == nil ? "暂无收藏单词" : "暂无\(selectedStarLevel!)星收藏")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredWords, id: \.id) { word in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(word.english)
                                    .font(.headline)
                                Spacer()
                                Button(action: {
                                    audioVM.playEnglishWord(word.english)
                                }) {
                                    Image(systemName: "speaker.wave.2")
                                        .foregroundColor(.blue)
                                }
                            }
                            if let phonetic = word.phonetic {
                                Text(phonetic)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Text(word.chinese)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Spacer()
                                ForEach(1...5, id: \.self) { level in
                                    Image(systemName: level <= wordStore.getFavoriteLevel(for: word.english) ? "heart.fill" : "heart")
                                        .foregroundColor(level <= wordStore.getFavoriteLevel(for: word.english) ? .red : .gray)
                                        .onTapGesture {
                                            wordStore.updateFavorite(for: word.english, level: level)
                                        }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("收藏单词")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemBackground))
    }
}

//#Preview {
//    NavigationView {
//        WordListView()
//            .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
//    }
//} 
