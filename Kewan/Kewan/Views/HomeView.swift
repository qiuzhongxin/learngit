//
//  HomeView.swift
//  Kewan
//
//  Created by Zhongxin qiu on 2024/11/30.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var gameVM = GameViewModel()
    @StateObject private var userVM = UserViewModel()
    @StateObject private var settings = AppSettings.shared
    
    var body: some View {
        TabView {
            ContentView(gameVM: gameVM, userVM: userVM)
                .tabItem {
                    Label("游戏", systemImage: "gamecontroller")
                }
            
            ScoreView(userVM: userVM)
                .tabItem {
                    Label("分数", systemImage: "chart.bar")
                }
            
            NavigationView {
                WordListView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("收藏", systemImage: "star")
            }
            
            NavigationView {
                SettingsView(userVM: userVM)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("设置", systemImage: "gearshape")
            }
        }
        .tabViewStyle(.automatic)
        .onChange(of: userVM.userId) { newValue in
            gameVM.setUserId(newValue)
        }
        .onAppear {
            gameVM.setUserId(userVM.userId)
            
            // 添加调试日志
            print("HomeView appeared")
            print("Settings color: \(settings.color)")
            
            // 确保 TabView 样式正确设置
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.overrideUserInterfaceStyle = .light
            }
        }
        .accentColor(settings.color)
        .tint(settings.color)
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
}


