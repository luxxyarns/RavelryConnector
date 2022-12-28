import Foundation
import OAuthSwift

public extension RavelryEnvironment {
    func searchLibrary(username: String, query: String, query_type: String, type: String, sort: String, page: Int, page_size: Int,
                       completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["query"] = query
        parameters["query_type"] = query_type
        parameters["type"] = type
        parameters["sort"] = sort
        parameters["page"] = page
        parameters["page_size"] = page_size

        getPaginatedRequest(resultsKey: "volumes", url: "\(baseURI)/people/\(username)/library/search.json", parameters: parameters, username: username, completedRequest: completedRequest)
    }

    func generateLibraryPDFDownloadLink(
        identifier: Int,
        completedRequest: @escaping (_ json: [String: Any]?) -> Void
    ) {
        postSimpleRequest(url: "\(baseURI)/product_attachments/\(identifier)/generate_download_link.json", completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func showVolume(identifier: Int,
                    completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/volumes/\(identifier).json", completedRequest: completedRequest)
    }

    func updateVolume(
        identifier: Int,
        data: OAuthSwift.Parameters,
        completedRequest: @escaping (_ json: [String: Any]?) -> Void
    ) {
        postSimpleRequest(url: "\(baseURI)/volumes/\(identifier)/update.json", parameters: data, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func createVolume(data: OAuthSwift.Parameters,
                      completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        postSimpleRequest(url: "\(baseURI)/volumes/create.json", parameters: data, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func deleteVolume(identifier: Int, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        deleteSimpleRequest(url: "\(baseURI)/volumes/\(identifier).json", completedRequest: completedRequest)
    }
}
