//
//  ViewController.swift
//  Example
//
//  Created by Jhoan River S on 06/05/21.
//

import UIKit
import imi_dolphin_livechat_ios



class ViewController: UIViewController {

    
    
    /*
     setup url, clientId, and clientSecret before connection started
     */
    let baseUrl: String = "https://adapter.3dolphins.ai:31632"
    let clientId: String = "f181392d7b4f13ec1903d6359edf0cf2"
    let clientSecrect: String = "e61f8a33cba79b79c541586b944a25cd"

    

    var connector: Connector?

    var dolphinProfile: DolphinProfile = DolphinProfile(
    name: "huhui", email: "huhui@gmail.comn", phoneNumber: "0812345678", customerId: "", uid: "12345")
//
    override func viewDidLoad() {
        super.viewDidLoad()
        connector = Connector.shared
        connector?.setupConnection(baseUrl: baseUrl, clientId: clientId, clientSecrect: clientSecrect)
        connector?.enableGetQueue(isEnable: true)
        connector?.constructConnector(profile: dolphinProfile)
        
    }


}

