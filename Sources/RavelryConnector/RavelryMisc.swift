// Ravelry Connector - to help connecting with the Ravelry API: https://www.ravelry.com/api
// (C) 2022 by Marco Nissen

import Foundation
import OAuthSwift
import UIKit
import SDWebImage

public extension  RavelryEnvironment {
    func getCurrentUser(  completedRequest: @escaping (_ json : [String:Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/current_user.json?extras=1", completedRequest: completedRequest)
    }
    
    func getYarnWeights(  completedRequest: @escaping (_ json : [String:Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/yarn_weights.json", completedRequest: completedRequest)
    }
    func getColorFamilies(  completedRequest: @escaping (_ json : [String:Any]?) -> Void) {
        getSimpleRequest( url: "\(baseURI)/color_families.json", completedRequest: completedRequest)
    }
    
    func showPage( page_id : Int,
                   completedRequest: @escaping (_ json : [String:Any]?) -> Void) {
        
        getSimpleRequest(url: "\(baseURI)/pages/\(page_id).json",  completedRequest: completedRequest)
        
    }
    func updatePage(
        page_id : Int,
        data : OAuthSwift.Parameters ,
        completedRequest: @escaping (_ json : [String:Any]?) -> Void) {
            
            postSimpleRequest(url: "\(baseURI)/pages/\(page_id).json", parameters:data, completedRequest: completedRequest, failure:  { (err) in
                if err != nil { print ("error in post request: \(err!.description)") }
            })
        }
    
    func getSavedSearches(   completedRequest: @escaping (_ json : [String:Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/saved_searches.json", completedRequest: completedRequest)
    }
    
    private static var lowresIdentifier = "small2_url"
    private static var lowresBackupIdentifier = "small2_url"
    private static var highresIdentifier = "medium2_url"
    private static var highresBackupIdentifier = "medium_url"
    private static var thumbnailIdentifier = "thumbnail_url"
    private static var thumbnailIdentifier1 = "large_photo_url"
    private static var thumbnailIdentifier2 = "photo_url"
    private static var thumbnailIdentifier3 = "tiny_photo_url"
    private static var squareIdentifier = "square_url"
    
    enum RavelryPictureMode {
        case highres
        case lowres
        case lowhighres
        case thumbnail
        case square
    }
    
    func getUsername(_ json : [String:Any]? ) -> String? {
        if let j = json {
            if let u = j["user"] as? [String:Any] {
                if let u = u["username"] as? String {
                    return u
                }
                
            }
            if let u = j["username"] as? String {
                return u
            }
        }
        return nil
    }
    
    func getPictureURL(_ json : [String:Any]? , pictureMode : RavelryPictureMode = .lowres) -> String? {
        if let j = json {
            switch pictureMode {
            case .highres:
                if let x = j[RavelryEnvironment.highresIdentifier] as? String {
                    return x
                }
                if let x = j[RavelryEnvironment.highresBackupIdentifier] as? String {
                    return x
                }
                if let x = j[RavelryEnvironment.thumbnailIdentifier1] as? String {
                    return x
                }
                if let x = j[RavelryEnvironment.thumbnailIdentifier2] as? String {
                    return x
                }
                if let x = j[RavelryEnvironment.thumbnailIdentifier3] as? String {
                    return x
                }
                
            case .lowres:
                if let x = j[RavelryEnvironment.lowresIdentifier] as? String {
                    return x
                }
                if let x = j[RavelryEnvironment.lowresBackupIdentifier] as? String {
                    return x
                }
                if let x = j[RavelryEnvironment.thumbnailIdentifier1] as? String {
                    return x
                }
                if let x = j[RavelryEnvironment.thumbnailIdentifier2] as? String {
                    return x
                }
                if let x = j[RavelryEnvironment.thumbnailIdentifier3] as? String {
                    return x
                }
            case .square:
                if let x = j[RavelryEnvironment.squareIdentifier] as? String {
                    return x
                }
            case .thumbnail:
                if let x = j[RavelryEnvironment.thumbnailIdentifier] as? String {
                    return x
                }
                if let x = j[RavelryEnvironment.thumbnailIdentifier1] as? String {
                    return x
                }
                if let x = j[RavelryEnvironment.thumbnailIdentifier2] as? String {
                    return x
                }
                if let x = j[RavelryEnvironment.thumbnailIdentifier3] as? String {
                    return x
                }
                if let x = j[RavelryEnvironment.lowresBackupIdentifier] as? String {
                    return x
                }
                if let x = j[RavelryEnvironment.squareIdentifier] as? String {
                    return x
                }
            default:
                return nil
            }
            
        }
        return nil
    }
    
}

