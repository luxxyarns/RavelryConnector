// Ravelry Connector - to help connecting with the Ravelry API: https://www.ravelry.com/api
// (C) 2022 by Marco Nissen

import Foundation
import OAuthSwift

public extension RavelryEnvironment {
    func createPack(data: OAuthSwift.Parameters,
                    completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        postSimpleRequest(url: "\(baseURI)/packs/create.json", parameters: data, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func deletePack(pack_id: Int, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        deleteSimpleRequest(url: "\(baseURI)/packs/\(pack_id).json", completedRequest: completedRequest)
    }

    func showPack(pack_id: Int,
                  completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/packs/\(pack_id).json", completedRequest: completedRequest)
    }

    func updatePack(
        pack_id: Int,
        data: OAuthSwift.Parameters,
        completedRequest: @escaping (_ json: [String: Any]?) -> Void
    ) {
        postSimpleRequest(url: "\(baseURI)/packs/\(pack_id).json", parameters: data, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }
}
