# 3Dolphin Live Chat Connector IOS



## Requirement


- **XCode 10.0 +**
- **XCode 12.1 +**
- **Swift 4.0, Swift 4.1, Swift 4.2, Swift 5.0**

## Installation

#### Cocoapods

```swift
pod "imi-dolphin-livechat-ios"
```

If any issues happened or class couldn't be called, I recommend you to import library manually to your project app. after you clone this lib 
1. add **imi-dolphin-livechat-ios.xcodeproj** to your project app
2. add **pod "StompClientLib"** and pod **"CryptoSwift", '~> 1.3.8'** to your Podfile


## Usage

```swift
import imi-dolphin-livechat-ios
```

#### In App Usage

- Initialise user profile object : DolphinpProfile (Available in lib)

```swift
let dolphinProfile = DolphinProfile(
            name: nameTextField.text!,
            email: emailTextField.text!,
            phoneNumber: phoneTextField.text!,
            customerId: "",
            uid: "12345"
        )
```

- Initialise **BaseUrl** (String), **clientId** (String) and **clientSecret** (String)

- Initialise connection variable and notification listener

```swift
var connector: Connector?
let notificationMessage = "com.connector.notificationMessage"
let notificationConnectionStatus = "com.connector.connectionStatus"
let notificationReadMessage = "com.connector.notificationReadMessage"
let notificationTypingCondition = "com.connector.notificationTypingCondition"

```

- Inside *viewDidLoad* function, setup profile, connection, and Notification center

```swift
connector = Connector.shared
connector!.setupConnection(baseUrl: baseUrl, clientId: clientId, clientSecrect: clientSecrect)
connector?.enableGetQueue(isEnable: false)
connector!.constructConnector(profile: dolphinProfile!)

NotificationCenter.default.addObserver(self, selector: #selector(doOnReceiveMessage(_:)), name: Notification.Name(rawValue: notificationMessage), object: nil)
NotificationCenter.default.addObserver(self, selector: #selector(doUpdateConnectionStatus(_:)), name: Notification.Name(rawValue: notificationConnectionStatus), object: nil)
NotificationCenter.default.addObserver(self, selector: #selector(doUpdateStatusMessage(_:)), name: Notification.Name(rawValue: notificationReadMessage), object: nil)
NotificationCenter.default.addObserver(self, selector: #selector(doUpdateTypingCondition(_:)), name: Notification.Name(rawValue: notificationTypingCondition), object: nil)

```

> setupConnection -> adjust baseUrl, client and client secret.
> enableGetQueue -> enabling get chat conversation history.
> contructConnector -> Start connecting to ws, with user profile to web socket.


- Initialise Function for every NotificationCenter function

```swift
 
    @objc func doOnReceiveMessage(_ notification: NSNotification) {
        let newMessage = notification.object as! DolphinMessage
        
        //Incoming param : "DolphinMessage"
        // this is your code when receive message from server
    }
    
    @objc func doUpdateConnectionStatus(_ notification: NSNotification) {
        let status: Int = notification.object as! Int
        // Incoming param : "Int"
        // 1. Connecting
        // 2. Connected
        // 3. Reconnecting
        // 4. Disconnected (when quit from chat)
        // 5. Disconnected (when something error from server)
        
    }
    
    @objc func doUpdateStatusMessage(_ notification: NSNotification){
        let updatedMessage = notification.object as! DolphinMessage
        // incoming param "DolphinMessage"
        // Do your code here, when you receive your message has been red
    }
    
    @objc func doUpdateTypingCondition(_ notification: NSNotification){
        /*
         Do your code here when agent ( customer service is typing message)
         */
    }

```
## Model Message

```swift
struct MessageModel {
    var text: String?
    var isAnswer: Bool?
    var name: String
    var createdDate: Date
    var mediaLink: String?
    var mediaType: String?
    var read: Bool?
    var transactionId: String?
    var state: String?
    var filename: String?
    
    init(text: String? = nil,
         isAnswer: Bool,
         name: String,
         createdDate: Date,
         mediaLink: String? = nil,
         mediaType: String? = nil,
         read: Bool? = nil,
         transactionId: String? = nil,
         state: String,
         filename: String? = nil
    ) {
        self.text = text
        self.isAnswer = isAnswer
        self.name = name
        self.createdDate = createdDate
        self.state = state
        self.mediaLink = mediaLink
        self.read = read
        self.transactionId = transactionId
        self.mediaType = mediaType
        self.filename = filename
    }
}

```

## On Send Message

Before sending messages, we used an object to save device information. This is optional variable which send some information about device info. 
But you can leave it nil. For example:

```swift
    var sample: AnyObject = [
        "gpsLocation" : "123123,-12312412",
        "email" : "halalteam@gmail.com"
    ] as AnyObject
```

- Send Text

```swift
connector?.onSendMessage(messages: "TEXT_MESSAGE_STRING", dataUser: sample)
```


- Send Image

Prerequisite when sending image

- Must be lower than 2mb
- Format PNG or JPEG
- ImageUrl is Filepath of image

```swift
connector!.sendAttachment(fileNsUrl: "IMAGE_FILEPATH", state: state!, dataUser: sample)
```


- Send Video

Prerequisite when sending video

- Must be lower than 2mb
- Currently format only MP4
- VideoUrl is filepath of video

```swift
connector!.sendAttachment(fileNsUrl: "VIDEO_FILEPATH", state: state!, dataUser: sample)
```

- Send Audio/Document

Prerequisite when sending video

- Must be lower than 2mb
- Currently format only PDF
- Audio/ Document is filepath of video

```swift
 connector?.sendAttachment(fileNsUrl: AUDIO/DOCUMENT_FILEPATH as NSURL, state: state!, dataUser: sample)
```


To see more detail about how to implement this library, you can see in Example folder
