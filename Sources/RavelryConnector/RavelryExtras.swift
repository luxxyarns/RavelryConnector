// Ravelry Connector - to help connecting with the Ravelry API: https://www.ravelry.com/api
// (C) 2022 by Marco Nissen

import Foundation
import OAuthSwift

public extension RavelryEnvironment {
    func createAttachment(image_id: Int,
                          completedRequest: @escaping (_ json: [String: Any]?) -> Void,
                          failure: @escaping(_ err: OAuthSwiftError?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["image_id"] = image_id
        postSimpleRequest(url: "\(baseURI)/extras/create_attachment.json", parameters: parameters, completedRequest: completedRequest, failure:  failure)
    }
} 
