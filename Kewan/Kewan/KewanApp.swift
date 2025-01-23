//
//  KewanApp.swift
//  Kewan
//
//  Created by Zhongxin qiu on 2024/11/30.
//

import SwiftUI
import CoreData

@main
struct KewanApp: App {
    // 使用 CoreDataManager 的共享实例
    let coreDataManager = CoreDataManager.shared
    let wordStore = WordStore.shared
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, coreDataManager.viewContext)
        }
    }
}
