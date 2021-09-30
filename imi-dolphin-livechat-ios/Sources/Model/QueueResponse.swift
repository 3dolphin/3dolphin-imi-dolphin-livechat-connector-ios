//
//  QueueResponse.swift
//  imi-dolphin-livechat-ios
//
//  Created by Jhoan River S on 30/09/21.
//

import Foundation

public struct QueueResponse: Codable {
    
    public var data: Int?
    public var status: String?
    
    enum CodingKeys: String, CodingKey {
        case data = "data"
        case status = "status"
    }

    init(data: Int, status: String) {
        self.data = data
        self.status = status
    }
    
}
