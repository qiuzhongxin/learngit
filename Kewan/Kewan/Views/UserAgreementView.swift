import SwiftUI

struct UserAgreementView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("用户协议")
                        .font(.title)
                        .bold()
                    
                    Text("欢迎使用泡泡英语！在使用我们的服务之前，请仔细阅读以下用户协议。")
                    
                    Text("1. 服务说明")
                        .font(.headline)
                    Text("泡泡英语是一款英语学习应用，提供单词记忆、听力练习等功能。我们致力于为用户提供优质的英语学习体验。")
                    
                    Text("2. 账号管理")
                        .font(.headline)
                    Text("• 用户可以使用Apple ID登录账号\n• 用户有责任保护自己的账号安全\n• 用户可以随时删除账号，但删除后所有数据将无法恢复")
                    
                    Text("3. 会员服务")
                        .font(.headline)
                    Text("• 基础功能永久免费使用\n• 高级功能需要订阅会员\n• 会员订阅可以在App Store中管理和取消\n• 未使用的会员期限不予退款")
                }
                
                Group {
                    Text("4. 数据同步")
                        .font(.headline)
                    Text("• 学习记录将通过iCloud同步\n• 请确保您的设备已登录iCloud账号\n• 同步功能依赖于网络连接")
                    
                    Text("5. 用户行为规范")
                        .font(.headline)
                    Text("用户在使用过程中应遵守相关法律法规，不得从事任何违法或不当行为。")
                    
                    Text("6. 隐私保护")
                        .font(.headline)
                    Text("我们重视用户隐私保护，具体隐私政策请参考隐私协议。")
                    
                    Text("7. 免责声明")
                        .font(.headline)
                    Text("• 我们会持续优化和更新服务内容\n• 对于因不可抗力导致的服务中断，我们不承担责任\n• 用户因违反本协议造成的损失由用户自行承担")
                    
                    Text("8. 协议修改")
                        .font(.headline)
                    Text("我们保留随时修改本协议的权利，修改后的协议将在应用内公布。")
                    
                    Link("在线查看用户协议", destination: URL(string: "https://qiuzhongxin.github.io/kewanapp/terms.html")!)
                        .foregroundColor(.blue)
                        .padding(.top)
                }
            }
            .padding()
        }
        .navigationTitle("用户协议")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        UserAgreementView()
    }
} 