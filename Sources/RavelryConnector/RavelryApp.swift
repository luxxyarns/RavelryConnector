// Ravelry Connector - to help connecting with the Ravelry API: https://www.ravelry.com/api
// (C) 2022 by Marco Nissen
 
import Foundation
import OAuthSwift

public extension RavelryEnvironment {
    func deleteAppConfig(keys: String, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["keys"] = keys
        postSimpleRequest(url: "\(baseURI)/app/config/delete.json", parameters: parameters, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }
    
    func getAppConfig(keys: String, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["keys"] = keys
        getSimpleRequest(url: "\(baseURI)/app/config/get.json", parameters: parameters, completedRequest: completedRequest)
    }
    
    func setAppConfig(keyList: OAuthSwift.Parameters, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        postSimpleRequest(url: "\(baseURI)/app/config/set.json", parameters: keyList, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }
    
    func deleteAppData(keys: String, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["keys"] = keys
        postSimpleRequest(url: "\(baseURI)/app/data/delete.json", parameters: parameters, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }
    
    func getAppData(keys: String, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["keys"] = keys
        getSimpleRequest(url: "\(baseURI)/app/data/get.json", parameters: parameters, completedRequest: completedRequest)
    }
    
    func setAppData(keyList: OAuthSwift.Parameters, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        postSimpleRequest(url: "\(baseURI)/app/data/set.json", parameters: keyList, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }
    
    func getCountersForProject(identifier: Int, completedRequest: @escaping (_ json: [[String: Any]]?) -> Void) {
        let keystr = "s2g:kc-\(identifier)-counters"
        getAppData(keys: keystr) { results in
            if let r = results {
                if let data = r["data"] as? [String: Any] {
                    let x = data[keystr]
                    if let s = x as? String {
                        if let js = s.parseJSONString as? [String: Any] {
                            if let counters = js["counters"] as? [[String: Any]] {
                                completedRequest(counters)
                            }
                        }
                    } else {
                        completedRequest([[String: Any]]())
                    }
                }
            }
        }
    }
    
    func storeCountersForProject(identifier: Int, counters: [[String: Any]], completedRequest: @escaping (_ json: [[String: Any]]?) -> Void) {
        let keystr = "s2g:kc-\(identifier)-counters"
        var parameters = [String: Any]()
        do {
            let counterDict = ["counters": counters]
            let jsonData = try JSONSerialization.data(withJSONObject: counterDict, options: .prettyPrinted)
            let theJSONText = String(data: jsonData, encoding: .utf8)
            
            parameters[keystr] = theJSONText
            
            setAppData(keyList: parameters) { results in
                if let r = results {
                    if let data = r["data"] as? [String: Any] {
                        let x = data[keystr]
                        if let s = x as? String {
                            if let js = s.parseJSONString as? [String: Any] {
                                if let counters = js["counters"] as? [[String: Any]] {
                                    completedRequest(counters)
                                }
                            }
                        }
                    }
                }
            }
            
        } catch let err {
            print(err)
        }
    }
}
