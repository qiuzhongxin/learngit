import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @StateObject private var iapManager = IAPManager.shared
    @ObservedObject var userVM: UserViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var canPurchaseProduct: Bool {
        guard let product = selectedProduct else { return true }
        let selectedLevel = getMembershipLevel(for: product)
        return selectedLevel > userVM.membershipLevel
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 会员特权介绍
                    VStack(alignment: .leading, spacing: 15) {
                        Text("会员特权")
                            .font(.title2)
                            .bold()
                        
                        FeatureRow(icon: "star.fill", color: .yellow, text: "解锁所有单词和短语")
                        FeatureRow(icon: "book.fill", color: .blue, text: "高级词汇学习")
                        FeatureRow(icon: "chart.bar.fill", color: .green, text: "详细的学习统计")
                        FeatureRow(icon: "icloud.fill", color: .blue, text: "iCloud 同步")
                        FeatureRow(icon: "person.2.fill", color: .purple, text: "家庭共享（仅限永久会员）")
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                    // 订阅选项
                    VStack(spacing: 15) {
                        ForEach(iapManager.subscriptions, id: \.id) { product in
                            SubscriptionOptionView(
                                product: product,
                                isSelected: selectedProduct?.id == product.id,
                                isDisabled: userVM.membershipLevel >= getMembershipLevel(for: product),
                                onSelect: {
                                    if canPurchaseProduct {
                                        selectedProduct = product
                                    }
                                }
                            )
                        }
                        
                        // 永久会员选项
                        if let lifetimeProduct = iapManager.nonConsumables.first {
                            SubscriptionOptionView(
                                product: lifetimeProduct,
                                isSelected: selectedProduct?.id == lifetimeProduct.id,
                                isDisabled: userVM.membershipLevel >= .lifetime,
                                onSelect: {
                                    if canPurchaseProduct {
                                        selectedProduct = lifetimeProduct
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // 购买按钮
                    Button(action: {
                        if let product = selectedProduct {
                            Task {
                                await purchase(product)
                            }
                        }
                    }) {
                        if isPurchasing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("立即购买")
                                .bold()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedProduct != nil ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .disabled(isPurchasing || selectedProduct == nil)
                    
                    // 隐私政策和用户协议链接
                    VStack(spacing: 10) {
                        Link("隐私政策", destination: URL(string: "https://qiuzhongxin.github.io/kewanapp/index.html")!)
                            .foregroundColor(.blue)
                        Link("用户协议", destination: URL(string: "https://qiuzhongxin.github.io/kewanapp/agreement.html")!)
                            .foregroundColor(.blue)
                        Link("取消订阅", destination: URL(string: "itms-apps://apps.apple.com/account/subscriptions")!)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 10)
                    
                    // 订阅说明
                    VStack(spacing: 10) {
                        Text("订阅说明")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("1. 订阅期间可以使用所有高级功能")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("2. 自动订阅将在到期前24小时内自动续费")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("3. 可以随时在 App Store 中取消订阅")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                .padding(.vertical)
            }
            .navigationTitle("订阅管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            // 加载商品
            await iapManager.loadProducts()
        }
        .alert("购买失败", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func purchase(_ product: Product) async {
        isPurchasing = true
        do {
            try await iapManager.purchase(product)
            dismiss()
        } catch StoreError.userCancelled {
            errorMessage = "购买已取消"
            showError = true
        } catch StoreError.pending {
            errorMessage = "购买正在处理中，请稍后查看"
            showError = true
        } catch {
            errorMessage = "购买失败：\(error.localizedDescription)"
            showError = true
        }
        isPurchasing = false
    }
    
    private func getMembershipLevel(for product: Product) -> MembershipLevel {
        switch product.id {
        case IAPProduct.monthly.rawValue:
            return .monthly
        case IAPProduct.yearly.rawValue:
            return .yearly
        case IAPProduct.lifetime.rawValue:
            return .lifetime
        default:
            return .free
        }
    }
    
    private func getDisplayName(for product: Product) -> String? {
        switch product.id {
        case IAPProduct.monthly.rawValue:
            return "月度订阅"
        case IAPProduct.yearly.rawValue:
            return "年度订阅"
        case IAPProduct.lifetime.rawValue:
            return "永久会员（支持家人共享）"
        default:
            return nil
        }
    }
    
    private func getDescription(for product: Product) -> String? {
        switch product.id {
        case IAPProduct.monthly.rawValue:
            return "订阅后可学习海量单词\n有效期1个月,时间到后用户自由选择是否续期"
        case IAPProduct.yearly.rawValue:
            return "订阅后可学习海量单词\n有效期1个年,时间到后用户自由选择是否续期"
        case IAPProduct.lifetime.rawValue:
            return "一次性购买，永久使用\n支持家人共享"
        default:
            return nil
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            Text(text)
                .foregroundColor(.primary)
            Spacer()
        }
    }
}

struct SubscriptionOptionView: View {
    let product: Product
    let isSelected: Bool
    let isDisabled: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let displayName = getDisplayName(for: product) {
                        Text(displayName)
                            .font(.headline)
                    }
                    if let description = getDescription(for: product) {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.displayPrice)
                        .bold()
                    if product.id == IAPProduct.monthly.rawValue {
                        Text("每月")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if product.id == IAPProduct.yearly.rawValue {
                        Text("每年")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if isDisabled {
                    Text("已拥有")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(4)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.gray, lineWidth: isSelected ? 2 : 1)
            )
            .opacity(isDisabled ? 0.5 : 1)
        }
        .disabled(isDisabled)
    }
    
    private func getDisplayName(for product: Product) -> String? {
        switch product.id {
        case IAPProduct.monthly.rawValue:
            return "月度订阅"
        case IAPProduct.yearly.rawValue:
            return "年度订阅"
        case IAPProduct.lifetime.rawValue:
            return "永久会员（支持家人共享）"
        default:
            return nil
        }
    }
    
    private func getDescription(for product: Product) -> String? {
        switch product.id {
        case IAPProduct.monthly.rawValue:
            return "订阅后可学习海量单词\n有效期1个月,时间到后用户自由选择是否续期"
        case IAPProduct.yearly.rawValue:
            return "订阅后可学习海量单词\n有效期1个年,时间到后用户自由选择是否续期"
        case IAPProduct.lifetime.rawValue:
            return "一次性购买，永久使用\n支持家人共享"
        default:
            return nil
        }
    }
}

#Preview {
    SubscriptionView(userVM: UserViewModel())
}
