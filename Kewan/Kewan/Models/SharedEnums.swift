import Foundation

// 会员等级枚举
enum MembershipLevel: Int, Comparable {
    case free = 0
    case monthly = 1
    case yearly = 2
    case lifetime = 3
    
    var hasAccess: Bool {
        self != .free
    }
    
    var displayName: String {
        switch self {
        case .free:
            return "免费用户"
        case .monthly:
            return "月度会员"
        case .yearly:
            return "年度会员"
        case .lifetime:
            return "永久会员"
        }
    }
    
    static func < (lhs: MembershipLevel, rhs: MembershipLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// 内容类型枚举
enum ContentType {
    case basicWords     // 基础单词
    case dailyPhrase    // 每日短语
    case advancedFeatures // 高级功能（包括进阶单词和高级单词）
} 