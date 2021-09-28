//
//  DolphinChatHistory.swift
//  imi-dolphin-livechat-ios
//
//  Created by Jhoan River S on 28/09/21.
//

import Foundation


public struct DolphinChatHistory: Codable {
    
    public let parent: Int?
    public let ticketNumber, audioLink, prettyDate, accountName: String?
    public let unreadMessages: Int?
    public let subject, channel, slaStatusText, channelType: String?
    public let ticketAnswer, displayConferenceParticipant: Bool?
    public let documentLink: String?
    public let ccList: [JSONAny]?
    public let modifiedBy, id, botID: String?
    public let selected: Bool?
    public let friendlyName, owner, severity: String?
    public let attachmentExist: Bool?
    public let statusStyle: String?
    public let conferenceParticipantObject, callParticipantObject: [JSONAny]?
    public let createdDateText, messageID: String?
    public let dateTimeline: Int?
    public let internalCallRecipient: Bool?
    public let prettyDateTimeline, collection: String?
    public let callVariableObject: [JSONAny]?
    public let emailRecipient, message, replyAgent: String?
    public let markRead: Bool?
    public let ccListFormatted, transactionID: String?
    public let overReplySla: Bool?
    public let accountID: String?
    public let createdDate: Int?
    public let answer: Bool?
    public let severityStyle, createdBy, channelKey: String?
    public let modifiedDate: Int?
    public let pictureLink: String?
    public let videoLink, slaStyle: String?
    

    enum CodingKeys: String, CodingKey {
        case parent, ticketNumber, audioLink, prettyDate, accountName, unreadMessages, subject, channel, slaStatusText, channelType, ticketAnswer, displayConferenceParticipant, documentLink,ccList, modifiedBy, id
        case botID = "botId"
        case selected, friendlyName, owner, severity, attachmentExist, statusStyle, conferenceParticipantObject, callParticipantObject, createdDateText
        case messageID = "messageId"
        case dateTimeline, internalCallRecipient, prettyDateTimeline, collection, callVariableObject, emailRecipient, message, replyAgent, markRead, ccListFormatted
        case transactionID = "transactionId"
        case overReplySla
        case accountID = "accountId"
        case createdDate, answer, severityStyle, createdBy, channelKey, modifiedDate, pictureLink, videoLink, slaStyle
    }

    public init(parent: Int?, ticketNumber: String?, audioLink: String?, prettyDate: String?, accountName: String?, unreadMessages: Int?, subject: String?, channel: String?, slaStatusText: String?, channelType: String?, ticketAnswer: Bool?, displayConferenceParticipant: Bool?, documentLink: String?,ccList: [JSONAny]?, modifiedBy: String?, id: String?, botID: String?, selected: Bool?, friendlyName: String?, owner: String?, severity: String?, attachmentExist: Bool?, statusStyle: String?, conferenceParticipantObject: [JSONAny]?, callParticipantObject: [JSONAny]?, createdDateText: String?, messageID: String?, dateTimeline: Int?, internalCallRecipient: Bool?, prettyDateTimeline: String?, collection: String?, callVariableObject: [JSONAny]?, emailRecipient: String?, message: String?, replyAgent: String?, markRead: Bool?, ccListFormatted: String?, transactionID: String?, overReplySla: Bool?, accountID: String?, createdDate: Int?, answer: Bool?, severityStyle: String?, createdBy: String?, channelKey: String?, modifiedDate: Int?, pictureLink: String?, videoLink: String?, slaStyle: String?) {
        self.parent = parent
        self.ticketNumber = ticketNumber
        self.audioLink = audioLink
        self.prettyDate = prettyDate
        self.accountName = accountName
        self.unreadMessages = unreadMessages
        self.subject = subject
        self.channel = channel
        self.slaStatusText = slaStatusText
        self.channelType = channelType
        self.ticketAnswer = ticketAnswer
        self.displayConferenceParticipant = displayConferenceParticipant
        self.documentLink = documentLink
        self.ccList = ccList
        self.modifiedBy = modifiedBy
        self.id = id
        self.botID = botID
        self.selected = selected
        self.friendlyName = friendlyName
        self.owner = owner
        self.severity = severity
        self.attachmentExist = attachmentExist
        self.statusStyle = statusStyle
        self.conferenceParticipantObject = conferenceParticipantObject
        self.callParticipantObject = callParticipantObject
        self.createdDateText = createdDateText
        self.messageID = messageID
        self.dateTimeline = dateTimeline
        self.internalCallRecipient = internalCallRecipient
        self.prettyDateTimeline = prettyDateTimeline
        self.collection = collection
        self.callVariableObject = callVariableObject
        self.emailRecipient = emailRecipient
        self.message = message
        self.replyAgent = replyAgent
        self.markRead = markRead
        self.ccListFormatted = ccListFormatted
        self.transactionID = transactionID
        self.overReplySla = overReplySla
        self.accountID = accountID
        self.createdDate = createdDate
        self.answer = answer
        self.severityStyle = severityStyle
        self.createdBy = createdBy
        self.channelKey = channelKey
        self.modifiedDate = modifiedDate
        self.pictureLink = pictureLink
        self.videoLink = videoLink
        self.slaStyle = slaStyle
    }
}
