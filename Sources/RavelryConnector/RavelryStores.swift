// Ravelry Connector - to help connecting with the Ravelry API: https://www.ravelry.com/api
// (C) 2022 by Marco Nissen

import Foundation
import OAuthSwift

public extension RavelryEnvironment {
    func searchShops(query: String,
                     lat: Float,
                     lng: Float,
                     radius: Int,
                     units: String,
                     page: Int, page_size: Int,
                     completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        print("Function: \(#function), line: \(#line)")
        var parameters = OAuthSwift.Parameters()
        parameters["query"] = query
        //parameters["shop_type_id"] = shop_type_id
        parameters["query"] = query
        parameters["lng"] = lng
        parameters["lat"] = lat
        parameters["radius"] = radius
        parameters["units"] = units
        parameters["page"] = page
        parameters["page_size"] = page_size
        
        print("search for \(lat)/\(lng)")
        getPaginatedRequest(resultsKey: "shops", url: "\(baseURI)/shops/search.json", parameters: parameters, completedRequest: completedRequest)
    }
    
    func showShop(identifier: Int, include: [String],
                  completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["include"] = include.joined(separator: " ")
        
        getSimpleRequest(url: "\(baseURI)/shops/\(identifier).json", parameters: parameters, completedRequest: completedRequest)
    }
}
