// Ravelry Connector - to help connecting with the Ravelry API: https://www.ravelry.com/api
// (C) 2022 by Marco Nissen

import Foundation
import OAuthSwift

public extension RavelryEnvironment {
    func createQueuedProject(username: String,
                             data: OAuthSwift.Parameters,
                             completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        postSimpleRequest(url: "\(baseURI)/people/\(username)/queue/create.json", parameters: data, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func deleteQueue(username: String, identifier: Int, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        deleteSimpleRequest(url: "\(baseURI)/people/\(username)/queue/\(identifier).json", completedRequest: completedRequest)
    }

    func getQueuedProjects(username: String, pattern_id: String?, query: String, query_type: String?, page: Int, page_size: Int,
                           completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["pattern_id"] = pattern_id
        parameters["query_type"] = query_type
        parameters["query"] = query
        parameters["page"] = page
        parameters["page_size"] = page_size

        getPaginatedRequest(resultsKey: "queued_projects", url: "\(baseURI)/people/\(username)/queue/list.json", parameters: parameters, username: username, completedRequest: completedRequest)
    }

    func getOrderOfQueuedProjects(username: String, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/people/\(username)/queue/order.json", completedRequest: completedRequest)
    }

    func repositionQueuedProject(username: String,
                                 identifier: Int,
                                 insert_at: Int,
                                 completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["insert_at"] = insert_at
        postSimpleRequest(url: "\(baseURI)/people/\(username)/queue/\(identifier)/reposition.json", parameters: parameters, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func showQueuedProject(username: String, identifier: Int,
                           completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/people/\(username)/queue/\(identifier).json", completedRequest: completedRequest)
    }

    func updateQueuedProject(username: String,
                             identifier: Int,
                             data: OAuthSwift.Parameters,
                             completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        postSimpleRequest(url: "\(baseURI)/people/\(username)/queue/\(identifier)/update.json", parameters: data, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }
}
