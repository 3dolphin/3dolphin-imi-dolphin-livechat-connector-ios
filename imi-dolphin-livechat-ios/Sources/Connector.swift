
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
     Initilisation connector
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
        
        ApiService.getAccessToken(url: url, token: token) { result, error in
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
        print("String Body : \(stringBody ?? "nil")")
        let data = Data(stringBody!.utf8)
        if destination.contains("/topic/ack") {
            print("ack response server")
        } else {
            do{
                let onReceivingMessage: DolphinMessage = try JSONDecoder().decode(DolphinMessage.self, from: data)
                let msgDecrypted = AESEncryption.doDecrypt(clientSecret: clientSecrect, accessToken: access_token, messageToDec: onReceivingMessage)
                
                if msgDecrypted != nil {
                    if msgDecrypted!.token != nil {
                        if msgDecrypted?.message == nil && msgDecrypted!.event == nil {
                            token = msgDecrypted!.token!
                            if msgDecrypted?.sessionId != nil {
                                sessionId = msgDecrypted?.sessionId
                                DispatchQueue.main.async { [self] in
                                    NotificationCenter.default.post(name: Notification.Name(rawValue: notificationConnectionStatus), object: 2)
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
                print("Failed to load: \(error.localizedDescription)")
            }
        }
        
    }
    
    /*
     Set event for every received message
     Response : DolphineMessage with event disconnect, read, typing and incoming
     */
    public func setEvent(msgDecriypted: DolphinMessage) {
        DispatchQueue.main.async { [self] in
            if msgDecriypted.event == "diconnect" {
                print("User is disconnected")
                NotificationCenter.default.post(name: Notification.Name(rawValue: notificationConnectionStatus), object: 5)
            } else if msgDecriypted.event == "read" {
                print("read")
                NotificationCenter.default.post(name: Notification.Name(rawValue: notificationReadMessage), object: msgDecriypted)
            } else if msgDecriypted.event == "typing" {
                print("typing")
                NotificationCenter.default.post(name: Notification.Name(rawValue: notificationTypingCondition), object: msgDecriypted)
            } else if msgDecriypted.event == "unassigned" {
                print("unassigned")
            } else {
                incomingMessage(incomingMsg: msgDecriypted)
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
        print("stompClientDidDisconnect")
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
        if !(dolphinProfile!.customerId == "") {
            socialid = dolphinProfile!.customerId!}
        let url = URL(string: baseUrl+"/webchat/conversation?contactid=\(socialid)&access_token=\(access_token)")!
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10)
        request.httpMethod = "GET"
        /// Call api request
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
                        var attachmentUrl: String = baseUrl
                        if chatMessage.documentLink != nil {
                            let filename = chatMessage.documentLink!.parsingData()
                            if chatMessage.accountName != dolphinProfile?.name {
                                attachmentUrl = attachmentUrl+"/webchat/out/document/"+filename+"?access_token=\(access_token)"
                            } else{
                                attachmentUrl = attachmentUrl+"/webchat/in/document/"+filename+"?access_token=\(access_token)"
                            }
                            let dolphinMessage: DolphinMessage = DolphinMessage.parsingHistoryToMessage(chatMessage: chatMessage, filename: filename, attachmentUrl: attachmentUrl, state: Connector.CONSTANT_TYPE_DOCUMENT)
                            NotificationCenter.default.post(name: Notification.Name(rawValue: notificationMessage), object: dolphinMessage)
                        } else if chatMessage.videoLink != nil {
                            let filename = chatMessage.videoLink!.parsingData()
                            if chatMessage.accountName != dolphinProfile?.name {
                                attachmentUrl = attachmentUrl+"/webchat/out/video/"+filename+"?access_token=\(access_token)"
                            } else{
                                attachmentUrl = attachmentUrl+"/webchat/in/video/"+filename+"?access_token=\(access_token)"
                            }
                            let dolphinMessage: DolphinMessage = DolphinMessage.parsingHistoryToMessage(chatMessage: chatMessage, filename: filename, attachmentUrl: attachmentUrl, state: Connector.CONSTANT_TYPE_VIDEO)
                            NotificationCenter.default.post(name: Notification.Name(rawValue: notificationMessage), object: dolphinMessage)
                        } else if chatMessage.audioLink != nil {
                            let filename = chatMessage.audioLink!.parsingData()
                            if chatMessage.accountName != dolphinProfile?.name {
                                attachmentUrl = attachmentUrl+"/webchat/out/audio/"+filename+"?access_token=\(access_token)"
                            } else{
                                attachmentUrl = attachmentUrl+"/webchat/in/audio/"+filename+"?access_token=\(access_token)"
                            }
                            let dolphinMessage: DolphinMessage = DolphinMessage.parsingHistoryToMessage(chatMessage: chatMessage, filename: filename, attachmentUrl: attachmentUrl, state: Connector.CONSTANT_TYPE_AUDIO)
                            NotificationCenter.default.post(name: Notification.Name(rawValue: notificationMessage), object: dolphinMessage)
                        } else if chatMessage.pictureLink != nil {
                            let filename = chatMessage.pictureLink!.parsingData()
                            if chatMessage.accountName != dolphinProfile?.name {
                                attachmentUrl = attachmentUrl+"/webchat/out/image/"+filename+"?access_token=\(access_token)"
                            } else{
                                attachmentUrl = attachmentUrl+"/webchat/in/image/"+filename+"?access_token=\(access_token)"
                            }
                            let dolphinMessage: DolphinMessage = DolphinMessage.parsingHistoryToMessage(chatMessage: chatMessage, filename: filename, attachmentUrl: attachmentUrl, state: Connector.CONSTANT_TYPE_IMAGE)
                            NotificationCenter.default.post(name: Notification.Name(rawValue: notificationMessage), object: dolphinMessage)
                        }
                    }
                 }
            }
        })
        dataTask.resume()
    }
    
    
    /*
     Subscribe topic message after connected to websocket
     */
    func subscribeMessage() {
        wsMessage = self.topic_messageEndpoint + token
        let id = wsMessage
        let ack = wsMessage
        let headers = ["accessToken": access_token, "ack" : ack!, "id" : id! ]
        
        /*
         Start subscribe with header
         */
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
        /*
         Subscribe ACK with header
         */
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
        
        var jsonString: Data?
        
        if dataUser != nil {
            jsonString = convertDataToJson(data: dataUser as Any)
        }
        
        let mediaImage: DolphinMessage = preRenderFileMessage(fileNsUrl: fileNsUrl!, state: state)
        let url = URL(string: "\(baseUrl)/webchat/upload")
        // generate boundary string using a unique per-app string
        let boundary = "--------------\(UUID().uuidString)"
        let session = URLSession.shared
        let mimeType = getMimeByState(state: state)
        var data: Data = convertToDataByMime(fileNsUrl: fileNsUrl!, mimeType: mimeType)
        let fileName: String = (fileNsUrl?.lastPathComponent)!
        // Set the URLRequest to POST and to the specified URL
        var urlRequest = URLRequest(url: url!)
        urlRequest.httpMethod = "POST"

        // Set Content-Type Header to multipart/form-data, this is equivalent to submitting form data with file upload in a web browser
        // And the boundary is also set here
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(access_token)", forHTTPHeaderField: "Authorization")

        // Add the image data to the raw http request data
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("content-disposition: form-data; name=\"attachment\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        data.append(data)
    
        // Add the image data to the raw http request data
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("content-disposition: form-data; name=\"sessionId\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(String(describing: sessionId))\r\n".data(using: .utf8)!)
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Send a POST request to the URL, with the data we created earlier
        session.uploadTask(with: urlRequest, from: data, completionHandler: { [self] responseData, response, error in
            if error != nil {
                print(error as Any)
            }
            if let response = response as? HTTPURLResponse {
                print("statusCode: \(response.statusCode)")
            }
            guard let responseData = responseData else {
                print("no response data")
                return
            }
            if let responseString = String(data: responseData, encoding: .utf8){
                if responseString.contains("You can not upload") {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: notificationConnectionStatus), object: 7)
                    }
                } else {
                    let decodedData = Data(base64Encoded: responseString)
                    do {
                        let jsonObject = try JSONSerialization.jsonObject(with: decodedData!, options: .allowFragments) as! NSDictionary

                        if(jsonObject["message"] != nil){
                            if(jsonObject["message"] as! String == "Filesize limit exceeded"){
                                DispatchQueue.main.async {
                                    NotificationCenter.default.post(name: Notification.Name(rawValue: notificationConnectionStatus), object: 6)
                                }
                            }
                        } else{
                            mediaImage.attFilepath = (jsonObject["filepath"] as! String)
                            mediaImage.attFilename = (jsonObject["filename"] as! String)
                            mediaImage.attFiletype = (jsonObject["filetype"] as! String)
                            mediaImage.attUrl = getAttachmentURL(json: jsonObject)
                            mediaImage.preCustomVar = jsonString
                            onSend(message: mediaImage)
                            print(jsonObject)
                        }
                    } catch let parsingError {
                        print("Error", parsingError)
                    }
                }
            }
        }).resume()
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
     Convert data file to mime
     */
    public func convertToDataByMime(fileNsUrl: NSURL,  mimeType: String)->Data {
        
        var resData = Data()
        do {
            resData = try Data(contentsOf: fileNsUrl as URL)
        } catch {
            print("Error to convert data")
        }
        return resData
    }
    
    
    /*
     Set mime type by state from APP
     */
    public func getMimeByState(state: String)-> String {
        if state == Connector.CONSTANT_TYPE_IMAGE{
            return Connector.CONSTANT_TYPE_IMAGE
        } else if state == Connector.CONSTANT_TYPE_DOCUMENT {
            return Connector.CONSTANT_TYPE_DOCUMENT
        } else if state == Connector.CONSTANT_TYPE_AUDIO{
            return Connector.CONSTANT_TYPE_AUDIO
        } else {
            return Connector.CONSTANT_TYPE_VIDEO
        }
    }
    
    
    /*
     Get attachment URL after receiving from minio response
     */
    public func getAttachmentURL(json: NSDictionary)-> String {
        
        var type: String = json["filetype"] as! String
        var filename: String = json["filename"] as! String
        
        if type.starts(with: Connector.CONSTANT_TYPE_IMAGE ) {
            type = Connector.CONSTANT_TYPE_IMAGE
        } else if type.starts(with: Connector.CONSTANT_TYPE_DOCUMENT) {
            type = Connector.CONSTANT_TYPE_DOCUMENT
        } else if type.starts(with: Connector.CONSTANT_TYPE_AUDIO){
            type = Connector.CONSTANT_TYPE_AUDIO
        } else if type.starts(with: Connector.CONSTANT_TYPE_VIDEO) {
            type = Connector.CONSTANT_TYPE_VIDEO
        }
        
        filename = filename.replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
        
        print(" URLNYA : \(baseUrl)/webchat/in/\(type)/\(filename)")
        return "\(baseUrl)/webchat/in/\(type)/\(filename)"
        
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
        
        if state == Connector.CONSTANT_TYPE_IMAGE {
            setIncomingFileTypeAndState(message: mediaMessage, state: Connector.CONSTANT_TYPE_IMAGE)
        } else if state == Connector.CONSTANT_TYPE_DOCUMENT {
            setIncomingFileTypeAndState(message: mediaMessage, state: Connector.CONSTANT_TYPE_DOCUMENT)
        } else if state == Connector.CONSTANT_TYPE_AUDIO {
            setIncomingFileTypeAndState(message: mediaMessage, state: Connector.CONSTANT_TYPE_AUDIO)
        } else if state == Connector.CONSTANT_TYPE_VIDEO {
            setIncomingFileTypeAndState(message: mediaMessage, state: Connector.CONSTANT_TYPE_VIDEO)
        }
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
    
}




// MARK: - Encode/decode helpers

public class JSONNull: Codable, Hashable {

    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
        return true
    }

    public var hashValue: Int {
        return 0
    }

    public func hash(into hasher: inout Hasher) {
        // No-op
    }

    public init() {}

    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

class JSONCodingKey: CodingKey {
    let key: String

    required init?(intValue: Int) {
        return nil
    }
    required init?(stringValue: String) {
        key = stringValue
    }
    var intValue: Int? {
        return nil
    }
    var stringValue: String {
        return key
    }
}

public class JSONAny: Codable {

    public let value: Any

    static func decodingError(forCodingPath codingPath: [CodingKey]) -> DecodingError {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode JSONAny")
        return DecodingError.typeMismatch(JSONAny.self, context)
    }

    static func encodingError(forValue value: Any, codingPath: [CodingKey]) -> EncodingError {
        let context = EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode JSONAny")
        return EncodingError.invalidValue(value, context)
    }

    static func decode(from container: SingleValueDecodingContainer) throws -> Any {
        if let value = try? container.decode(Bool.self) {
            return value
        }
        if let value = try? container.decode(Int64.self) {
            return value
        }
        if let value = try? container.decode(Double.self) {
            return value
        }
        if let value = try? container.decode(String.self) {
            return value
        }
        if container.decodeNil() {
            return JSONNull()
        }
        throw decodingError(forCodingPath: container.codingPath)
    }

    static func decode(from container: inout UnkeyedDecodingContainer) throws -> Any {
        if let value = try? container.decode(Bool.self) {
            return value
        }
        if let value = try? container.decode(Int64.self) {
            return value
        }
        if let value = try? container.decode(Double.self) {
            return value
        }
        if let value = try? container.decode(String.self) {
            return value
        }
        if let value = try? container.decodeNil() {
            if value {
                return JSONNull()
            }
        }
        if var container = try? container.nestedUnkeyedContainer() {
            return try decodeArray(from: &container)
        }
        if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self) {
            return try decodeDictionary(from: &container)
        }
        throw decodingError(forCodingPath: container.codingPath)
    }

    static func decode(from container: inout KeyedDecodingContainer<JSONCodingKey>, forKey key: JSONCodingKey) throws -> Any {
        if let value = try? container.decode(Bool.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Int64.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Double.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(String.self, forKey: key) {
            return value
        }
        if let value = try? container.decodeNil(forKey: key) {
            if value {
                return JSONNull()
            }
        }
        if var container = try? container.nestedUnkeyedContainer(forKey: key) {
            return try decodeArray(from: &container)
        }
        if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key) {
            return try decodeDictionary(from: &container)
        }
        throw decodingError(forCodingPath: container.codingPath)
    }

    static func decodeArray(from container: inout UnkeyedDecodingContainer) throws -> [Any] {
        var arr: [Any] = []
        while !container.isAtEnd {
            let value = try decode(from: &container)
            arr.append(value)
        }
        return arr
    }

    static func decodeDictionary(from container: inout KeyedDecodingContainer<JSONCodingKey>) throws -> [String: Any] {
        var dict = [String: Any]()
        for key in container.allKeys {
            let value = try decode(from: &container, forKey: key)
            dict[key.stringValue] = value
        }
        return dict
    }

    static func encode(to container: inout UnkeyedEncodingContainer, array: [Any]) throws {
        for value in array {
            if let value = value as? Bool {
                try container.encode(value)
            } else if let value = value as? Int64 {
                try container.encode(value)
            } else if let value = value as? Double {
                try container.encode(value)
            } else if let value = value as? String {
                try container.encode(value)
            } else if value is JSONNull {
                try container.encodeNil()
            } else if let value = value as? [Any] {
                var container = container.nestedUnkeyedContainer()
                try encode(to: &container, array: value)
            } else if let value = value as? [String: Any] {
                var container = container.nestedContainer(keyedBy: JSONCodingKey.self)
                try encode(to: &container, dictionary: value)
            } else {
                throw encodingError(forValue: value, codingPath: container.codingPath)
            }
        }
    }

    static func encode(to container: inout KeyedEncodingContainer<JSONCodingKey>, dictionary: [String: Any]) throws {
        for (key, value) in dictionary {
            let key = JSONCodingKey(stringValue: key)!
            if let value = value as? Bool {
                try container.encode(value, forKey: key)
            } else if let value = value as? Int64 {
                try container.encode(value, forKey: key)
            } else if let value = value as? Double {
                try container.encode(value, forKey: key)
            } else if let value = value as? String {
                try container.encode(value, forKey: key)
            } else if value is JSONNull {
                try container.encodeNil(forKey: key)
            } else if let value = value as? [Any] {
                var container = container.nestedUnkeyedContainer(forKey: key)
                try encode(to: &container, array: value)
            } else if let value = value as? [String: Any] {
                var container = container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
                try encode(to: &container, dictionary: value)
            } else {
                throw encodingError(forValue: value, codingPath: container.codingPath)
            }
        }
    }

    static func encode(to container: inout SingleValueEncodingContainer, value: Any) throws {
        if let value = value as? Bool {
            try container.encode(value)
        } else if let value = value as? Int64 {
            try container.encode(value)
        } else if let value = value as? Double {
            try container.encode(value)
        } else if let value = value as? String {
            try container.encode(value)
        } else if value is JSONNull {
            try container.encodeNil()
        } else {
            throw encodingError(forValue: value, codingPath: container.codingPath)
        }
    }

    public required init(from decoder: Decoder) throws {
        if var arrayContainer = try? decoder.unkeyedContainer() {
            self.value = try JSONAny.decodeArray(from: &arrayContainer)
        } else if var container = try? decoder.container(keyedBy: JSONCodingKey.self) {
            self.value = try JSONAny.decodeDictionary(from: &container)
        } else {
            let container = try decoder.singleValueContainer()
            self.value = try JSONAny.decode(from: container)
        }
    }

    public func encode(to encoder: Encoder) throws {
        if let arr = self.value as? [Any] {
            var container = encoder.unkeyedContainer()
            try JSONAny.encode(to: &container, array: arr)
        } else if let dict = self.value as? [String: Any] {
            var container = encoder.container(keyedBy: JSONCodingKey.self)
            try JSONAny.encode(to: &container, dictionary: dict)
        } else {
            var container = encoder.singleValueContainer()
            try JSONAny.encode(to: &container, value: self.value)
        }
    }
}


