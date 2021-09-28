//
//  ResponseToken.swift
//  imi-dolphin-livechat-ios
//
//  Created by Jhoan River S on 28/09/21.
//

import Foundation


public struct TokenModel: Codable {
    
    var accessToken:String?
    var tokenType: String?
    var refreshToken: String?
    var expiresIn: Int?
    var scope: String?
    
    init() {}
    
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case scope = "scope"
    }
}
