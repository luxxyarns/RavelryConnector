import Foundation
import OAuthSwift

public extension RavelryEnvironment {
    func getYarnAttributes(completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/yarn_attributes/groups.json", completedRequest: completedRequest)
    }

    func searchYarnCompanies(query: String, sort: String, additionalParameters _: [String: String]? = nil, page: Int, page_size: Int,
                             completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["query"] = query
        parameters["sort"] = sort
        parameters["page"] = page
        parameters["page_size"] = page_size

        getPaginatedRequest(resultsKey: "yarn_companies", url: "\(baseURI)/yarn_companies/search.json", parameters: parameters, completedRequest: completedRequest)
    }

    func searchYarns(query: String, sort: String, personal_attributes: Bool, additionalParameters: [String: String]? = nil, page: Int, page_size: Int,
                     completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        if let a = additionalParameters {
            parameters = a
        }
        parameters["query"] = query
        parameters["sort"] = sort
        parameters["personal_attributes"] = personal_attributes
        parameters["page"] = page
        parameters["page_size"] = page_size

        getPaginatedRequest(resultsKey: "yarns", url: "\(baseURI)/yarns/search.json", parameters: parameters, completedRequest: completedRequest)
    }

    func showYarn(identifier: Int,
                  completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/yarns/\(identifier).json", completedRequest: completedRequest)
    }
}
