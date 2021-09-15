//
//  ViewController.swift
//  Example
//
//  Created by Jhoan River S on 06/05/21.
//

import UIKit
import imi_dolphin_livechat_ios


let notificationMessage = "com.connector.notificationMessage"
let notificationConnectionStatus = "com.connector.connectionStatus"
let notificationReadMessage = "com.connector.notificationReadMessage"
let notificationTypingCondition = "com.connector.notificationTypingCondition"
class ViewController: UIViewController {

    
    
    /*
     setup url, clientId, and clientSecret before connection started
     */
    let baseUrl: String = "https://adapter.3dolphins.ai:31644"
    let clientId: String = "b7674391db9fce68390998c3c4865442"
    let clientSecrect: String = "d501b0b896247c1bb0b8644eaf33d6c7"

    
    
    
    
    

    var connector: Connector?

    var dolphinProfile: DolphinProfile = DolphinProfile(
    name: "huhui", email: "huhui@gmail.comn", phoneNumber: "0812345678", customerId: "", uid: "12345")
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        connector = Connector.shared
        connector?.connect(baseUrl: baseUrl, clientId: clientId, clientSecrect: clientSecrect)
        connector?.enableGetHistory(isEnable: true)
        connector?.constructConnector(profile: dolphinProfile)
        connector?.triggerMenu(message: "hallo")
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(doOnReceiveMessage(_:)), name: Notification.Name(rawValue: notificationMessage), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(doUpdateConnectionStatus(_:)), name: Notification.Name(rawValue: notificationConnectionStatus), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(doUpdateStatusMessage(_:)), name: Notification.Name(rawValue: notificationReadMessage), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(doUpdateTypingCondition(_:)), name: Notification.Name(rawValue: notificationTypingCondition), object: nil)
        
    }
    
    
    @objc func doOnReceiveMessage(_ notification: NSNotification) {
        let newMessage = notification.object as! DolphinMessage
        
        print(newMessage.message)
    }
    
    @objc func doUpdateConnectionStatus(_ notification: NSNotification) {
        let status: Int = notification.object as! Int

        switch status {
        case 1:
           print("Connecting")
        case 2:
            print("Connected")
        case 3:
           print("Reconnecting")
        case 4:
           print("Disconnected")
        case 6:
            print("Failed to send file caused of limited exceeded")
        case 7:
           print("You can not upload this kind of file!")
        default:
            print("Disconnected")
        }

    }
    
    
    @objc func doUpdateStatusMessage(_ notification: NSNotification){

        let updatedMessage = notification.object as! DolphinMessage
    }
    
    
    @objc func doUpdateTypingCondition(_ notification: NSNotification){
        /*
         response for typing condition by agent
         you can handle your layout about this typing
         */

    }


}

