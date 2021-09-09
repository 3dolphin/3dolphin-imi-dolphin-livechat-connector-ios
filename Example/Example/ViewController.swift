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
    let baseUrl: String = "https://adapter.3dolphins.ai:31644"
    let clientId: String = "b7674391db9fce68390998c3c4865442"
    let clientSecrect: String = "d501b0b896247c1bb0b8644eaf33d6c7"

    

    var connector: Connector?

    var dolphinProfile: DolphinProfile = DolphinProfile(
    name: "huhui", email: "huhui@gmail.comn", phoneNumber: "0812345678", customerId: "", uid: "12345")
//
    override func viewDidLoad() {
        super.viewDidLoad()
        connector = Connector.shared
        connector?.connect(baseUrl: baseUrl, clientId: clientId, clientSecrect: clientSecrect)
        connector?.enableGetHistory(isEnable: true)
        connector?.constructConnector(profile: dolphinProfile)
    }


}

