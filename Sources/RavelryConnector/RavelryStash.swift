import Foundation
import OAuthSwift
import UIKit

public extension RavelryEnvironment {
    func getStashComments(username: String, identifier: Int, sort: String, page: Int, page_size: Int,
                          completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["sort"] = sort
        parameters["page"] = page
        parameters["page_size"] = page_size

        getPaginatedRequest(resultsKey: "comments", url: "\(baseURI)/people/\(username)/stash/\(identifier)/comments.json",
                            parameters: parameters, completedRequest: completedRequest)
    }

    func createStash(username: String,
                     data: OAuthSwift.Parameters,
                     completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        postSimpleRequest(url: "\(baseURI)/people/\(username)/stash/create.json", parameters: data, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func createStashPhoto(username: String,
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
        postSimpleRequest(url: "\(baseURI)/people/\(username)/stash/\(identifier)/create_photo.json", parameters: parameters, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func deleteStash(username: String, identifier: Int, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        deleteSimpleRequest(url: "\(baseURI)/people/\(username)/stash/\(identifier).json", completedRequest: completedRequest)
    }

    func getStashList(username: String, sort: String, include: [String], page: Int, page_size: Int,
                      completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["include"] = include.joined(separator: " ")
        parameters["sort"] = sort
        parameters["page"] = page
        parameters["page_size"] = page_size

        getPaginatedRequest(resultsKey: "stash", url: "\(baseURI)/people/\(username)/stash/list.json", parameters: parameters, username: username, completedRequest: completedRequest)
    }

    func reorderStashPhotos(username: String,
                            identifier: Int,
                            sort_order: String,
                            completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["sort_order"] = sort_order
        postSimpleRequest(url: "\(baseURI)/people/\(username)/stash/\(identifier)/reorder_photos.json", parameters: parameters, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func searchStash(query: String, sort: String, additionalParameters: [String: String]? = nil, page: Int, page_size: Int,
                     completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        if let a = additionalParameters {
            parameters = a
        }
        parameters["query"] = query
        parameters["sort"] = sort
        parameters["page"] = page
        parameters["page_size"] = page_size

        getPaginatedRequest(resultsKey: "stashes", url: "\(baseURI)/stash/search.json", parameters: parameters, completedRequest: completedRequest)
    }

    func showStash(username: String, identifier: Int, include: [String],
                   completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["include"] = include.joined(separator: " ")

        getSimpleRequest(url: "\(baseURI)/people/\(username)/stash/\(identifier).json", parameters: parameters, completedRequest: completedRequest)
    }

    func updateStash(username: String,
                     identifier: Int,
                     data: OAuthSwift.Parameters,
                     completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        postSimpleRequest(url: "\(baseURI)/people/\(username)/stash/\(identifier).json", parameters: data, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    private func attachStashPhoto(username: String, identifier: Int, image_id: Int,
                                  success: @escaping () -> Void,
                                  failure: @escaping(_ err: OAuthSwiftError?) -> Void,
                                  progressUpdate: @escaping (_ progress: Int) -> Void) {
        if let env = RavelryBase.shared.getCurrentEnvironment() {
            env.createStashPhoto(username: username,
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

    func uploadStashPhoto(username: String, identifier: Int, image: UIImage,
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
                                            self.attachStashPhoto(username: username, identifier: identifier, image_id: image_id,
                                                                  success: success, failure: failure, progressUpdate: progressUpdate)
                                        }
                                    }
                                }
                            }
                        }, failure: failure)
                    }
                }
            }, failure: failure)
        }
    }
}
