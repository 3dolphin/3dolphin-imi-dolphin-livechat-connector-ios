//
//  ApiService.swift
//  imi-dolphin-livechat-ios
//
//  Created by Jhoan River S on 28/09/21.
//

import Foundation


public class ApiService {
    
    
    
    public static func getAccessToken(url: URL, token: String, completionHandler: @escaping (TokenModel?, Error?) -> Void) {
        
        var request = URLRequest(url: url,
                                 cachePolicy: .useProtocolCachePolicy,
                                 timeoutInterval: 10)
        
        
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Basic \(token)", forHTTPHeaderField: "Authorization")
        
        let dataTask = URLSession.shared.dataTask(with: request){ data, response, error in
            
            guard error == nil else {
                return
            }
            guard let data = data else {
                return
            }
            
            do {
                let dataJson: TokenModel = try! JSONDecoder().decode(TokenModel.self, from: data)
                completionHandler(dataJson, nil)
            } catch{
                // error Trying to convert JSON data to string
                completionHandler(nil, error)
                return
            }
        }.resume()
        
        
        
    }
    
    
    
    
    
    
}
