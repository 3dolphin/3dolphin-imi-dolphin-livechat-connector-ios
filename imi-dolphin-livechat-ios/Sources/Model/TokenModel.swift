//
//  ResponseToken.swift
//  imi-dolphin-livechat-ios
//
//  Created by Jhoan River S on 28/09/21.
//

import Foundation


public class TokenModel: Codable {
    
    public var accessToken:String?
    public var tokenType: String?
    public var refreshToken: String?
    public var expiresIn: Int?
    public var scope: String?
    
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case scope = "scope"
    }
    
}
