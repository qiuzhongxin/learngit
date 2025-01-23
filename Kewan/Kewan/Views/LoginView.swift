import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @ObservedObject var userVM: UserViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                    .padding(.top, 50)
                
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let authResults):
                            if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
                                let userId = appleIDCredential.user
                                var username: String? = nil
                                
                                // 尝试获取用户的全名
                                if let fullName = appleIDCredential.fullName,
                                   let givenName = fullName.givenName {
                                    if let familyName = fullName.familyName {
                                        username = "\(givenName) \(familyName)"
                                    } else {
                                        username = givenName
                                    }
                                }
                                
                                // 如果没有获取到名字，使用一个默认的格式
                                if username?.isEmpty ?? true {
                                    username = "泡泡用户 \(String(userId.prefix(4)))"
                                }
                                
                                userVM.loginWithApple(userId: userId, username: username)
                                dismiss()
                            }
                        case .failure(let error):
                            print("登录失败：\(error.localizedDescription)")
                        }
                    }
                )
                .frame(height: 44)
                .padding(.horizontal)
                
                Text("登录您的苹果账号，您的学习记录可以保存并上传至iCloud同步")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationTitle("登录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LoginView(userVM: UserViewModel())
}
