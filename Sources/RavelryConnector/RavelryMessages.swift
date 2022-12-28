import Foundation
import OAuthSwift

public extension RavelryEnvironment {
    func archiveMessage(
        message_id: Int,
        completedRequest: @escaping (_ json: [String: Any]?) -> Void
    ) {
        postSimpleRequest(url: "\(baseURI)/messages/\(message_id)/archive.json", completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }
    
    func unarchiveMessage(
        message_id: Int,
        completedRequest: @escaping (_ json: [String: Any]?) -> Void
    ) {
        postSimpleRequest(url: "\(baseURI)/messages/\(message_id)/unarchive.json", completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }
    
    func createMessage(data: OAuthSwift.Parameters,
                       completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        postSimpleRequest(url: "\(baseURI)/messages/create.json", parameters: data, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }
    
    func replyMessage(message_id: Int, data: OAuthSwift.Parameters,
                      completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        postSimpleRequest(url: "\(baseURI)/messages/\(message_id)/reply.json", parameters: data, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }
    
    func deleteMessage(message_id: Int, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        deleteSimpleRequest(url: "\(baseURI)/messages/\(message_id)/delete.json", completedRequest: completedRequest)
    }
    
    func markMessageRead(message_id: Int, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        postSimpleRequest(url: "\(baseURI)/messages/\(message_id)/mark_read.json", completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }
    
    func markMessageUnread(message_id: Int, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        postSimpleRequest(url: "\(baseURI)/messages/\(message_id)/mark_unread.json", completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }
    
    func getMessages(folder: String, search: String, unread_only: Bool, output_format: String, page: Int, page_size: Int,
                     completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["folder"] = folder
        parameters["search"] = search
        parameters["extras"] = 1
        parameters["unread_only"] = unread_only
        parameters["output_format"] = output_format
        parameters["page"] = page
        parameters["page_size"] = page_size
        
        getPaginatedRequest(resultsKey: "messages", url: "\(baseURI)/messages/list.json",
            parameters: parameters, completedRequest: completedRequest)
    }
    
    func showMessage(message_id: Int,
                     completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/messages/\(message_id).json", completedRequest: completedRequest)
    }
}
  
