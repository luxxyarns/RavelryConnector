import Foundation
import OAuthSwift

public extension RavelryEnvironment {
    func addFavoriteToBundle(username: String,
                             identifier: Int,
                             bundle_id: Int,
                             completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["bundle_id"] = bundle_id
        postSimpleRequest(url: "\(baseURI)/people/\(username)/favorites/\(identifier)/add_to_bundle.json", parameters: parameters, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func createFavorite(username: String,
                        data: OAuthSwift.Parameters,
                        completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        postSimpleRequest(url: "\(baseURI)/people/\(username)/favorites/create.json", parameters: data, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func deleteFavorite(username: String, identifier: Int, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        deleteSimpleRequest(url: "\(baseURI)/people/\(username)/favorites/\(identifier).json", completedRequest: completedRequest)
    }

    func getFavoriteList(username: String, types: [String], query: String, deep_search: Bool, page: Int, page_size: Int,
                         completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["types"] = types.joined(separator: " ")
        parameters["query"] = query
        parameters["deep_search"] = deep_search
        parameters["page"] = page
        parameters["page_size"] = page_size

        getPaginatedRequest(resultsKey: "favorites", url: "\(baseURI)/people/\(username)/favorites/list.json", parameters: parameters, username: username, completedRequest: completedRequest)
    }

    func getFavoriteList(username: String, types: [String], deep_search: Bool, tag: String, page: Int, page_size: Int,
                         completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["types"] = types.joined(separator: " ")

        parameters["deep_search"] = deep_search
        parameters["tag"] = tag
        parameters["page"] = page
        parameters["page_size"] = page_size

        getPaginatedRequest(resultsKey: "favorites", url: "\(baseURI)/people/\(username)/favorites/list.json", parameters: parameters, username: username, completedRequest: completedRequest)
    }

    func removeFavoriteFromBundle(username: String,
                                  identifier: Int,
                                  bundle_id: Int,
                                  completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["bundle_id"] = bundle_id
        postSimpleRequest(url: "\(baseURI)/people/\(username)/favorites/\(identifier)/remove_from_bundle.json", parameters: parameters, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func showFavorite(username: String, identifier: Int,
                      completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/people/\(username)/favorites/\(identifier).json",
                         completedRequest: completedRequest)
    }

    func updateFavorite(username: String,
                        identifier: Int,
                        data: OAuthSwift.Parameters,
                        completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        postSimpleRequest(url: "\(baseURI)/people/\(username)/favorites/\(identifier).json", parameters: data, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }
}
