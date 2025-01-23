//import SwiftUI
//
//// 卡片数据模型
//struct Card: Identifiable, Equatable {
//    let id = UUID()
//    let content: String
//    let pairId: Int
//    var isFaceUp = false
//    var isMatched = false
//}
//
//struct MemoryView: View {
//    @State private var cards: [Card] = []
//    @State private var selectedCard: Card?
//    @State private var isAnimating = false
//    
//    // 示例词对
//    let wordPairs = [
//        (chinese: "苹果", english: "apple"),
//        (chinese: "香蕉", english: "banana"),
//        (chinese: "橙子", english: "orange"),
//        (chinese: "草莓", english: "strawberry"),
//        (chinese: "葡萄", english: "grape"),
//        (chinese: "西瓜", english: "watermelon")
//    ]
//    
//    var body: some View {
//        VStack {
//            Text("记忆配对游戏")
//                .font(.title)
//                .padding()
//            
//            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
//                ForEach(cards) { card in
//                    CardView(card: card)
//                        .frame(height: 150)
//                        .onTapGesture {
//                            withAnimation(.easeInOut(duration: 0.5)) {
//                                flipCard(card)
//                            }
//                        }
//                }
//            }
//            .padding()
//        }
//        .onAppear {
//            setupGame()
//        }
//    }
//    
//    private func setupGame() {
//        var newCards: [Card] = []
//        for (index, pair) in wordPairs.enumerated() {
//            newCards.append(Card(content: pair.chinese, pairId: index))
//            newCards.append(Card(content: pair.english, pairId: index))
//        }
//        cards = newCards.shuffled()
//    }
//    
//    private func flipCard(_ card: Card) {
//        guard !isAnimating else { return }
//        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }
//        guard !cards[index].isMatched else { return }  // 已匹配的卡片不能再次翻转
//        
//        isAnimating = true
//        
//        if let selected = selectedCard {
//            // 第二张卡被选中
//            cards[index].isFaceUp = true
//            
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                let selectedIndex = cards.firstIndex(where: { $0.id == selected.id })!
//                
//                if cards[index].pairId == cards[selectedIndex].pairId {
//                    // 匹配成功
//                    cards[index].isMatched = true
//                    cards[selectedIndex].isMatched = true
//                } else {
//                    // 匹配失败，翻回去
//                    cards[index].isFaceUp = false
//                    cards[selectedIndex].isFaceUp = false
//                }
//                
//                selectedCard = nil
//                isAnimating = false
//            }
//        } else {
//            // 第一张卡被选中
//            cards[index].isFaceUp = true
//            selectedCard = cards[index]
//            isAnimating = false
//        }
//    }
//}
//
//struct CardView: View {
//    let card: Card
//    
//    var body: some View {
//        ZStack {
//            if card.isMatched {
//                Text("🐣")
//                    .font(.system(size: 80))
//            } else {
//                ZStack {
//                    // 背面（鸡蛋）
//                    Text("🥚")
//                        .font(.system(size: 80))
//                        .opacity(card.isFaceUp ? 0 : 1)
//                    
//                    // 正面（文字）
//                    if card.isFaceUp {
//                        Text(card.content)
//                            .font(.system(size: 30))
//                            .padding(8)
//                            .background(
//                                RoundedRectangle(cornerRadius: 8)
//                                    .fill(Color.white)
//                                    .shadow(radius: 1)
//                            )
//                    }
//                }
//                .rotation3DEffect(
//                    .degrees(card.isFaceUp ? 180 : 0),
//                    axis: (x: 0.0, y: 1.0, z: 0.0)
//                )
//            }
//        }
//    }
//}
//
//#Preview {
//    MemoryView()
//} 
