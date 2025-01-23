import SwiftUI

struct LevelBubbleView: View {
    let word: String
    let color: Color
    let position: CGPoint
    let bubbleId: String
    let size: CGFloat
    @ObservedObject var gameVM: GameViewModel
    let audioVM: AudioViewModel
    
    @State private var isBreathing = false
    @State private var speakerScale: CGFloat = 1.0
    @State private var showWordTemporarily = false
    @State private var wordScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.8))
                .frame(width: size, height: size)
                .shadow(radius: gameVM.isBubbleSelected(bubbleId) ? 10 : 5)
                .scaleEffect(isBreathing ? 1.1 : 1.0)
            
            if gameVM.isListeningMode && bubbleId.hasSuffix("_en") && !showWordTemporarily {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(.white)
                    .scaleEffect(speakerScale)
            } else {
                Text(word)
                    .font(.system(size: size * 0.3))
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
                    .foregroundColor(.white)
                    .frame(width: size * 0.8, height: size)
                    .scaleEffect(showWordTemporarily ? wordScale : 1.0)
            }
        }
        .position(position)
        .onTapGesture {
            if bubbleId.hasSuffix("_en") {
                audioVM.playEnglishWord(word)
                
                if gameVM.isListeningMode {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        speakerScale = 1.3
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            speakerScale = 1.0
                        }
                    }
                }
            }
            gameVM.selectBubble(id: bubbleId)
        }
        .onChange(of: gameVM.matchedPair) { newValue in
            if let pair = newValue {
                if bubbleId.hasSuffix("_en") && (bubbleId == pair.firstId || bubbleId == pair.secondId) {
                    showWordTemporarily = true
                    
                    withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                        wordScale = 1.2
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation {
                            wordScale = 1.0
                        }
                        withAnimation {
                            showWordTemporarily = false
                        }
                    }
                }
            }
        }
        .onChange(of: gameVM.isBubbleSelected(bubbleId)) { newValue in
            isBreathing = newValue
        }
    }
}

//#Preview {
//    ZStack {
//        Color.white
//        LevelBubbleView(
//            word: "Hello",
//            color: .blue,
//            position: CGPoint(x: 100, y: 100),
//            bubbleId: "test_en",
//            gameVM: GameViewModel(),
//            audioVM: AudioViewModel()
//        )
//    }
//    .frame(width: 300, height: 300)
//}
