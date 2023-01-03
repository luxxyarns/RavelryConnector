// Ravelry Connector - to help connecting with the Ravelry API: https://www.ravelry.com/api
// (C) 2022 by Marco Nissen

import Foundation
import OAuthSwift

public extension RavelryEnvironment {
    func createComment(type: String,
                       commented_id: Int,
                       body: String,
                       reply_to_id: Int,
                       completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["type"] = type
        parameters["commented_id"] = commented_id
        parameters["body"] = body
        parameters["reply_to_id"] = reply_to_id
        postSimpleRequest(url: "\(baseURI)/comments/create.json", parameters: parameters, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }
    
    func deleteComment(identifier: Int, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        deleteSimpleRequest(url: "\(baseURI)/comments/\(identifier).json", completedRequest: completedRequest)
    }
    
    func getComments(username: String, page: Int, page_size: Int,
                     completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["page"] = page
        parameters["page_size"] = page_size
        
        getPaginatedRequest(resultsKey: "comments", url: "\(baseURI)/people/\(username)/comments/list.json", parameters: parameters, username: username, completedRequest: completedRequest)
    }
}
