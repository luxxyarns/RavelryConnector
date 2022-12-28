import Foundation
import OAuthSwift

public extension RavelryEnvironment {
    func uploadImage(upload_token: String,
                     file0: Data?, file1: Data? = nil, file2: Data? = nil,
                     completedRequest: @escaping (_ json: [String: Any]?) -> Void,
                     failure: @escaping(_ err: OAuthSwiftError?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["upload_token"] = upload_token
        var multiparts = [OAuthSwiftMultipartData]()
        if let file0 = file0 {
            multiparts.append(OAuthSwiftMultipartData(name: "file0", data: file0, fileName: "file0", mimeType: "image/jpeg"))
        }
        if let file1 = file1 {
            multiparts.append(OAuthSwiftMultipartData(name: "file1", data: file1, fileName: "file1", mimeType: "image/jpeg"))
        }
        if let file2 = file2 {
            multiparts.append(OAuthSwiftMultipartData(name: "file2", data: file2, fileName: "file2", mimeType: "image/jpeg"))
        }
        postMultipart(url: "\(baseURI)/upload/image.json", parameters: parameters, multiparts: multiparts,
                      success: { response in
                          do {
                              let json = try response.jsonObject()
                              if let j = json as? [String: Any] {
                                  completedRequest(j)
                              } else {
                                  print("wrong format \(json)")
                                  failure(nil)
                              }
                          } catch let err {
                              print(err)
                             failure(nil)
                          }
        }) { err in
            print(err)
            failure(err)
            
        }
    }

    func requestUploadToken(completedRequest: @escaping (_ json: [String: Any]?) -> Void,
                             failure: @escaping (_ err: OAuthSwiftError?) -> Void )  {
        postSimpleRequest(url: "\(baseURI)/upload/request_token.json", completedRequest: completedRequest, failure:failure)
    }

    func getUploadImageStatus(upload_token: String,
                              completedRequest: @escaping (_ json: [String: Any]?) -> Void )  {
        var parameters = OAuthSwift.Parameters()
        parameters["upload_token"] = upload_token
        getSimpleRequest(url: "\(baseURI)/upload/image/status.json", parameters: parameters, completedRequest: completedRequest )
    }
}
