//
//  Model.swift
//  CS193p
//
//  Created by WisidomCleanMaster on 2023/7/13.
//

/// 从文件加载模型, 保存模型到文件
import Foundation
import Combine

// SwiftUI订阅ObservableObject对象, 当ObservableObject改变时SwiftUI会主动刷新订阅的view
class ModelData: ObservableObject {
    
    // 使用Published修复属性后, 当属性改变时回主动发送消息, 订阅改消息的view就能及时获取最新状态
    @Published var landmarks: [Landmark] = load("landmarkData.json")
    
    @Published var profile = Profile.default
    
    let episodeStore = EpisodeStore()
    
    // 加载徒步旅行数据, 该数据无需修改无需使用 @Published修饰
    let hikes: [Hike] = load("hikeData.json")
    
    var features: [Landmark] {
        landmarks.filter { $0.isFeatured }
    }
    
    var categories: [String: [Landmark]] {
        // 通过category将集合landmarks分类
        Dictionary(
            grouping: landmarks,
            by: {$0.category.rawValue})
    }
}

func load<T: Decodable>(_ filename: String) -> T {
    guard let file = Bundle.main.url(forResource: filename, withExtension: nil) else {
        fatalError("没有找到文件: \(filename)")
    }

    do {
        let data = try Data(contentsOf: file)
        let decoder = JSONDecoder()
        // 模型的参数必须与文件中一一对应
        // 参数可以比文件中少, 但是不能是文件中没有的
        // 例如模型中定义description2, 但文件中只有description, 则解码失败
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("创建模型失败")
    }
}
