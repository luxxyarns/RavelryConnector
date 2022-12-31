import Foundation
import KeychainSwift
import OAuthSwift
import WebKit
import os.log

public class RavelryBase: ObservableObject {
    var servers = [RavelryEnvironment]()
    @Published var currentEnvironment = ""
    
    public class var shared: RavelryBase {
        struct Static {
            static let instance = RavelryBase()
        }
        return Static.instance
    }
    var errorTitle = ""
    var errorMessage = ""
    @Published public var focusedUser: String?
    @Published  var displayError: Bool = false
    @Published  var unreadMessages = 0
    @Published  var unreadForumReplies = 0

    public static let htmlCSS = """
    <link href="https://style-cdn.ravelrycache.com/stylesheets/ravelry_legacy_1910241442.css" rel="Stylesheet" type="text/css" />
    <link href="https://style-cdn.ravelrycache.com/stylesheets/ravelry_components_1910241442.css" rel="Stylesheet" type="text/css" />
    """
    
    public static let htmlCSSExtended = """
    <link href="https://style-cdn.ravelrycache.com/stylesheets/ravelry_legacy_1910241442.css" rel="Stylesheet" type="text/css" />
    <link href="https://style-cdn.ravelrycache.com/stylesheets/ravelry_components_1910241442.css" rel="Stylesheet" type="text/css" />
    <script src="https://style-cdn.ravelrycache.com/javascripts/base11_1906031629.js" type="text/javascript"></script>
    <script src="https://style-cdn.ravelrycache.com/javascripts/ravelry_1910241442.js" type="text/javascript"></script>
    """
    
    public func handleURL(url: URL) {
        OAuthSwift.handle(url: url)
    }
    
    public func addRavelryEnvironment(_ env: RavelryEnvironment) {
        servers.append(env)
    }
    
    public func getEnvironment(_ i: String) -> RavelryEnvironment? {
        for env in servers {
            if env.identifier == i { return env }
        }
        return nil
    }
    
    public func getCurrentEnvironment() -> RavelryEnvironment? {
        return getEnvironment(currentEnvironment)
    }
    
    public func selectEnvironment(_ i: String) -> Bool {
        for env in servers {
            if env.identifier == i {
                currentEnvironment = i
                
                let keychain = KeychainSwift()
                if let oauthswift = env.oauth2swift {
                    if let token = keychain.get("\(i):oauthToken") {
                        oauthswift.client.credential.oauthToken = token
                    }
                    if let token_secret = keychain.get("\(i):oauthTokenSecret") {
                        oauthswift.client.credential.oauthTokenSecret = token_secret
                    }
                    if let refreshToken = keychain.get("\(i):oauthRefreshToken") {
                        oauthswift.client.credential.oauthRefreshToken = refreshToken
                    }
                    if let expiredAtStr = keychain.get("\(i):oauthTokenExpiresAt") {
                        let iX = Int(expiredAtStr)
                        let eX = Date(timeIntervalSince1970: Double(iX!))
                        oauthswift.client.credential.oauthTokenExpiresAt = eX
                    }
                    if let newFocusedUser = keychain.get("\(i):focusedUser") {
                        RavelryBase.shared.focusedUser = newFocusedUser
                    }
                }
                if let oauthswift = env.oauth1swift {
                    if let token = keychain.get("\(i):oauth1Token") {
                        oauthswift.client.credential.oauthToken = token
                    }
                    if let token_secret = keychain.get("\(i):oauth1TokenSecret") {
                        oauthswift.client.credential.oauthTokenSecret = token_secret
                    }
                    if let expiredAtStr = keychain.get("\(i):oauth1TokenExpiresAt") {
                        let iX = Int(expiredAtStr)
                        let eX = Date(timeIntervalSince1970: Double(iX!))
                        oauthswift.client.credential.oauthTokenExpiresAt = eX
                    }
                    if let newFocusedUser = keychain.get("\(i):focusedUser") {
                        RavelryBase.shared.focusedUser = newFocusedUser
                        
                    }
                }
                return true
            }
        }
        return false
    }
}

class XHeaders: OAuthSwiftCredentialHeadersFactory {
    let credential: OAuthSwiftCredential
    init(credential: OAuthSwiftCredential) {
        self.credential = credential
    }
    
    func make(_ url: URL, method _: OAuthSwiftHTTPRequest.Method, parameters _: OAuthSwift.Parameters, body _: Data?) -> [String: String] {
        if url.absoluteString.contains("oauth2/token") {
            let loginString = String(format: "%@:%@", credential.consumerKey, credential.consumerSecret)
            let loginData = loginString.data(using: String.Encoding.utf8)!
            let base64LoginString = loginData.base64EncodedString()
            
            return ["Authorization": "Basic \(base64LoginString)"]
        }
        
        if credential.oauthToken.isEmpty {
            let loginString = String(format: "%@:%@", credential.consumerKey, credential.consumerSecret)
            let loginData = loginString.data(using: String.Encoding.utf8)!
            let base64LoginString = loginData.base64EncodedString()
            
            return ["Authorization": "Basic \(base64LoginString)"]
        }
        
        return ["Authorization": "Bearer \(credential.oauthToken)"]
    }
}

public extension UIColor {
    static func appleBlue() -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                switch traitCollection.userInterfaceStyle {
                case .unspecified, .light:
                    return UIColor(red: 14.0 / 255, green: 122.0 / 255, blue: 254.0 / 255, alpha: 1.0)
                default:
                    return UIColor(red: 14.0 / 255, green: 122.0 / 255, blue: 254.0 / 255, alpha: 1.0)
                }
            }
        } else {
            return UIColor(red: 14.0 / 255, green: 122.0 / 255, blue: 254.0 / 255, alpha: 1.0)
        }
    }
    
    static func ravelryLightGreen() -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                switch traitCollection.userInterfaceStyle {
                case .unspecified, .light:
                    return UIColor(red: 234 / 255, green: 246 / 255, blue: 227 / 255, alpha: 1.0) /* #eaf6e3 */
                default:
                    return UIColor(red: 59 / 255, green: 117 / 255, blue: 70 / 255, alpha: 1.0) /* #3b7546 */
                }
            }
        } else {
            return UIColor(red: 234 / 255, green: 246 / 255, blue: 227 / 255, alpha: 1.0) /* #eaf6e3 */
        }
    }
    
    static func neutralBackground() -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                switch traitCollection.userInterfaceStyle {
                case .unspecified, .light:
                    return UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.6)
                default:
                    return UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.6)
                }
            }
        } else {
            return UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.6)
        }
    }
    
    static func ravelryLightGreenTransparent() -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                switch traitCollection.userInterfaceStyle {
                case .unspecified, .light:
                    return UIColor(red: 234 / 255, green: 246 / 255, blue: 227 / 255, alpha: 0.6) /* #eaf6e3 */
                default:
                    return UIColor(red: 59 / 255, green: 117 / 255, blue: 70 / 255, alpha: 0.6) /* #3b7546 */
                }
            }
        } else {
            return UIColor(red: 234 / 255, green: 246 / 255, blue: 227 / 255, alpha: 0.6) /* #eaf6e3 */
        }
    }
    
    static func darkBackground() -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                switch traitCollection.userInterfaceStyle {
                case .unspecified, .light:
                    return UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
                default:
                    return UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
                }
            }
        } else {
            return UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
        }
    }
    
    static func penColor() -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.label
        } else {
            return .black
        }
    }
    
    static func ravelryBackground() -> UIColor {
        if #available(iOS 13.0, *) {
            
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                switch traitCollection.userInterfaceStyle {
                case .unspecified, .light:
                    return UIColor(red: 234 / 255, green: 246 / 255, blue: 227 / 255, alpha: 1.0) /* #eaf6e3 */
                    //return UIColor(red: 234 / 255, green: 246 / 255, blue: 227 / 255, alpha: 0.6) /* #eaf6e3 */
                default:
                    return .systemBackground
                }
            }
            
        } else {
            return UIColor(red: 234 / 255, green: 246 / 255, blue: 227 / 255, alpha: 1.0) /* #eaf6e3 */
            
            //            return UIColor(red: 234 / 255, green: 246 / 255, blue: 227 / 255, alpha: 0.6) /* #eaf6e3 */
        }
    }
    
    static func ravelryBackgroundHeader() -> UIColor {
        if #available(iOS 13.0, *) {
            
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                switch traitCollection.userInterfaceStyle {
                case .unspecified, .light:
                    return UIColor(red: 202 / 255, green: 233 / 255, blue: 182 / 255, alpha: 0.9) /* #cae9b6 */
                default:
                    return .secondarySystemBackground
                }
            }
            
        } else {
            return UIColor(red: 202 / 255, green: 233 / 255, blue: 182 / 255, alpha: 0.9) /* #cae9b6 */
        }
    }
    
    static func ravelryGreen() -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                switch traitCollection.userInterfaceStyle {
                case .unspecified, .light:
                    return UIColor(red: 202 / 255, green: 233 / 255, blue: 182 / 255, alpha: 0.9) /* #cae9b6 */
                default:
                    return UIColor(red: 7 / 255, green: 63 / 255, blue: 17 / 255, alpha: 1.0) /* #073f11 */
                }
            }
        } else {
            return UIColor(red: 202 / 255, green: 233 / 255, blue: 182 / 255, alpha: 0.9) /* #cae9b6 */
        }
    }
    
    
    static func ravelryHighlightPen() -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                switch traitCollection.userInterfaceStyle {
                case .unspecified, .light:
                    return .white
                default:
                    return  .black
                }
            }
        } else {
            return .white
        }
    }
    
    
    static func ravelryHighlight() -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                switch traitCollection.userInterfaceStyle {
                case .unspecified, .light:
                    return UIColor(red: 201 / 255, green: 51 / 255, blue: 89 / 255, alpha: 1.0) /* #c93359 */
                default:
                    return      UIColor(red: 255/255, green: 201/255, blue: 66/255, alpha: 1.0) /* #ffc942 */
                }
            }
        } else {
            return UIColor(red: 201 / 255, green: 51 / 255, blue: 89 / 255, alpha: 1.0) /* #c93359 */
        }
    }
    
    static func ravelryRed() -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                switch traitCollection.userInterfaceStyle {
                case .unspecified, .light:
                    return UIColor(red: 201 / 255, green: 51 / 255, blue: 89 / 255, alpha: 1.0) /* #c93359 */
                default:
                    return UIColor(red: 145 / 255, green: 37 / 255, blue: 64 / 255, alpha: 1.0) /* #912540 */
                }
            }
        } else {
            return UIColor(red: 201 / 255, green: 51 / 255, blue: 89 / 255, alpha: 1.0) /* #c93359 */
        }
    }
}
public extension Date {
    func timeAgoSinceDate(_ numericDates: Bool = false) -> String {
        let calendar = NSCalendar.current
        let unitFlags: Set<Calendar.Component> = [.minute, .hour, .day, .weekOfYear, .month, .year, .second]
        let now = NSDate()
        let earliest = now.earlierDate(self)
        let latest = (earliest == now as Date) ? self : now as Date
        let components = calendar.dateComponents(unitFlags, from: earliest as Date, to: latest as Date)
        
        if components.year! >= 2 {
            return "\(components.year!) years ago"
        } else if components.year! >= 1 {
            if numericDates {
                return "1 year ago"
            } else {
                return "Last year"
            }
        } else if components.month! >= 2 {
            return "\(components.month!) months ago"
        } else if components.month! >= 1 {
            if numericDates {
                return "1 month ago"
            } else {
                return "Last month"
            }
        } else if components.weekOfYear! >= 2 {
            return "\(components.weekOfYear!) weeks ago"
        } else if components.weekOfYear! >= 1 {
            if numericDates {
                return "1 week ago"
            } else {
                return "Last week"
            }
        } else if components.day! >= 2 {
            return "\(components.day!) days ago"
        } else if components.day! >= 1 {
            if numericDates {
                return "1 day ago"
            } else {
                return "Yesterday"
            }
        } else if components.hour! >= 2 {
            return "\(components.hour!) hours ago"
        } else if components.hour! >= 1 {
            if numericDates {
                return "1 hour ago"
            } else {
                return "An hour ago"
            }
        } else if components.minute! >= 2 {
            return "\(components.minute!) min. ago"
        } else if components.minute! >= 1 {
            if numericDates {
                return "1 minute ago"
            } else {
                return "A minute ago"
            }
        } else if components.second! >= 3 {
            return "\(components.second!) sec. ago"
        } else {
            return "Just now"
        }
    }
}

extension String {
    var parseJSONString: AnyObject? {
        let data = self.data(using: String.Encoding.utf8, allowLossyConversion: false)
        if let jsonData = data { do {
            let message = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
            if let jsonResult = message as? NSMutableArray {
                print(jsonResult)
                return jsonResult
            }
            
            if let jsonResult = message as? NSMutableDictionary {
                print(jsonResult)
                return jsonResult
            }
            return nil
        } catch let error as NSError {
            print("An error occurred: \(error)")
            return nil
        }
        } else {
            return nil
        }
    }
}

