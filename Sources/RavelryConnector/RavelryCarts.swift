// Ravelry Connector - to help connecting with the Ravelry API: https://www.ravelry.com/api
// (C) 2022 by Marco Nissen

import Foundation
import OAuthSwift

public extension RavelryEnvironment {
    func addCart(identifier: Int, item_code: String, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["item_code"] = item_code
        postSimpleRequest(url: "\(baseURI)/carts/\(identifier)/add.json", parameters: parameters, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func createCart(store_id: Int, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["store_id"] = store_id
        postSimpleRequest(url: "\(baseURI)/carts/create.json", parameters: parameters, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func externalCartCheckout(identifier: Int, payment_reference: String, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["payment_reference"] = payment_reference
        postSimpleRequest(url: "\(baseURI)/carts/\(identifier)/external_checkout.json", parameters: parameters, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func externalCartCheckoutLoveKnitting(identifier: Int, payment_reference: String,
                                          product_id_list: [String],
                                          completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["payment_reference"] = payment_reference
        parameters["product_id_list"] = product_id_list.joined(separator: " ")
        postSimpleRequest(url: "\(baseURI)/carts/loveknitting/\(identifier)/external_checkout.json", parameters: parameters, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }
}
