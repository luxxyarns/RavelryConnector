import Foundation
import OAuthSwift

public extension RavelryEnvironment {
    func showDesigner(identifier: Int, include: [String],
                      completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["include"] = include.joined(separator: " ")

        getSimpleRequest(url: "\(baseURI)/designers/\(identifier).json", parameters: parameters, completedRequest: completedRequest)
    }

    func showDesigner(name: String, include: [String],
                      completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["include"] = include.joined(separator: " ")

        getSimpleRequest(url: "\(baseURI)/designers/\(name).json", parameters: parameters, completedRequest: completedRequest)
    }
}
