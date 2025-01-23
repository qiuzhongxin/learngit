import SwiftUI

struct ScoreRingView: View {
    let progress: Double // 0.0 to 1.0
    let score: Double
    let date: Date
    let ringColor: Color
    let ringWidth: CGFloat
    let size: CGFloat
    let showScore: Bool
    
    @State private var isBreathing = false
    
    // 只保留缩放范围
    private var scaleRange: (min: Double, max: Double) {
        size > 100 ? (1, 1.03) : (0.9, 1.1)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // 背景环
                Circle()
                    .stroke(ringColor.opacity(0.5), lineWidth: ringWidth)
                
                // 进度环
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        ringColor,
                        style: StrokeStyle(
                            lineWidth: ringWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)
                    .scaleEffect(progress >= 1.0 ? (isBreathing ? scaleRange.min : scaleRange.max) : 1.0)
                    .animation(
                        progress >= 1.0 ? 
                            Animation.easeInOut(duration: 1.2)
                                .repeatForever(autoreverses: true)
                            : .default,
                        value: isBreathing
                    )
                
                // 分数文本
                if showScore {
                    VStack(spacing: 4) {
                        Text(String(format: "%.0f", score))
                            .font(.system(size: size * 0.2, weight: .bold))
                            .foregroundColor(ringColor)
                            .scaleEffect(progress >= 1.0 ? (isBreathing ? scaleRange.min : scaleRange.max) : 1.0)
                            .animation(
                                progress >= 1.0 ? 
                                    Animation.easeInOut(duration: 1.2)
                                        .repeatForever(autoreverses: true)
                                    : .default,
                                value: isBreathing
                            )
                        
                        Text("每天目标:300分")
                            .font(.system(size: size * 0.05))
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(width: size, height: size)
            .padding(size > 100 ? 30 : 0)  // 只给大圆圈添加padding
            
            // 日期文本移到圆圈下方
            if showScore {
                Text(formatDate(date))
                    .font(.system(size: size * 0.05))
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            // 立即开始动画
            if progress >= 1.0 {
                isBreathing = true
            }
        }
        .onChange(of: progress) { newValue in
            // 当progress改变时更新动画状态
            isBreathing = newValue >= 1.0
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

struct DailyScoreRingView: View {
    let scores: [GameScore]
    let date: Date
    let isToday: Bool
    let showScore: Bool
    let isLarge: Bool  // 添加新属性来控制是否是大圆圈
    @State private var isBreathing = false  // 添加状态变量
    
    private var dailyScore: Double {
        let dayScores = scores.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
        return Double(dayScores.reduce(0) { $0 + Int($1.score) }) / 10.0
    }
    //目标分数
    private var progress: Double {
        min(dailyScore / 300.0, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ScoreRingView(
                progress: progress,
                score: dailyScore,
                date: date,
                ringColor: .purple,
                ringWidth: isLarge ? 80 : 10,
                size: isLarge ? 250 : 40,
                showScore: showScore
            )
            
            if !isLarge {
                Text(formatDate(date))
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            if progress >= 1.0 {
                isBreathing = true
            }
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
            formatter.dateFormat = "M-d"
            return formatter.string(from: date)
        }
    }
}

struct WeeklyScoreRingsView: View {
    let scores: [GameScore]
    @State private var selectedDate: Date = Date()  // 添加选中日期状态
    
    //小圆圈数量日期设置
    private var lastSevenDays: [Date] {
        (0..<18).map { days in
            Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 最近7天的小环
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 34) {
                    ForEach(lastSevenDays, id: \.timeIntervalSince1970) { date in
                        Button(action: {
                            withAnimation {
                                selectedDate = date
                            }
                        }) {
                            DailyScoreRingView(
                                scores: scores,
                                date: date,
                                isToday: Calendar.current.isDateInToday(date),
                                showScore: false,
                                isLarge: false  // 小圆圈统一大小
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(width: 35)
                    }
                }
                .padding(10)
            }
            .frame(height: 50)
            .padding(10)
            
            // 大环（固定外观，更新数据）
            DailyScoreRingView(
                scores: scores,
                date: selectedDate,
                isToday: Calendar.current.isDateInToday(selectedDate),
                showScore: true,
                isLarge: true  // 大圆圈
            )
            .padding(.top, 20)
        }
    }
}

#Preview {
    WeeklyScoreRingsView(scores: [])
        .frame(height: 400)
} 
