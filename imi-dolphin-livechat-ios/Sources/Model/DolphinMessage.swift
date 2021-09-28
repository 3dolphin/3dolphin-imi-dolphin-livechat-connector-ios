//
//  DolphinMessage.swift
//  imi-dolphin-livechat-ios
//
//  Created by Jhoan River S on 28/09/21.
//

import Foundation

public class DolphinMessage : Codable {
    
    public init(agent: String? = nil, agentAvatar: String? = nil, agentName: String? = nil, attFilename: String? = nil, attFilepath: String? = nil, attFilesize: Int? = nil, attFiletype: String? = nil, attUrl: String? = nil, customVariables: String? = nil, disconnect: Bool? = nil, event: String? = nil, inbound: Bool? = nil, iv: String? = nil, label: String? = nil, language: String? = nil, latitude: String? = nil, longitude: String? = nil, message: String? = nil, messageHash: String? = nil, outbound: Bool? = nil, salt: String? = nil, sessionId: String? = nil, token: String? = nil, transactionId: String? = nil, isUser: Bool? = nil, createdDate: Date? = nil, state: String? = nil, preCustomVar: Data? = nil)
    
    
    {
        self.agent = agent
        self.agentAvatar = agentAvatar
        self.agentName = agentName
        self.attFilename = attFilename
        self.attFilepath = attFilepath
        self.attFilesize = attFilesize
        self.attFiletype = attFiletype
        self.attUrl = attUrl
        self.customVariables = customVariables
        self.disconnect = disconnect
        self.event = event
        self.inbound = inbound
        self.iv = iv
        self.label = label
        self.language = language
        self.latitude = latitude
        self.longitude = longitude
        self.message = message
        self.messageHash = messageHash
        self.outbound = outbound
        self.salt = salt
        self.sessionId = sessionId
        self.token = token
        self.transactionId = transactionId
        self.isUser = isUser
        self.createdDate = createdDate
        self.state = state
        self.preCustomVar = preCustomVar
        
    }
    
    public var agent: String?
    public var agentAvatar: String?
    public var agentName: String?
    public var attFilename: String?
    public var attFilepath: String?
    public var attFilesize: Int?
    public var attFiletype: String?
    public var attUrl: String?
    public var customVariables: String?
    public var disconnect: Bool?
    public var event: String?
    public var inbound: Bool?
    public var iv: String?
    public var label: String?
    public var language: String?
    public var latitude: String?
    public var longitude: String?
    public var message: String?
    public var messageHash: String?
    public var outbound: Bool?
    public var salt: String?
    public var sessionId: String?
    public var token: String?
    public var transactionId: String?
    public var isUser: Bool?
    public var createdDate: Date?
    public var state: String?
    public var preCustomVar: Data?
    
    
    
    
    
    public static func parsingHistoryToMessage(chatMessage: DolphinChatHistory, filename: String? = nil, attachmentUrl: String? = nil, state: String)-> DolphinMessage {
        
        
        let epochTime = TimeInterval(chatMessage.createdDate!/1000)
        
        let dolphinMessage = DolphinMessage(
            agentName: !chatMessage.answer!
                ? chatMessage.accountName
                : chatMessage.replyAgent,
            attFilename: filename,
            attFiletype: chatMessage.message != nil && chatMessage.message != ""
                ? nil
                : state,
            attUrl: attachmentUrl,
            message: chatMessage.message != nil && chatMessage.message != ""
                ? chatMessage.message
                : nil,
            transactionId: chatMessage.transactionID,
            isUser: !chatMessage.answer!,
            createdDate: Date(timeIntervalSince1970: epochTime),
            state: state)
        
        
        return dolphinMessage
    }
    
}
