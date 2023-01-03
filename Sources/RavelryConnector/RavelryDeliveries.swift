// Ravelry Connector - to help connecting with the Ravelry API: https://www.ravelry.com/api
// (C) 2022 by Marco Nissen

import Foundation
import OAuthSwift

public extension RavelryEnvironment {
    func getDeliveries(page: Int, page_size: Int,
                       completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["page"] = page
        parameters["page_size"] = page_size
        
        getPaginatedRequest(resultsKey: "deliveries", url: "\(baseURI)/deliveries/list.json", parameters: parameters, completedRequest: completedRequest)
    }
}
