import Foundation
import OAuthSwift

public extension RavelryEnvironment {
    func deleteBundledItem(bundled_item_id: Int, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        deleteSimpleRequest(url: "\(baseURI)/bundled_items/\(bundled_item_id).json", completedRequest: completedRequest)
    }
    
    func getBundledItem(bundled_item_id: Int, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/bundled_items/\(bundled_item_id).json", completedRequest: completedRequest)
    }
    
    func createBundledItem(username: String, data: [String: Any], completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/people/\(username)/bundles/create.json", parameters: data, completedRequest: completedRequest)
    }
    
    func deleteBundleRecord(username: String, recordID: Int, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        deleteSimpleRequest(url: "\(baseURI)/people/\(username)/bundles/\(recordID).json", completedRequest: completedRequest)
    }
    
    func getBundleList(username: String, owner_types: [String], query: String, page: Int, page_size: Int,
                       completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["owner_types"] = owner_types.joined(separator: " ")
        parameters["query"] = query
        parameters["page"] = page
        parameters["page_size"] = page_size
        
        getPaginatedRequest(resultsKey: "bundles", url: "\(baseURI)/people/\(username)/bundles/list.json", parameters: parameters, username: username, completedRequest: completedRequest)
    }
    
    func showBundle(username: String, identifier: Int,
                    completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/people/\(username)/bundles/\(identifier).json", completedRequest: completedRequest)
    }
}
