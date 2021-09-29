//
//  FileResponse.swift
//  imi-dolphin-livechat-ios
//
//  Created by Jhoan River S on 29/09/21.
//

import Foundation


public struct FileResponse: Codable {
    
    public var fileType: String?
    public var filename: String?
    public var status: String?
    
    
    enum CodingKeys: String, CodingKey {
        case fileType = "filetype"
        case filename = "filename"
        case status = "status"
    }
    
    
    init(fileType: String, filename: String, status: String) {
        self.fileType = fileType
        self.filename = filename
        self.status = status
    }
        
}


public struct FilePath: Codable {
    
    public var bucket: String?
    public var filename: String?
    public var contentType: String?
    
    
    enum CodingKeys: String, CodingKey {
        case bucket = "bucket"
        case filename = "filename"
        case contentType = "contentType"
    }
    
}
