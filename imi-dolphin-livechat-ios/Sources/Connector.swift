
//
//  Connector.swift
//  imi-dolphin-livechat-ios
//
//  Created by Jhoan River S on 04/05/21.
//

import Foundation
import StompClientLib
import UIKit
import CryptoSwift
import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG
import os.log



let notificationMessage = "com.connector.notificationMessage"
let notificationConnectionStatus = "com.connector.connectionStatus"
let notificationReadMessage = "com.connector.notificationReadMessage"
let notificationTypingCondition = "com.connector.notificationTypingCondition"
let notificationQueue = "com.connector.notificationQueue"

public class Connector: StompClientLibDelegate {
    
    // message type
    
    static var MESSAGE_TYPE_OPTIONS = "options"
    static var MESSAGE_TYPE_BUTTON = "buttons"
    static var MESSAGE_TYPE_INCOMING = "incoming"
    static var MESSAGE_TYPE_OUTGOING = "outgoing"
    let topic_ACK: String = "/topic/ack-"
    let topic_messageEndpoint: String = "/topic/message-"
    let destinationUrl = "/app/wmessage"
    // is user active
    
    
    /*
     Param
     Base url
     Client id
     Client Secret
     */
    public var baseUrl: String = ""
    public var clientId: String = ""
    public var clientSecrect: String = ""
    public var isEnableQueue: Bool = false
    public var isShowTriggerMenu: Bool = false
    public var triggerMenuMessage = ""
    var token: String = ""
    var isConnecting: Bool = false
    var isConnected: Bool = false
    var socketClient = StompClientLib()
    var socketUrl = NSURL()
    var wsMessage: String?
    var wsAck: String = ""
    var sessionId: String?
    var dolphinProfile: DolphinProfile?
    public static let CONSTANT_TYPE_IMAGE: String = "image";
    public static let CONSTANT_TYPE_DOCUMENT: String = "document";
    public static let CONSTANT_TYPE_OCTET_STREAM: String = "application/octet-stream";
    public static let CONSTANT_TYPE_APPLICATION: String = "application/pdf";
    public static let CONSTANT_TYPE_AUDIO: String = "audio";
    public static let CONSTANT_TYPE_VIDEO: String = "video";
    public static let CONSTANT_TYPE_MESSAGE: String = "message";
    public var access_token = ""
    public var refresh_token = ""
    public var tokenModel: TokenModel = TokenModel()
    var subsystem = Bundle.main.bundleIdentifier!
    
    /*
     Initialisation connector
     */
    public static var shared = Connector()
    public init(){}
    
    
    /*
     setup url, clientid, and secretclient before start connection
     */
    public func connect(baseUrl: String, clientId: String, clientSecrect: String) {
        self.baseUrl = baseUrl
        self.clientId = clientId
        self.clientSecrect = clientSecrect
    }
    
    /*
     set up enable get chat history
     */
    public func enableGetHistory(isEnable: Bool){
        self.isEnableQueue = isEnable
    }
    
    
    /*
     Construct connection after receive data profile of user
     */
    public func constructConnector(profile: DolphinProfile) {
        dolphinProfile = profile
        getUserToken()
    }
    
    
    /*
     enable show trigger menu
     */
    public func doShowTriggerMenu(value: Bool){
        isShowTriggerMenu = value
    }
    
    /*
     Message for trigger menu
     */
    public func triggerMenu(message: String) {
        triggerMenuMessage = message
    }
    
    
    /*
     Get user access and refresh token
     Result :   access_token
                refresh_token
     */
    public func getUserToken(){
        token = "\(clientId):\(clientSecrect)".data(using: .utf8)?.base64EncodedString() ?? ""
        let url = URL(string: baseUrl+"/oauth/token?grant_type=password&username=\(clientId)&password=\(clientSecrect)")!
        let log = OSLog(subsystem: subsystem, category: "Access Token")
        
        let group = DispatchGroup()
        group.enter()
        
        ApiService.getAccessToken(url: url, token: token) { [self] result, error in
            if result != nil {
                self.tokenModel = result!
                self.access_token = result!.accessToken!
                self.refresh_token = result!.refreshToken!
                os_log("Success get access token : %@", log: log, type: .info, self.access_token)
                group.leave()
                print("leave")
                group.notify(queue: .main) {
                    print("finished all request")
                }
                self.refreshAccessToken()
               
            } else{
                os_log("Failed get access token", log: log, type: .error)
                group.leave()
                print("leave")
            }
        }
        
    }
    
    /*
     Refresh token after get called getUserToken
     Result :   access_token
                refresh_token
     */
    public func refreshAccessToken(){
        
        let log = OSLog(subsystem: subsystem, category: "Refresh Token")
        let url = URL(string: baseUrl+"/oauth/token?grant_type=refresh_token&refresh_token=\(refresh_token)")!
        ApiService.getRefreshToken(url: url, token: token) { [self] result, error in
            if result != nil
            {
                tokenModel = result!
                access_token = result!.accessToken!
                refresh_token = result!.refreshToken!
                os_log("Success get refresh token", log: log, type: .info)
                doConnectToStomp()
                isConnecting = true;
                DispatchQueue.main.async {
                                NotificationCenter.default.post(name: Notification.Name(rawValue: notificationConnectionStatus), object: 1)
                }
            } else{
                os_log("Failed get refresh token", log: log, type: .error)
            }
        }
    }
    
    /*
    Starting connection to web socket
     */
    public func doConnectToStomp(){
        let cutHttp: String = baseUrl.truncateUrl()
        let completedWSURL = "wss://\(cutHttp)/webchat/websocket?access_token=\(access_token)"
        socketUrl = NSURL(string: completedWSURL)!
        token = dolphinProfile!.name! + dolphinProfile!.email! + dolphinProfile!.phoneNumber! + dolphinProfile!.uid!
        token = token.md5()
        
        /*
         Call request to connect to websocket
         */
        socketClient.openSocketWithURLRequest(request: NSURLRequest(url: socketUrl as URL), delegate: self, connectionHeaders: [
            "accessToken" : self.access_token,
            "name" : dolphinProfile!.name!,
            "email" : dolphinProfile!.email!,
            "phone" : dolphinProfile!.phoneNumber!,
            "uid" : dolphinProfile!.uid!,
        ])
        
    }
    

    /*
     Receive all response from websocket
     response will be achieve :
        - Response from ACK topic
        - Response from Message topic
     */
    public func stompClient(client: StompClientLib!, didReceiveMessageWithJSONBody jsonBody: AnyObject?, akaStringBody stringBody: String?, withHeader header: [String : String]?, withDestination destination: String) {
        
        let log = OSLog(subsystem: subsystem, category: "Stomp Client Life")
        let data = Data(stringBody!.utf8)
        if destination.contains("/topic/ack") {
            os_log("ACK response message: message sent to server", log: log, type: .info)
        } else {
            do{
                let onReceivingMessage: DolphinMessage = try JSONDecoder().decode(DolphinMessage.self, from: data)
                let msgDecrypted = AESEncryption.doDecrypt(clientSecret: clientSecrect, accessToken: access_token, messageToDec: onReceivingMessage)
                
                if msgDecrypted != nil {
                    if msgDecrypted!.token != nil {
                        if msgDecrypted?.message == nil && msgDecrypted!.event == nil {
                            token = msgDecrypted!.token!
                            
                            print("current token", token)
                            if msgDecrypted?.sessionId != nil {
                                sessionId = msgDecrypted?.sessionId
                                DispatchQueue.main.async { [self] in
                                    NotificationCenter.default.post(name: Notification.Name(rawValue: notificationConnectionStatus), object: 2)
                                    os_log("Successfully subscribe message", log: log, type: .info)
                                    onSendMessage(messages: triggerMenuMessage)
                                }
                            }
                            subscribeTransaction()
                        } else {
                            setEvent(msgDecriypted: msgDecrypted!)
                        }
                    }
                }
            } catch let error as NSError {
                os_log("Failed to parsing message cause of: %@", log: log, type: .error, error.localizedDescription)
            }
        }
        
    }
    
    /*
     Set event for every received message
     Response : DolphineMessage with event disconnect, read, typing and incoming
     */
    public func setEvent(msgDecriypted: DolphinMessage) {
        let log = OSLog(subsystem: subsystem, category: "Event")
        DispatchQueue.main.async { [self] in
            if msgDecriypted.event == Constant.disconnectEvent {
                os_log("Disconnect event", log: log, type: .info)
                NotificationCenter.default.post(name: Notification.Name(rawValue: notificationConnectionStatus), object: 5)
            } else if msgDecriypted.event == Constant.readEvent {
                os_log("Read event", log: log, type: .info)
                NotificationCenter.default.post(name: Notification.Name(rawValue: notificationReadMessage), object: msgDecriypted)
            } else if msgDecriypted.event == Constant.typingEvent {
                os_log("Typing event", log: log, type: .info)
                NotificationCenter.default.post(name: Notification.Name(rawValue: notificationTypingCondition), object: msgDecriypted)
            } else if msgDecriypted.event == Constant.unassignedEvent {
                getQueueTicket()
                os_log("Unassigned event", log: log, type: .info)
            } else {
                os_log("Message event", log: log, type: .info)
                incomingMessage(incomingMsg: msgDecriypted)
            }
        }
    }
    
    
    /*
     getQueue ticket : When websocket send Message.event = unassigned
     */
    func getQueueTicket(){
        let socialId: String = dolphinProfile!.phoneNumber!+"-"+dolphinProfile!.name!
        let url = URL(string: baseUrl+"/webchat/queue?access_token=\(access_token)&token=\(token)&accountId=\(socialId)")
        let log = OSLog(subsystem: subSystem!, category: "Queue Log")
        
        ApiService.getQueueService(url: url!) { queueResponse, error in
            
            if queueResponse != nil {
                if queueResponse!.data! > 0 {
                    os_log("Broadcast queue to main", log: log, type: .info)
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: notificationQueue), object: queueResponse)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now()+30) { [self] in
                        getQueueTicket()
                    }
                }
            } else {
                os_log("Failed broadcast queue", log: log, type: .error)
            }
        }
        
    }
    
    
    /*
     Split type of incoming message by file type
     Response : message
                image
                video
                audio
                document
     */
    public func incomingMessage(incomingMsg: DolphinMessage) {
        incomingMsg.isUser = false
        if(incomingMsg.message != nil) {
            NotificationCenter.default.post(name: Notification.Name(rawValue: notificationMessage), object: incomingMsg)
        } else {
            incomingMsg.attUrl = getUrlFile(url: incomingMsg.attUrl!)
            if incomingMsg.attUrl != nil && (incomingMsg.attFiletype!.contains(Connector.CONSTANT_TYPE_IMAGE)) {
                setIncomingFileTypeAndState(message: incomingMsg, state: Connector.CONSTANT_TYPE_IMAGE)
            } else if incomingMsg.attUrl != nil && (incomingMsg.attFiletype!.contains(Connector.CONSTANT_TYPE_VIDEO)) || (incomingMsg.attFiletype!.contains(Connector.CONSTANT_TYPE_OCTET_STREAM)){
                setIncomingFileTypeAndState(message: incomingMsg, state: Connector.CONSTANT_TYPE_VIDEO)
            } else if incomingMsg.attUrl != nil && (incomingMsg.attFiletype!.contains(Connector.CONSTANT_TYPE_DOCUMENT) || incomingMsg.attFiletype!.contains(Connector.CONSTANT_TYPE_APPLICATION)){
                setIncomingFileTypeAndState(message: incomingMsg, state: Connector.CONSTANT_TYPE_DOCUMENT)
            } else if incomingMsg.attUrl != nil && incomingMsg.attFiletype!.contains(Connector.CONSTANT_TYPE_AUDIO) {
                setIncomingFileTypeAndState(message: incomingMsg, state: Connector.CONSTANT_TYPE_AUDIO)
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: notificationMessage), object: incomingMsg)
        }
    }
    
    
    /*
     Set incoming message state by fileType
     */
    public func setIncomingFileTypeAndState(message: DolphinMessage, state: String)-> Void {
        message.attFiletype = state
        message.state = state
    }
    
    
    /*
     Set file url from attUrl message
     Response : url + access_token
     */
    public func getUrlFile(url: String)-> String {
        let result: String = "\(url)?access_token=\(access_token)"
        print("attribute urlnya: ", result)
        return result
    }
    
    
    /*
     Override function
     When send message received by server
     */
    public func serverDidSendReceipt(client: StompClientLib!, withReceiptId receiptId: String) {
           print("Receipt : \(receiptId)")
    }
    
    
    /*
     Override function
     Response : Receive response from websocket when diconnected happened
                Broadcast notification disconnected
     */
    public func stompClientDidDisconnect(client: StompClientLib!) {
        let log = OSLog(subsystem: subsystem, category: "Stomp Client Disconnected")
        os_log("Disconnected from StompClient", log: log, type: .info)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name(rawValue: notificationConnectionStatus), object: 4)
        }
    }
    
    
    /*
     Reconnect to websocket
     Response : Broadcast notification connection reconnect
                Do reconnect to websocket
     */
    public func doReconnectToWs() {
        socketClient.autoDisconnect(time: 3)
        socketClient.reconnect(request: NSURLRequest(url: socketUrl as URL), delegate: self,connectionHeaders: [
            "accessToken" : self.access_token,
            "name" : dolphinProfile!.name!,
            "email" : dolphinProfile!.email!,
            "phone" : dolphinProfile!.phoneNumber!,
            "uid" : dolphinProfile!.uid!,
        ], time: 4)
    }

    
    /*
     Override function
     Receive response after client connected to web socket
     Response :     Subscribe message
                    isConnecting = false
                    isConnected = true
                    Get history chat
     */
    public func stompClientDidConnect(client: StompClientLib!) {
        subscribeMessage()
        isConnecting = false
        isConnected = true
        if isEnableQueue {
            getChatHistory()
        }
        
    }
    
    
    /*
     Do disconnect to websocket
     */
    public func doDisconnectToWs(){
        socketClient.disconnect()
    }
    
    
    /*
     Get chat history
     Hit API get history conversation
     Response : - Broadcast notification message to app
     */
    public func getChatHistory()-> Void {
        var socialid: String = dolphinProfile!.phoneNumber!+"-"+dolphinProfile!.name!
        print("social id", socialid)
        if !(dolphinProfile!.customerId == "") {
            socialid = dolphinProfile!.customerId!}
        let url = URL(string: baseUrl+"/webchat/conversation?contactid=\(socialid)&access_token=\(access_token)")!
        
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10)
        request.httpMethod = "GET"
        let dataTask = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            guard let _ = data, error == nil else {
                print(error?.localizedDescription ?? "No Data")
                return
            }
            var chatHistories = try! JSONDecoder().decode([DolphinChatHistory].self, from: data!)
            chatHistories.reverse()
            DispatchQueue.main.async { [self] in
                for chatMessage in chatHistories {
                    if chatMessage.message != nil && chatMessage.message != "" {
                        if(isShowTriggerMenu == false && chatMessage.message == triggerMenuMessage){
                            continue
                        } else{
                            let dolphinMessage = DolphinMessage.parsingHistoryToMessage(chatMessage: chatMessage, state: Connector.CONSTANT_TYPE_MESSAGE)
                            NotificationCenter.default.post(name: Notification.Name(rawValue: notificationMessage), object: dolphinMessage)
                        }
                    } else {
                        
                        if chatMessage.documentLink != nil {
                            let filename = chatMessage.documentLink!.parsingData()
                            broadcastChatHistory(chatMessage: chatMessage, filename: filename, accountName: chatMessage.accountName!, state: Connector.CONSTANT_TYPE_DOCUMENT)
                        } else if chatMessage.videoLink != nil {
                            let filename = chatMessage.videoLink!.parsingData()
                            broadcastChatHistory(chatMessage: chatMessage, filename: filename, accountName: chatMessage.accountName!, state: Connector.CONSTANT_TYPE_VIDEO)
                        } else if chatMessage.audioLink != nil {
                            let filename = chatMessage.audioLink!.parsingData()
                            broadcastChatHistory(chatMessage: chatMessage, filename: filename, accountName: chatMessage.accountName!, state: Connector.CONSTANT_TYPE_AUDIO)
                        } else if chatMessage.pictureLink != nil {
                            let filename = chatMessage.pictureLink!.parsingData()
                            broadcastChatHistory(chatMessage: chatMessage, filename: filename, accountName: chatMessage.accountName!, state: Connector.CONSTANT_TYPE_IMAGE)
                        }
                    }
                 }
            }
        })
        dataTask.resume()
    }
    
    
    /*
     broadcast chat history message with fileURL
     */
    func broadcastChatHistory(chatMessage: DolphinChatHistory, filename: String, accountName: String, state: String) {
        var attachmentUrl: String = baseUrl
        if accountName != dolphinProfile?.name {
            attachmentUrl = attachmentUrl+"/webchat/out/\(state)/"+filename+"?access_token=\(access_token)"
        } else{
            attachmentUrl = attachmentUrl+"/webchat/in/\(state)/"+filename+"?access_token=\(access_token)"
        }
        let dolphinMessage: DolphinMessage = DolphinMessage.parsingHistoryToMessage(chatMessage: chatMessage, filename: filename, attachmentUrl: attachmentUrl, state: state)
        NotificationCenter.default.post(name: Notification.Name(rawValue: notificationMessage), object: dolphinMessage)
    }
    
    
    /*
     Subscribe topic message after connected to websocket
     */
    func subscribeMessage() {
        wsMessage = self.topic_messageEndpoint + token
        let id = wsMessage
        let ack = wsMessage
        let headers = ["accessToken": access_token, "ack" : ack!, "id" : id! ]
        socketClient.subscribeWithHeader(destination: wsMessage!, withHeader: headers)
    }
    
    
    /*
     Unsubscribe message topic
     */
    public func unsubscribeMessage() {
        print("current ws \(wsMessage ?? "")")
        socketClient.unsubscribe(destination: wsMessage!)
    }


    /*
     Subscribe ACK to get condition response from server
     */
    func subscribeTransaction() {
        wsAck = topic_ACK+access_token
        let id = wsAck
        let headers = ["ack": "client",
                       "id" : id,
                       "accessToken" : access_token]
        socketClient.subscribeWithHeader(destination: wsAck, withHeader: headers)
    }
    
    
    /*
     Override function
     Receive message from websocket for every error happened in websocket
     */
    public func serverDidSendError(client: StompClientLib!, withErrorMessage description: String, detailedErrorMessage message: String?) {
        print("serverDidSEndError")
        NotificationCenter.default.post(name: Notification.Name(rawValue: notificationConnectionStatus), object: 5)
    }
    
    
    /*
     Override function
     send ping request to server
     */
    public func serverDidSendPing() {
        print("server ping")
    }
    
    
    /*
     On send text message to web socket
     */
    public func onSendMessage(messages: String, dataUser: AnyObject? = nil){
        
        var jsonString: Data?
        
        if dataUser != nil {
            jsonString = convertDataToJson(data: dataUser as Any)
        }
         
        let messageItem = DolphinMessage()
        let tx = String(Int(NSDate().timeIntervalSince1970))
        messageItem.token = token
        messageItem.message = messages
        messageItem.transactionId = tx
        messageItem.messageHash = messages.md5()
        messageItem.sessionId = sessionId!
        messageItem.isUser = true
        messageItem.state = "message"
        messageItem.agentName = dolphinProfile!.name!
        messageItem.preCustomVar = jsonString
        
        if(isShowTriggerMenu == false && messages == triggerMenuMessage){
            //skip
        } else{
            NotificationCenter.default.post(name: Notification.Name(rawValue: notificationMessage), object: messageItem)
        }
        onSend(message: messageItem)
    }
    
    
    /*
     Send attachment (file, image, video, and audio) to server
     Response - Send broadcast UI message to app
                Send message to server
     */
    public func sendAttachment(fileNsUrl: NSURL?, state: String, dataUser: AnyObject? = nil) {
        let log = OSLog(subsystem: subsystem, category: "Send Attachment")
        var jsonString: Data?
        
        if dataUser != nil {
            jsonString = convertDataToJson(data: dataUser as Any)
        }
        
        let mediaImage: DolphinMessage = preRenderFileMessage(fileNsUrl: fileNsUrl!, state: state)
        let url = URL(string: "\(baseUrl)/webchat/upload")
        
        ApiService.sendAttachmentMessage(url: url!, fileNsURL: fileNsUrl!, state: state, accessToken: access_token, sessionId: sessionId!) { [self] fileResponse, stringResponse, error in
            
            if fileResponse != nil {
                mediaImage.attFilepath = fileResponse?.filepath
                mediaImage.attFilename = fileResponse?.filename
                mediaImage.attFiletype = fileResponse?.fileType
                mediaImage.attUrl = getAttachmentURL(fileResponse: fileResponse!)
                mediaImage.preCustomVar = jsonString
                onSend(message: mediaImage)
                
            } else if stringResponse != nil {
                if stringResponse!.contains(Constant.cannotUpload){
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: notificationConnectionStatus), object: 7)
                    }
                } else{
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: notificationConnectionStatus), object: 6)
                    }
                }
            } else{
                os_log("Failed send attachment with error : %@", log: log, type: .error, error.debugDescription)
            }
        }
        
    }
    
    
    /*
     convert anyobject (map) to data json
     */
    public func convertDataToJson(data: Any)-> Data? {
        do {
            return try! JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    /*
     Get attachment URL after receiving from minio response
     */
    public func getAttachmentURL(fileResponse: FileResponse)-> String {
        let state = fileResponse.fileType!.getFileType()
        return "\(baseUrl)/webchat/in/\(state)/\(fileResponse.filename!)"
    }
    
    
    /*
     On send every message to server (message and file)
     */
    public func onSend(message: DolphinMessage) {
        
        if message.preCustomVar != nil {
            message.customVariables = parsingDataUserInformation(dataUser: message.preCustomVar!)
        }
        do {
            let headers = [
                "accessToken": self.access_token,
                "transaction": message.transactionId!,
                "content-type": "application/json",
            ]
            
            AESEncryption.doEncrypt(clientSecret: clientSecrect,message: message, accessToken: self.access_token);
             
            let jsonObj = try JSONEncoder().encode(message)
            let jsonBody = String(data: jsonObj,encoding: .utf8)
            
            /// Websocket send message
            socketClient.begin(transactionId: message.transactionId!)
            socketClient.sendMessage(
                message: jsonBody ?? "",
                toDestination: self.destinationUrl,
                withHeaders: headers,
                withReceipt: nil
            )
            socketClient.commit(transactionId: message.transactionId!)
        } catch {
            print("Error send message")
        }
    }
    
    
    /*
     parsing data from precustom variable to json string
     */
    public func parsingDataUserInformation(dataUser: Data)-> String? {
        
        var result: String?
        
        do {
            let decoded = try JSONSerialization.jsonObject(with: dataUser, options: [])
            
            let decodedFromJson =  decoded as? [String : String]
            let dataMapUser = [
                    ["gpsLocation" : decodedFromJson!["gpsLocation"]],
                    ["networkName" : decodedFromJson!["networkName"]],
                    ["networkMode" : decodedFromJson!["networkMode"]],
                    ["signalStrength" : decodedFromJson!["signalStrength"]],
                    ["ipAddress" : decodedFromJson!["ipAddress"]],
                    ["apn" : decodedFromJson!["apn"]],
                    ["os" : decodedFromJson!["os"]],
                    ["noAxis" : decodedFromJson!["noAxis"]],
                    ["email" : decodedFromJson!["email"]],
                    ["category" : decodedFromJson!["category"]],
                    ["imsi" : decodedFromJson!["imsi"]],
                    ["mcc" : decodedFromJson!["mcc"]],
                    ["mnc" : decodedFromJson!["mnc"]],
                    ["lac" : decodedFromJson!["lac"]],
                    ["cellId" : decodedFromJson!["cellId"]],
                    ["deviceInfo" : decodedFromJson!["deviceInfo"]],
                    
                ]
            
           result = convertDataToJsonString(arrayData: dataMapUser)
            
        } catch {
            print(error.localizedDescription)
        }
        
       return result
    }
    
    
    /*
     convert map to json string
     */
    public func convertDataToJsonString(arrayData: Any)-> String {
        var json: String = ""
        
        do {
            let jsonData: Data = try JSONSerialization.data(withJSONObject: arrayData, options: [])
            if  let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue) {
                json = jsonString as String
                print(json)
            }
        } catch let error as NSError {
            print("Array convertIntoJSON - \(error.description)")
            }
        return json
    }
    
    
    
    /*
     Build prerender file message before sending to server
     Broadcast Notification file message to App
     */
    public func preRenderFileMessage(fileNsUrl: NSURL, state: String) -> DolphinMessage {
    
        let mediaMessage: DolphinMessage = DolphinMessage()
        
        mediaMessage.attUrl = fileNsUrl.absoluteString
        mediaMessage.token = token
        mediaMessage.outbound = false
        mediaMessage.isUser = true
        let transactionId: String = String(Int(NSDate().timeIntervalSince1970))
        mediaMessage.transactionId = transactionId
        mediaMessage.sessionId = sessionId
        mediaMessage.agentName = dolphinProfile!.name!
        mediaMessage.attFiletype = state
        setIncomingFileTypeAndState(message: mediaMessage, state: state)
        NotificationCenter.default.post(name: Notification.Name(rawValue: notificationMessage), object: mediaMessage)
        return mediaMessage
    }

}


/*
 Extension for parsing filelink which received from chat history
 Response : filename
 */
extension String {
    
    func parsingData() -> String {
        let addQuotes = self.replacingOccurrences(of: "'", with: "\"", options: .literal)
        
        let data = addQuotes.data(using: String.Encoding.utf8)
        var dictonary:NSDictionary?
        do {
            dictonary =  try JSONSerialization.jsonObject(with: data!, options: [.allowFragments]) as? [String:AnyObject] as NSDictionary?
            
        } catch let error as NSError {
            print(error)
        }
        return dictonary!["filename"]! as! String
    }
    
    func truncateUrl()-> String{
        if self.starts(with: "http://") {
            let index = self.index(self.startIndex, offsetBy: 7)
            return String(self[index...])
        } else {
            let index = self.index(self.startIndex, offsetBy: 8)
            return String(self[index...])
        }
    }
    
    func getFileType()-> String{
        if self.contains(Connector.CONSTANT_TYPE_IMAGE){
            return Connector.CONSTANT_TYPE_IMAGE
        } else if self.contains(Connector.CONSTANT_TYPE_DOCUMENT) || self.contains( Connector.CONSTANT_TYPE_APPLICATION){
            return Connector.CONSTANT_TYPE_DOCUMENT
        } else if self.contains(Connector.CONSTANT_TYPE_VIDEO) || self.contains( Connector.CONSTANT_TYPE_OCTET_STREAM){
            return Connector.CONSTANT_TYPE_VIDEO
        } else {
            return Connector.CONSTANT_TYPE_AUDIO
        }
    }
    
}
