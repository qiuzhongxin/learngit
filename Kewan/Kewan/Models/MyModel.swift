//
//  MyModel.swift
//  Kewan
//
//  Created by Zhongxin qiu on 2024/11/30.
//

import SwiftUI
import Foundation

struct MyModel: Identifiable, Codable, Equatable {
    let id: String  // 改为 String 类型以匹配 JSON 数据
    let english: String
    let chinese: String
    let phonetic: String?  // 添加音标字段
    
    // 自定义解码方法来处理空格
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        english = try container.decode(String.self, forKey: .english).trimmingCharacters(in: .whitespaces)
        chinese = try container.decode(String.self, forKey: .chinese).trimmingCharacters(in: .whitespaces)
        phonetic = try container.decodeIfPresent(String.self, forKey: .phonetic)?.trimmingCharacters(in: .whitespaces)
    }
    
    // 保留原有的初始化方法
    init(id: String = UUID().uuidString, english: String, chinese: String, phonetic: String? = nil) {
        self.id = id
        self.english = english
        self.chinese = chinese
        self.phonetic = phonetic
    }
    
    static func == (lhs: MyModel, rhs: MyModel) -> Bool {
        return lhs.id == rhs.id
    }
}
