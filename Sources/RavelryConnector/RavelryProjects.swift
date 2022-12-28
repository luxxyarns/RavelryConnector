import Foundation
import OAuthSwift
import UIKit

public extension RavelryEnvironment {
    func getProjectComments(username: String, identifier: Int, sort: String, page: Int, page_size: Int,
                            completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["sort"] = sort
        parameters["page"] = page
        parameters["page_size"] = page_size

        getPaginatedRequest(resultsKey: "comments", url: "\(baseURI)/projects/\(username)/\(identifier)/comments.json",
                            parameters: parameters, username: username, completedRequest: completedRequest)
    }

    func getProjectCrafts(completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        postSimpleRequest(url: "\(baseURI)/projects/crafts.json", completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func getProjectStatuses(completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        postSimpleRequest(url: "\(baseURI)/projects/project_statuses.json", completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func createProject(username: String,
                       data: OAuthSwift.Parameters,
                       completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        postSimpleRequest(url: "\(baseURI)/projects/\(username)/create.json", parameters: data, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func createProjectPhoto(username: String,
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
        postSimpleRequest(url: "\(baseURI)/projects/\(username)/\(identifier)/create_photo.json", parameters: parameters, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func deleteProject(username: String, identifier: Int, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        deleteSimpleRequest(url: "\(baseURI)/projects/\(username)/\(identifier).json", completedRequest: completedRequest)
    }

    func getProjectList(username: String, sort: String, include: [String], additionalParameters: [String: String]? = nil, page: Int, page_size: Int, completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        if let a = additionalParameters {
            parameters = a
        }
        parameters["include"] = include.joined(separator: " ")
        parameters["sort"] = sort
        parameters["debug"] = 1
        parameters["page"] = page
        parameters["page_size"] = page_size

        getPaginatedRequest(resultsKey: "projects", url: "\(baseURI)/projects/\(username)/list.json", parameters: parameters, username: username, completedRequest: completedRequest)
    }

    func reorderProjectPhotos(username: String,
                              identifier: Int,
                              sort_order: String,
                              completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["sort_order"] = sort_order
        postSimpleRequest(url: "\(baseURI)/projects/\(username)/\(identifier)/reorder_photos.json", parameters: parameters, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func searchProjects(query: String, sort: String, status: [String], additionalParameters: [String: String]? = nil, page: Int, page_size: Int,
                        completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        if let a = additionalParameters {
            parameters = a
        }
        parameters["query"] = query
        parameters["sort"] = sort
        parameters["status"] = status.joined(separator: "|")
        parameters["debug"] = 1
        parameters["page"] = page
        parameters["page_size"] = page_size

        getPaginatedRequest(resultsKey: "projects", url: "\(baseURI)/projects/search.json", parameters: parameters, completedRequest: completedRequest)
    }

    func showProject(username: String, identifier: Int, include: [String],
                     completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["include"] = include.joined(separator: " ")

        getSimpleRequest(url: "\(baseURI)/projects/\(username)/\(identifier).json", parameters: parameters, completedRequest: completedRequest)
    }

    func showProject(username: String, name: String, include: [String],
                     completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["include"] = include.joined(separator: " ")

        getSimpleRequest(url: "\(baseURI)/projects/\(username)/\(name).json", parameters: parameters, completedRequest: completedRequest)
    }

    func updateProject(username: String,
                       identifier: Int,
                       data: OAuthSwift.Parameters,
                       completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        postSimpleRequest(url: "\(baseURI)/projects/\(username)/\(identifier).json", parameters: data, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    private func attachProjectPhoto(username: String, identifier: Int, image_id: Int,
                                    success: @escaping () -> Void,
                                    failure: @escaping(_ err: OAuthSwiftError?) -> Void, progressUpdate: @escaping (_ progress: Int) -> Void) {
        if let env = RavelryBase.shared.getCurrentEnvironment() {
            env.createProjectPhoto(username: username,
                                   identifier: identifier,
                                   image_id: image_id,
                                   completedRequest: { photojson in
                                       if let j = photojson {
                                           print("created photo json \(j)")
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
                                               }, failure: failure, progressUpdate: { update in
                                                   print("progress update \(update)")
                                                   progressUpdate(update)
                                               })
                                           }
                                       }

            })
        }
    }

    func uploadPhotoAsAssetAsGIF(data: Data,
                                 success: @escaping (_ result: [String: Any]?) -> Void,
                                 failure: @escaping(_ err: OAuthSwiftError?) -> Void,
                                 progressUpdate _: @escaping (_ progress: Int) -> Void) {
        if let env = RavelryBase.shared.getCurrentEnvironment() {
            let imageData = data
            env.requestUploadToken(completedRequest: { tokenJson in
                if let t = tokenJson {
                    if let uploadToken = t["upload_token"] as? String {
                        env.uploadImage(upload_token: uploadToken, file0: imageData, completedRequest: { result in
                            if let r = result {
                                if let uploads = r["uploads"] as? [String: Any] {
                                    if let file0 = uploads["file0"] as? [String: Any] {
                                        if let image_id = file0["image_id"] as? Int {
                                            env.createAttachment(image_id: image_id, completedRequest: { result in
                                                success(result)
                                            }, failure: failure)
                                        }
                                    }
                                }
                            }
                        },failure: failure)
                    }
                }
            }, failure: failure)
        }
    }

    func uploadPhotoAsAsset(image: UIImage,
                            success: @escaping (_ result: [String: Any]?) -> Void,
                            failure: @escaping(_ err: OAuthSwiftError?) -> Void,
                            progressUpdate _: @escaping (_ progress: Int) -> Void) {
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
                                            env.createAttachment(image_id: image_id, completedRequest: { result in
                                                success(result)
                                            },failure: failure)
                                        }
                                    }
                                }
                            }
                        },failure: failure)
                    }
                }
            }, failure:  failure)
        }
    }

    func uploadProjectPhoto(username: String, identifier: Int, image: UIImage,
                            success: @escaping () -> Void,
                            failure: @escaping(_ err: OAuthSwiftError?) -> Void,
                            progressUpdate: @escaping (_ progress: Int) -> Void) {
        if let env = RavelryBase.shared.getCurrentEnvironment() {
            progressUpdate(10)
            let imageData = image.jpegData(compressionQuality: 0.75)
            env.requestUploadToken(completedRequest: { tokenJson in
                progressUpdate(20)
                print("request upload token json is \(tokenJson)")
                if let t = tokenJson {
                    if let uploadToken = t["upload_token"] as? String {
                        print("request upload token is \(uploadToken)")
                        env.uploadImage(upload_token: uploadToken, file0: imageData, completedRequest: { result in
                            progressUpdate(30)

                            print("uploadImage result \(result)")
                            if let r = result {
                                if let uploads = r["uploads"] as? [String: Any] {
                                    if let file0 = uploads["file0"] as? [String: Any] {
                                        if let image_id = file0["image_id"] as? Int {
                                            print("attach now project photo")
                                            self.attachProjectPhoto(username: username, identifier: identifier, image_id: image_id,
                                                                    success: success, failure: failure, progressUpdate: progressUpdate)
                                        }
                                    }
                                }
                            }
                        },failure: failure)
                    }
                }
            }, failure: failure)
        }
    }
}
