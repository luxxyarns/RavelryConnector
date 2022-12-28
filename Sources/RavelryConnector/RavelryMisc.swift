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
    private static var lowresBackupIdentifier = "small_url"
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
    
    
    
    func  setRavelryFirstImage(_ json : Any?, pictureMode: RavelryPictureMode = .lowres , view: UIImageView?,
                               completedDisplay: @escaping () -> Void)   {
        if let d = json as? [String:Any]{
            if let firstPhoto = d["first_photo"] as? [String:Any ]{
                setImageFromDict(firstPhoto, pictureMode: pictureMode, view: view) {_ in
                    completedDisplay()
                }
            } else {
                if let v = view {
                    v.image = UIImage(systemName: "rectangle.on.rectangle.slash")
                 }
                completedDisplay()
            }
        }
    }
    
    
    
    func  setRavelryBestImage(_ json : Any?, pictureMode: RavelryPictureMode = .lowres , view: UIImageView?,
                              completedDisplay: @escaping () -> Void)   {
        if let d = json as? [String:Any]{
            if let firstPhoto = d["best_photo"] as? [String:Any ]{
                setImageFromDict(firstPhoto, pictureMode: pictureMode, view: view) {_   in
                    completedDisplay()
                }
            } else {
                if let v = view {
                    v.image = UIImage(systemName: "rectangle.on.rectangle.slash")

                }
                completedDisplay()
            }
        }
    }
    
    
    
    
    func  setImageFromDict(_ firstPhoto : [String:Any ]?, pictureMode: RavelryPictureMode = .lowres , view: UIImageView?,
                           completedDisplay: @escaping (_ url : String ) -> Void)   {
        if let firstPhoto = firstPhoto {
            if let v = view {
                if pictureMode == .lowhighres {
                    if let url = getPictureURL(firstPhoto, pictureMode:.thumbnail ) {
                        let indicator = UIActivityIndicatorView(frame: v.frame)
                        v.superview!.addSubview(indicator)
                        indicator.style = .gray
                        indicator.startAnimating()
                        v.alpha = 0
                        v.sd_setImage(with: URL(string: url),
                                      placeholderImage: nil,
                                      options: [],
                                      context: nil,
                                      progress: nil) { (img, err, type, theurl) in
                            var duration = 0.0
                            if type == .none {
                                duration = 0.4
                            }
                            UIView.animate(withDuration: duration,
                                           delay: 0,
                                           animations: {
                                v.alpha = 1
                                DispatchQueue.global(qos: .default).async {
                                    DispatchQueue.main.async {
                                        if let url = self.getPictureURL(firstPhoto, pictureMode: .lowres ) {
                                            v.sd_setImage(with: URL(string: url),
                                                          placeholderImage: v.image,
                                                          options: [],
                                                          context: nil,
                                                          progress: nil) { (img, err, type, theurl) in
                                                
                                            }
                                        }
                                    }
                                }
                                
                            })
                            completedDisplay(url)
                            indicator.removeFromSuperview()
                        }
                    } else {
                        v.image = UIImage(systemName: "rectangle.on.rectangle.slash")

                        completedDisplay("nil")
                        
                    }
                } else {
                    if let url = getPictureURL(firstPhoto, pictureMode:pictureMode ) {
                        let indicator = UIActivityIndicatorView(frame: v.frame)
                        if v == nil { return }
                        if v.superview == nil { return }
                        v.superview!.addSubview(indicator)
                        indicator.style = .gray
                        indicator.startAnimating()
                        v.alpha = 0
                        //  v.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                        v.sd_setImage(with: URL(string: url),
                                      placeholderImage: nil,
                                      options: [],
                                      context: nil,
                                      progress: nil) { (img, err, type, theurl) in
                            var duration = 0.0
                            if type == .none {
                                duration = 0.5
                            }
                            UIView.animate(withDuration: duration, delay: 0, options: .allowUserInteraction, animations: {
                                //  v.transform = .identity
                                v.alpha = 1
                            }) { ( successss) in
                                completedDisplay(url)
                            }
                            
                            
                            
                            /* UIView.animate(withDuration: duration,
                             delay: 0,
                             usingSpringWithDamping: 0.1,
                             initialSpringVelocity: 1.0,
                             options: .allowUserInteraction,
                             animations: {
                             v.transform = .identity
                             v.alpha = 1
                             completedDisplay(url)
                             })*/
                            
                            indicator.removeFromSuperview()
                        }
                    } else {
                        // no given picture
                        v.image = UIImage(systemName: "rectangle.on.rectangle.slash")

                        completedDisplay("nil")
                        
                    }
                }
            }
        } else {
            if let v = view {
                v.image = UIImage(systemName: "rectangle.on.rectangle.slash")

            }
            completedDisplay("nil")
        }
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
 
