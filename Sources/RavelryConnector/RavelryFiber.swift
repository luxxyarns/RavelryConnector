import Foundation
import OAuthSwift
import UIKit

public extension RavelryEnvironment {
    func getFiberComments(username: String, identifier: Int, sort: String, page: Int, page_size: Int,
                          completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["sort"] = sort
        parameters["page"] = page
        parameters["page_size"] = page_size

        getPaginatedRequest(resultsKey: "comments", url: "\(baseURI)/people/\(username)/fiber/\(identifier)/comments.json",
                            parameters: parameters, username: username, completedRequest: completedRequest)
    }

    func createFiber(username: String,
                     data: OAuthSwift.Parameters,
                     completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        postSimpleRequest(url: "\(baseURI)/people/\(username)/fiber/create.json", parameters: data, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func createFiberPhoto(username: String,
                          identifier: Int,
                          image_id: Int? = nil,
                          source_url: String? = nil,
                          completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        if let v = image_id {
            parameters["image_id"] = v
        }
        if let v = source_url {
            parameters["source_url"] = v
        }
        postSimpleRequest(url: "\(baseURI)/people/\(username)/fiber/\(identifier)/create_photo.json", parameters: parameters, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func deleteFiber(username: String, identifier: Int, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        deleteSimpleRequest(url: "\(baseURI)/people/\(username)/fiber/\(identifier).json", completedRequest: completedRequest)
    }

    func getFiberList(username: String, sort: String, include: [String], page: Int, page_size: Int,
                      completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["include"] = include.joined(separator: " ")
        parameters["sort"] = sort
        parameters["page"] = page
        parameters["page_size"] = page_size

        getPaginatedRequest(resultsKey: "fiber", url: "\(baseURI)/people/\(username)/fiber/list.json", parameters: parameters, username: username, completedRequest: completedRequest)
    }

    /* func reorderStashPhotos(  username : String ,
                               identifier : Int,
                               sort_order : String ,
                               completedRequest: @escaping (_ json : [String:Any]?) -> Void) {
         var parameters = OAuthSwift.Parameters()
         parameters["sort_order"] = sort_order
         postSimpleRequest(url: "\(baseURI)/people/\(username)/stash/\(identifier)/reorder_photos.json", parameters:parameters, completedRequest: completedRequest)
     }*/

    /* func searchstash( query : String, sort: String,   page: Int, page_size: Int,
                       completedRequest: @escaping (_ json : [[String:Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
         var parameters = OAuthSwift.Parameters()
         parameters["query"] = query
         parameters["sort"] = sort
         parameters["page"] = page
         parameters["page_size"] = page_size

         getPaginatedRequest(resultsKey: "stash", url: "\(baseURI)/stash/search.json", parameters: parameters, completedRequest: completedRequest)
     }*/

    func showFiber(username: String, identifier: Int,
                   completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/people/\(username)/fiber/\(identifier).json", completedRequest: completedRequest)
    }

    func updateFiber(username: String,
                     identifier: Int,
                     data: OAuthSwift.Parameters,
                     completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        postSimpleRequest(url: "\(baseURI)/people/\(username)/fiber/\(identifier).json", parameters: data, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    private func attachFiberPhoto(username: String, identifier: Int, image_id: Int,
                                  success: @escaping () -> Void,
                                  failure: @escaping(_ err: OAuthSwiftError?) -> Void,
                                  progressUpdate: @escaping (_ progress: Int) -> Void) {
        if let env = RavelryBase.shared.getCurrentEnvironment() {
            env.createFiberPhoto(username: username,
                                 identifier: identifier,
                                 image_id: image_id,
                                 completedRequest: { photojson in
                                     if let j = photojson {
                                         print(j)
                                         if let status_token = j["status_token"] as? String {
                                             self.pollingPhotoStatus(status_token, success: { (_ photo_id) in

                                                 env.updatePhoto(photo_id: photo_id,
                                                                 x_offset: 0, y_offset: 0,
                                                                 copyright_notice: username,
                                                                 caption: "",
                                                                 completedRequest: { _ in
                                                                     success()
                                                 }, failure:  { (err) in
                                                     if err != nil { print ("error in post request: \(err!.description)") }
                                                 })
                                             }, failure: failure, progressUpdate: progressUpdate)
                                         }
                                     }

            })
        }
    }

    func uploadFiberPhoto(username: String, identifier: Int, image: UIImage,
                          success: @escaping () -> Void,
                          failure: @escaping(_ err: OAuthSwiftError?) -> Void,
                          progressUpdate: @escaping (_ progress: Int) -> Void) {
        if let env = RavelryBase.shared.getCurrentEnvironment() {
            let imageData = image.jpegData(compressionQuality: 0.75)
            env.requestUploadToken(completedRequest: { tokenJson in
                if let t = tokenJson {
                    if let uploadToken = t["upload_token"] as? String {
                        env.uploadImage(upload_token: uploadToken, file0: imageData, completedRequest: { result in
                            if let r = result {
                                if let uploads = r["uploads"] as? [String: Any] {
                                    if let file0 = uploads["file0"] as? [String: Any] {
                                        if let image_id = file0["image_id"] as? Int {
                                            self.attachFiberPhoto(username: username, identifier: identifier, image_id: image_id,
                                                                  success: success, failure: failure, progressUpdate: progressUpdate)
                                        }
                                    }
                                }
                            }
                        },failure: failure)
                    }
                }
            }, failure:  { (err) in
                if err != nil { print ("error in post request: \(err!.description)") }
            })
        }
    }

    func getFiberAttributeGroups(completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/fiber_attribute_groups/list.json", completedRequest: completedRequest)
    }

    func getFiberAttributes(completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/fiber_attributes/list.json", completedRequest: completedRequest)
    }

    func getFiberCategories(completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/fiber_categories/list.json", completedRequest: completedRequest)
    }
}
