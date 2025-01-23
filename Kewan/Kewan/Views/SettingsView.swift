import SwiftUI

struct SettingsView: View {
    @ObservedObject var userVM: UserViewModel
    @StateObject private var settings = AppSettings.shared
    @State private var showLoginSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showSubscriptionView = false
    @State private var showPrivacyPolicy = false
    @State private var showUserAgreement = false
    @Environment(\.presentationMode) var presentationMode
    
    private let colorOptions = [
        ("紫色", "purple"),
        ("绿色", "green"),
        ("蓝色", "blue"),
        ("黄色", "yellow"),
        ("红色", "red"),
        ("黑色", "black"),
        ("白色", "white"),
        ("橙色", "orange"),
        ("青色", "mint"),
        ("粉色", "pink")
    ]
    
    var body: some View {
        NavigationView {
            List {
                // 用户信息部分
                Section {
                    if userVM.isLoggedIn {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 50))
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    Text(userVM.username)
                                }
                                .font(.headline)
                                Text("已登录")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    } else {
                        Button(action: {
                            showLoginSheet = true
                        }) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 50))
                                VStack{
                                    Text("点击登录")
                                        .foregroundColor(.blue)
                                    Text("登录数据永久保存并同步iCloud")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 15))
                                }
                                
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.footnote)
                            }
                        }
                    }
                }
                
                // 会员状态部分
                Section(header: Text("订阅状态")) {
                    HStack {
                        Text("当前状态")
                            .padding(.trailing)
                        Text(userVM.membershipLevel.displayName)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        showSubscriptionView = true
                    }) {
                        Text("会员管理")
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }) {
                        HStack {
                            Text("订阅管理")
                                .foregroundColor(.gray)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.footnote)
                        }
                    }
                }
                
                // 背景颜色设置
                Section(header: Text("背景颜色")) {
                    ForEach(colorOptions, id: \.1) { option in
                        HStack {
                            Circle()
                                .fill(getColor(option.1))
                                .frame(width: 20, height: 20)
                            Text(option.0)
                            Spacer()
                            if settings.backgroundColor == option.1 {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            settings.backgroundColor = option.1
                        }
                    }
                }
                
                // 添加透明度滑块
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("背景透明度")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        HStack {
                            Image(systemName: "circle.fill")
                                .foregroundColor(.gray)
                                .opacity(0.2)
                            Slider(value: $settings.backgroundOpacity, in: 0.1...1.0)
                                .tint(.gray)
                            Image(systemName: "circle.fill")
                                .foregroundColor(.gray)
                        }
                        // 预览区域
                        RoundedRectangle(cornerRadius: 10)
                            .fill(settings.color.opacity(settings.backgroundOpacity))
                            .frame(height: 80)
                    }
                }
                
                // 语音设置
                Section(header: Text("语音设置")) {
                    ForEach(settings.voiceOptions, id: \.1) { option in
                        HStack {
                            Text(option.0)
                            Spacer()
                            if settings.selectedVoice == option.1 {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            settings.selectedVoice = option.1
                        }
                    }
                }
                
                // 其他信息
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("版权信息")
                        Spacer()
                        Text("Copyright © 2025 非常时期")
                            .foregroundColor(.gray)
                    }
                    
                    NavigationLink("隐私协议") {
                        PrivacyPolicyView()
                    }
                    
                    NavigationLink("用户协议") {
                        UserAgreementView()
                    }
                }
                
                // 账号操作部分
                Section {
                    Button(action: {
                        if userVM.isLoggedIn {
                            userVM.logout()
                        } else {
                            showLoginSheet = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(userVM.isLoggedIn ? .red : .gray)
                            Text("退出账号")
                                .foregroundColor(userVM.isLoggedIn ? .red : .gray)
                        }
                    }
                    .disabled(!userVM.isLoggedIn)
                }
                
                Section {
                    Button(action: {
                        if userVM.isLoggedIn {
                            showDeleteConfirmation = true
                        } else {
                            showLoginSheet = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(userVM.isLoggedIn ? .red : .gray)
                            Text("删除账号")
                                .foregroundColor(userVM.isLoggedIn ? .red : .gray)
                        }
                    }
                    .disabled(!userVM.isLoggedIn)
                    .alert("确认删除账号", isPresented: $showDeleteConfirmation) {
                        Button("取消", role: .cancel) {}
                        Button("删除", role: .destructive) {
                            Task {
                                await userVM.deleteAccount()
                            }
                        }
                    } message: {
                        Text("删除账号后，所有数据将被永久清除且无法恢复，包括：\n\n• 学习记录\n• 收藏的单词\n• 会员状态\n\n是否确认删除？")
                    }
                }
            }
//            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showLoginSheet) {
                LoginView(userVM: userVM)
            }
            .sheet(isPresented: $showSubscriptionView) {
                SubscriptionView(userVM: userVM)
            }
            .onChange(of: showLoginSheet) { newValue in
                if !newValue {
                    Task {
                        await IAPManager.shared.loadPurchasedProducts()
                    }
                }
            }
            .onChange(of: showSubscriptionView) { newValue in
                if !newValue {
                    Task {
                        await IAPManager.shared.loadPurchasedProducts()
                    }
                }
            }
            .onAppear {
                Task {
                    await IAPManager.shared.loadPurchasedProducts()
                }
            }
            .listStyle(InsetGroupedListStyle())
            .background(settings.color.opacity(settings.backgroundOpacity))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func getColor(_ name: String) -> Color {
        switch name {
        case "green": return .green
        case "blue": return .blue
        case "yellow": return .yellow
        case "purple": return .purple
        case "red": return .red
        case "black": return .black
        case "white": return .white
        case "orange": return .orange
        case "mint": return.mint
        case "pink": return.pink
        default: return .purple
        }
    }
}

// 添加预览
#Preview {
    NavigationView {
        SettingsView(userVM: UserViewModel())
            .navigationBarTitleDisplayMode(.inline)
    }
}

