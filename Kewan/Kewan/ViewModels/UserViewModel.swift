//
//  UserViewModel.swift
//  Kewan
//
//  Created by Zhongxin qiu on 2024/12/9.
//

import SwiftUI
import AuthenticationServices

class UserViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var username: String = ""
    @Published var userAvatar: String = "person.circle.fill"
    @Published var userId: String = ""
    @Published var purchasedProducts: Set<String> = []
    
    init() {
        self.isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        self.username = UserDefaults.standard.string(forKey: "username") ?? ""
        self.userId = UserDefaults.standard.string(forKey: "userId") ?? ""
        
        // 加载已购买的产品
        if let purchased = UserDefaults.standard.array(forKey: "PurchasedProducts") as? [String] {
            self.purchasedProducts = Set(purchased)
        }
        
        // 配置 IAPManager
        Task { @MainActor in
            IAPManager.shared.configure(with: self)
        }
    }
    
    func login(username: String) {
        self.username = username
        self.userId = UUID().uuidString
        self.isLoggedIn = true
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        UserDefaults.standard.set(username, forKey: "username")
        UserDefaults.standard.set(userId, forKey: "userId")
    }
    
    func loginWithApple(userId: String, username: String?) {
        self.userId = userId
        self.username = username ?? "Apple 用户 \(String(userId.prefix(4)))"
        self.isLoggedIn = true
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        UserDefaults.standard.set(self.username, forKey: "username")
        UserDefaults.standard.set(userId, forKey: "userId")
    }
    
    func logout() {
        self.username = ""
        self.userId = ""
        self.isLoggedIn = false
        self.purchasedProducts = []
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "PurchasedProducts")
        
        // 清除订阅状态
        Task {
            await IAPManager.shared.clearPurchases()
        }
    }
    
    func deleteAccount() async {
        // 删除所有用户相关数据
        CoreDataManager.shared.deleteAllUserData(userId: userId)
        
        // 删除用户设置
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "userAvatar")
        UserDefaults.standard.removeObject(forKey: "PurchasedProducts")
        
        // 重置用户状态
        await MainActor.run {
            self.userId = ""
            self.username = ""
            self.userAvatar = "person.circle"
            self.isLoggedIn = false
            self.purchasedProducts = []
        }
    }
    
    // 检查用户是否有权限访问所有内容
    var hasFullAccess: Bool {
        purchasedProducts.contains(IAPProduct.lifetime.rawValue) ||
        purchasedProducts.contains(IAPProduct.yearly.rawValue) ||
        purchasedProducts.contains(IAPProduct.monthly.rawValue)
    }
    
    // 检查用户的会员等级
    var membershipLevel: MembershipLevel {
        if purchasedProducts.contains(IAPProduct.lifetime.rawValue) {
            return .lifetime
        } else if purchasedProducts.contains(IAPProduct.yearly.rawValue) {
            return .yearly
        } else if purchasedProducts.contains(IAPProduct.monthly.rawValue) {
            return .monthly
        } else {
            return .free
        }
    }
    
    // 检查是否有权限访问特定内容
    func canAccess(_ content: ContentType) -> Bool {
        switch content {
        case .basicWords, .dailyPhrase:
            return true // 基础单词和每日短语永远可用
        case .advancedFeatures:
            return hasFullAccess // 高级功能需要任意会员权限
        }
    }
    
    func updatePurchasedProducts(_ products: Set<String>) {
        purchasedProducts = products
        UserDefaults.standard.set(Array(products), forKey: "PurchasedProducts")
    }
    
    func updateUsername(_ newUsername: String) {
        self.username = newUsername
        UserDefaults.standard.set(newUsername, forKey: "username")
    }
}
