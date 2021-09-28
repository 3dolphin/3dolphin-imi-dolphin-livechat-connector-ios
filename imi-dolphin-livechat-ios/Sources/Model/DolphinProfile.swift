//
//  DolphinProfile.swift
//  imi-dolphin-livechat-ios
//
//  Created by Jhoan River S on 28/09/21.
//

import Foundation

public class DolphinProfile {
    
    public var name: String?
    public var email: String?
    public var phoneNumber: String?
    public var customerId: String?
    public var uid: String?
    
    
    public init(name: String, email: String, phoneNumber: String, customerId: String, uid: String) {
        
        self.name = name
        self.email = email
        self.phoneNumber = phoneNumber
        self.customerId = customerId
        self.uid = uid
    
    }
}
