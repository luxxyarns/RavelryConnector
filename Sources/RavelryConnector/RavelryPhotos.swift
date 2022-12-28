import Foundation
import KeychainSwift
import OAuthSwift
 
public extension RavelryEnvironment {
    func deletePhoto(identifier: Int, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        deleteSimpleRequest(url: "\(baseURI)/photos/\(identifier).json", completedRequest: completedRequest)
    }
    
    func getPhotosDimensions(photo_id_list: String, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["photo_id_list"] = photo_id_list
        
        getSimpleRequest(url: "\(baseURI)/photos/dimensions.json", parameters: parameters, completedRequest: completedRequest)
    }
    
    func getPhotoSizes(identifier: Int, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/photos/\(identifier)/sizes.json", completedRequest: completedRequest)
    }
    
    func getPhotoStatus(status_token: String, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["status_token"] = status_token
        
        getSimpleRequest(url: "\(baseURI)/photos/status.json", parameters: parameters, completedRequest: { (_ json: [String: Any]?) in
            completedRequest(json)
        })
    }
    
    func updatePhoto(photo_id: Int, x_offset: Int, y_offset: Int, copyright_notice: String, caption: String,
                     completedRequest: @escaping (_ json: [String: Any]?) -> Void,
                     failure: @escaping (_ err: OAuthSwiftError?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["x_offset"] = x_offset
        parameters["y_offset"] = y_offset
        parameters["copyright_notice"] = copyright_notice
        parameters["caption"] = caption
        
        postSimpleRequest(url: "\(baseURI)/photos/\(photo_id).json", parameters: parameters, completedRequest: { (_ json: [String: Any]?) in
            completedRequest(json)
        }, failure: failure)
    }
    
    func pollingPhotoStatus(_ status_token: String,
                            success: @escaping (_ photo_id: Int) -> Void,
                            failure: @escaping(_ err: OAuthSwiftError?) -> Void,
                            progressUpdate: @escaping (_ progress: Int) -> Void) {
        if let env = RavelryBase.shared.getCurrentEnvironment() {
            env.getPhotoStatus(status_token: status_token, completedRequest: { status in
                if let s = status {
                    if let failed = s["failed"] as? Bool {
                        if failed {
                            print("photo upload - ravelry reported failure")
                            failure(nil)
                            return
                        }
                    }
                    if let progress = s["progress"] as? Int {
                        if progress < 100 {
                            progressUpdate(progress)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.pollingPhotoStatus(status_token, success: success, failure: failure, progressUpdate: progressUpdate)
                            }
                        }
                        if progress >= 100 {
                            progressUpdate(progress)
                            if let photo = s["photo"] as? [String: Any] {
                                if let photo_id = photo["id"] as? Int {
                                    success(photo_id)
                                    print(photo)
                                    return
                                }
                            } else {
                                print("ravelry did not provide photo details")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    self.pollingPhotoStatus(status_token, success: success, failure: failure, progressUpdate: progressUpdate)
                                }
                            }
                        }
                    } else {
                        progressUpdate(40)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.pollingPhotoStatus(status_token, success: success, failure: failure, progressUpdate: progressUpdate)
                        }
                    }
                }
            })
        }
    }
}





 
