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
    public var filepath: String?
    
    
    enum CodingKeys: String, CodingKey {
        case fileType = "filetype"
        case filename = "filename"
        case status = "status"
        case filepath = "filepath"
    }
    
    
    init(fileType: String, filename: String, status: String, filepath: String) {
        self.fileType = fileType
        self.filename = filename
        self.status = status
        self.filepath = filepath
    }
        
}
