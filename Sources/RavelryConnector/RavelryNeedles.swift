// Ravelry Connector - to help connecting with the Ravelry API: https://www.ravelry.com/api
// (C) 2022 by Marco Nissen

import Foundation
import OAuthSwift

public extension RavelryEnvironment {
    func getNeedleList(username: String, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/people/\(username)/needles/list.json", completedRequest: completedRequest)
    }

    func getNeedleSizes(completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/needles/sizes.json", completedRequest: completedRequest)
    }

    func getNeedleTypes(completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/needles/types.json", completedRequest: completedRequest)
    }
}
