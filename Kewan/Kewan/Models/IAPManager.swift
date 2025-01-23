import Foundation
import StoreKit

@MainActor
class IAPManager: ObservableObject {
    static let shared = IAPManager()
    private var products: [Product] = []
    private var userVM: UserViewModel?
    
    @Published private(set) var subscriptions: [Product] = []
    @Published private(set) var nonConsumables: [Product] = []
    @Published var isLoading = false
    
    private init() {}
    
    func configure(with userViewModel: UserViewModel) {
        self.userVM = userViewModel
        // 只在用户登录时加载已购买的产品
        if userViewModel.isLoggedIn {
            Task {
                await loadPurchasedProducts()
            }
        }
    }
    
    func loadProducts() async {
        isLoading = true
        do {
            // 请求所有产品
            let products = try await Product.products(for: IAPProduct.allCases.map { $0.rawValue })
            
            // 分类产品
            self.products = products
            self.subscriptions = products.filter { $0.type == .autoRenewable }
            self.nonConsumables = products.filter { $0.type == .nonConsumable }
            
            isLoading = false
        } catch {
            print("Failed to load products:", error)
            isLoading = false
        }
    }
    
    func purchase(_ product: Product) async throws {
        guard let userVM = self.userVM else {
            throw StoreError.notConfigured
        }
        
        // 确保用户已登录
        guard userVM.isLoggedIn else {
            throw StoreError.notLoggedIn
        }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // 验证购买
            switch verification {
            case .verified(let transaction):
                // 购买成功
                await transaction.finish()
                await savePurchase(product.id)
            case .unverified:
                throw StoreError.failedVerification
            }
        case .userCancelled:
            throw StoreError.userCancelled
        case .pending:
            throw StoreError.pending
        @unknown default:
            break
        }
    }
    
    func loadPurchasedProducts() async {
        guard let userVM = self.userVM else { return }
        
        // 如果用户未登录，直接返回
        guard userVM.isLoggedIn else {
            await MainActor.run {
                userVM.updatePurchasedProducts([])
            }
            return
        }
        
        // 检查所有交易
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                // 只有在用户登录状态下才保存购买记录
                if userVM.isLoggedIn {
                    await savePurchase(transaction.productID)
                }
            case .unverified:
                continue
            }
        }
    }
    
    private func savePurchase(_ productID: String) async {
        guard let userVM = self.userVM else { return }
        
        // 确保用户已登录
        guard userVM.isLoggedIn else { return }
        
        await MainActor.run {
            var updatedProducts = userVM.purchasedProducts
            updatedProducts.insert(productID)
            userVM.updatePurchasedProducts(updatedProducts)
        }
    }
    
    // 获取产品价格
    func formattedPrice(for product: Product) -> String {
        product.displayPrice
    }
    
    // 清除所有购买记录
    func clearPurchases() async {
        guard let userVM = self.userVM else { return }
        await MainActor.run {
            userVM.updatePurchasedProducts([])
        }
    }
    
    // 检查用户是否有完整访问权限
    var hasFullAccess: Bool {
        guard let userVM = self.userVM else { return false }
        return userVM.isLoggedIn && userVM.hasFullAccess
    }
    
    // 获取用户的会员等级
    var membershipLevel: MembershipLevel {
        guard let userVM = self.userVM else { return .free }
        return userVM.isLoggedIn ? userVM.membershipLevel : .free
    }
    
    // 检查是否有权限访问特定内容
    func canAccess(_ content: ContentType) -> Bool {
        guard let userVM = self.userVM else { return false }
        return userVM.isLoggedIn && userVM.canAccess(content)
    }
}

// 错误类型
enum StoreError: Error {
    case failedVerification
    case userCancelled
    case pending
    case notLoggedIn
    case notConfigured
}

// 单词级别
enum WordLevel {
    case basic          // 基础单词
    case intermediate   // 进阶单词5000
    case advanced      // 高级英语单词
} 