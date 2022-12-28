import Foundation
import OAuthSwift

public extension RavelryEnvironment {
    func getFriendsActivity(username: String, activity_type_keys: String, page: Int, page_size: Int,
                            completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["activity_type_keys"] = activity_type_keys
        parameters["page"] = page
        parameters["page_size"] = page_size

        getPaginatedRequest(resultsKey: "activities", url: "\(baseURI)/people/\(username)/friends/activity.json", parameters: parameters, completedRequest: completedRequest)
    }

    func addFriend(username: String,
                   friend_user_id: Int,
                   completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["friend_user_id"] = friend_user_id
        postSimpleRequest(url: "\(baseURI)/people/\(username)/friends/create.json", parameters: parameters, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func removeFriend(username: String,
                      friendship_record_id: Int,
                      completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        let parameters = OAuthSwift.Parameters()
        postSimpleRequest(url: "\(baseURI)/people/\(username)/friends/\(friendship_record_id)/destroy.json", parameters: parameters, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func getFriends(username: String, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/people/\(username)/friends/list.json", completedRequest: completedRequest)
    }

    func searchPeople(query: String, sort: String, additionalParameters: [String: String]? = nil, page: Int, page_size: Int,
                      completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        if let a = additionalParameters {
            parameters = a
        }
        parameters["query"] = query
        parameters["sort"] = sort
        parameters["in"] = "all"
        parameters["page"] = page
        parameters["page_size"] = page_size

        getPaginatedRequest(resultsKey: "user", url: "\(baseURI)/people/search.json", parameters: parameters, completedRequest: completedRequest)
    }

    func showPerson(identifier: Int,
                    completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/people/\(identifier).json", completedRequest: completedRequest)
    }

    func showPerson(username: String,
                    completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/people/\(username).json", completedRequest: completedRequest)
    }

    func updatePerson(username: String,
                      data: OAuthSwift.Parameters,
                      completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        postSimpleRequest(url: "\(baseURI)/people/\(username).json", parameters: data, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func updatePerson(identifier: Int,
                      data: OAuthSwift.Parameters,
                      completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        postSimpleRequest(url: "\(baseURI)/people/\(identifier).json", parameters: data, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }
}
