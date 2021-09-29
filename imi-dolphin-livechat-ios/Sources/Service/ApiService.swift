//
//  ApiService.swift
//  imi-dolphin-livechat-ios
//
//  Created by Jhoan River S on 28/09/21.
//

import Foundation


public class ApiService {
    
    /*
     Access token API api sevice function
     */
    public static func getAccessToken(url: URL, token: String, completionHandler: @escaping (TokenModel?, Error?) -> ()) {
        
        var request = URLRequest(url: url,
                                 cachePolicy: .useProtocolCachePolicy,
                                 timeoutInterval: 10)

        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Basic \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in

            guard error == nil else {
                return
            }
            guard let data = data else {
                return
            }
            do {
                let tokenModel = try! JSONDecoder().decode(TokenModel.self, from: data)
                completionHandler(tokenModel, nil)
            } catch {
                // error Trying to convert JSON data to string
                completionHandler(nil, error)
                return
            }
        }).resume()

    }
    

    
    /*
     Refresh token API service function
     */
    public static func getRefreshToken(url : URL, token: String, completionHandler: @escaping (TokenModel?, Error?) -> ()) {
        var request = URLRequest (url: url, cachePolicy: .useProtocolCachePolicy,
                                  timeoutInterval: 10)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Basic \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            
            guard error == nil else {
                return
            }
            guard let data = data else {
                return
            }
            
            do {
                let tokenModel = try! JSONDecoder().decode(TokenModel.self, from: data)
                completionHandler(tokenModel, nil)
            } catch {
                completionHandler(nil, error)
                return
            }
        }).resume()
        
    }
    
    
    /*
     SendAttachment API service function
     */
    
    public static func sendAttachmentMessage(url: URL, fileNsURL: NSURL, state: String, accessToken: String, sessionId: String, completionHandler: @escaping (FileResponse?, String?, Error?) -> ()) {
        
        // generate boundary string using a unique per-app string
        let boundary = "--------------\(UUID().uuidString)"
        let session = URLSession.shared
        let mimeType = state.getFileType()
        var data: Data = convertToDataByMime(fileNsUrl: fileNsURL)
        let fileName: String = (fileNsURL.lastPathComponent)!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

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
            guard error == nil else {
                return
            }
            guard let responseData = responseData else {
                print("no response data")
                return
            }
            if let responseString = String(data: responseData, encoding: .utf8){
                if responseString.contains(Constant.cannotUpload) {
                    completionHandler(nil, Constant.cannotUpload, nil)
                } else {
                    let decodedData = Data(base64Encoded: responseString)
                    do {
                        let jsonObject = try JSONSerialization.jsonObject(with: decodedData!, options: .allowFragments) as! NSDictionary

                        if(jsonObject["message"] != nil){
                            if(jsonObject["message"] as! String == Constant.limitedExceeded){
                                completionHandler(nil, Constant.limitedExceeded, nil)
                            }
                        } else{
                            let fileResponse: FileResponse = FileResponse(
                                fileType:  (jsonObject["filetype"] as! String),
                                filename: (jsonObject["filename"] as! String),
                                status: (jsonObject["status"] as! String),
                                filepath: (jsonObject["filepath"] as! String)
                            )
                            completionHandler(fileResponse, nil, nil)
                        }
                    } catch {
                        completionHandler(nil, nil, error)
                    }
                }
            }
        }).resume()
        
    }
    
    
    /*
     Convert data file to mime
     */
    public static func convertToDataByMime(fileNsUrl: NSURL)->Data {
        var resData = Data()
        do {
            resData = try Data(contentsOf: fileNsUrl as URL)
        } catch {
            print("Error to convert data")
        }
        return resData
    }
    
    
    
    
    
}
