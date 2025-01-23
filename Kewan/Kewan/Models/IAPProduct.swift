import Foundation
import StoreKit

// 内购产品标识符
enum IAPProduct: String, CaseIterable {
    case monthly = "com.kewan.subscription.qiu1.monthly"     // 每月8元
    case yearly = "com.kewan.subscription.qiu2.yearly"       // 每年68元
    case lifetime = "com.qiuzx.kewan.lifetime"              // 399元永久会员
    
    var localizedTitle: String {
        switch self {
        case .monthly: return "月度订阅"
        case .yearly: return "年度订阅"
        case .lifetime: return "永久会员（支持家人共享）"
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .monthly: return "订阅后可学习海量单词，每月8元"
        case .yearly: return "订阅后可学习海量单词，年度订阅仅需68元（相当于5.7元/月）"
        case .lifetime: return "一次性购买399元，永久解锁所有内容，最多可与6位家庭成员共享"
        }
    }
} 