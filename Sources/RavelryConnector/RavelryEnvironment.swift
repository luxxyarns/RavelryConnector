// Ravelry Connector - to help connecting with the Ravelry API: https://www.ravelry.com/api
// (C) 2022 by Marco Nissen

import Cache
import Foundation
import KeychainSwift
import OAuthSwift
import UIKit
import OSLog

public class RavelryEnvironment: ObservableObject {
    public typealias SuccessHandler = (_ response: OAuthSwiftResponse) -> Void
    public typealias FailureHandler = (_ error: OAuthSwiftError) -> Void
    var baseURI = "https://api.ravelry.com"
    public var identifier: String = ""
    var authorizeURI: String = ""
    var tokenURI: String = ""
    var scope: String = ""
    var oauth1swift: OAuth1Swift?
    var oauth2swift: OAuth2Swift?
    var callback: String = ""
    var oauthMode: RavelryOauthMode = .oauth2
    var requestTokenUrl: String = ""
    var authorizeUrl: String = ""
    var accessTokenUrl: String = ""
    var forumPageSize: Int = 25
    var storage: Storage<String, EtagData>?
    var storageForumDescription: Storage<String, ForumDescription>?
    
    public init(identifier: String,
                consumerKey: String,
                consumerSecret: String,
                requestTokenUrl: String,
                authorizeUrl: String,
                accessTokenUrl: String,
                scope: String,
                callback: String) {
        self.identifier = identifier
        self.callback = callback
        self.oauthMode = .oauth1
        self.requestTokenUrl = requestTokenUrl + "?scope=" + scope.replacingOccurrences(of: " ", with: "%20")
        self.authorizeUrl = authorizeUrl
        self.accessTokenUrl = accessTokenUrl
        self.scope = scope.replacingOccurrences(of: " ", with: "%20")
        self.oauth2swift = nil
        self.oauth1swift = OAuth1Swift(consumerKey: consumerKey,
                                       consumerSecret: consumerSecret,
                                       requestTokenUrl: self.requestTokenUrl,
                                       authorizeUrl: self.authorizeUrl,
                                       accessTokenUrl: self.accessTokenUrl)
        
        let diskConfig = DiskConfig(name: "hardware")
        let diskConfig2 = DiskConfig(name: "hardwareForumDescription")
        let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
        
        self.storage = try? Storage<String,EtagData>(
            diskConfig: diskConfig,
            memoryConfig: memoryConfig,
            transformer: TransformerFactory.forCodable(ofType: EtagData.self)
        )
        self.storageForumDescription = try? Storage<String,ForumDescription>(
            diskConfig: diskConfig2,
            memoryConfig: memoryConfig,
            transformer: TransformerFactory.forCodable(ofType: ForumDescription.self)
        )
    }
    
    public init(identifier: String,
                clientID: String,
                secretID: String,
                authorizeURI: String,
                tokenURI: String,
                scope: String,
                callback: String) {
        self.identifier = identifier
        self.authorizeURI = authorizeURI
        self.callback = callback
        self.oauthMode = .oauth2
        self.tokenURI = tokenURI
        self.scope = scope
        self.oauth1swift = nil
        self.oauth2swift = OAuth2Swift(
            consumerKey: clientID,
            consumerSecret: secretID,
            authorizeUrl: self.authorizeURI,
            accessTokenUrl: self.tokenURI,
            responseType: "code"
        )
        let diskConfig = DiskConfig(name: "hardware")
        let diskConfig2 = DiskConfig(name: "hardwareForumDescription")
        let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
        
        self.storage = try? Storage<String,EtagData>(
            diskConfig: diskConfig,
            memoryConfig: memoryConfig,
            transformer: TransformerFactory.forCodable(ofType: EtagData.self)
        )
        self.storageForumDescription = try? Storage<String,ForumDescription>(
            diskConfig: diskConfig2,
            memoryConfig: memoryConfig,
            transformer: TransformerFactory.forCodable(ofType: ForumDescription.self)
        )
        
        if let oauthswift = self.oauth2swift {
            oauthswift.client.credential.headersFactory = XHeaders(credential: oauthswift.client.credential)
            oauthswift.allowMissingStateCheck = true
        }
    }
    
    
    public func storeToCache(value: EtagData, forKey: String) throws {
        if let s = storage {
            try s.setObject(value, forKey: forKey)
        }
    }
    
    public func readFromCache(_ forKey: String) throws -> EtagData? {
        if let s = storage {
            return try s.object(forKey: forKey)
        }
        return nil
    }
    
    
    public func storeForumDescriptionToCache(value: ForumDescription, forKey: String) throws {
        if let s = storageForumDescription {
            try s.setObject(value, forKey: forKey)
        }
    }
    
    public func readForumDescriptionFromCache(_ forKey: String) throws -> ForumDescription? {
        if let s = storageForumDescription {
            let result =  try s.object(forKey: forKey)
            let oldDate = result.date
            if let diff = Calendar.current.dateComponents([.day,.second], from: oldDate, to: Date()).day {
                if diff > 14 {
                    return nil
                }
            }
            return result
        }
        return nil
    }
    
    
    public func authorizeIfNeeded(_ completedRequest: @escaping () -> Void,
                                  failedRequest: @escaping () -> Void) {
        if let oa = self.oauth1swift {
            oa.authorizeURLHandler = SafariURLHandler(viewController: UIViewController.getCurrentController(), oauthSwift: oa)
            let token = oa.client.credential.oauthToken
            if token == "" {
                authorize(completedRequest, failedRequest: failedRequest)
            } else {
                completedRequest()
            }
        }
        if let oa = self.oauth2swift {
            let token = oa.client.credential.oauthToken
            if token == "" {
                authorize(completedRequest, failedRequest: failedRequest)
            } else {
                completedRequest()
            }
        }
    }
    
    public func authorize(_ completedRequest: @escaping () -> Void,
                          failedRequest: @escaping () -> Void) {
        let stateItem = randomString(length: 20)
        if let oa = self.oauth2swift {
            oa.authorize(withCallbackURL: URL(string: callback)!,
                         scope: scope,
                         state: stateItem) { result in
                switch result {
                case .success:
                    self.storeCredentialsInKeychain()
                    completedRequest()
                case let .failure(error):
                    print(error)
                    failedRequest()
                }
            }
        }
        if let oa = self.oauth1swift {
            oa.authorize(withCallbackURL: URL(string: callback)!) { result in
                switch result {
                case .success:
                    completedRequest()
                case .failure:
                    let error = result.mapError { $0 }
                    print(error)
                    failedRequest()
                }
            }
        }
    }
    
    public func resetTokensInKeychain() {
        let keychain = KeychainSwift()
        if let oa = self.oauth2swift {
            keychain.delete("\(identifier):oauthToken")
            keychain.delete("\(identifier):oauthTokenSecret")
            keychain.delete("\(identifier):oauthRefreshToken")
            keychain.delete("\(identifier):oauthTokenExpiresAt")
            keychain.delete("\(identifier):focusedUser")
            oa.client.credential.oauthToken = ""
            oa.client.credential.oauthTokenSecret = ""
            oa.client.credential.oauthRefreshToken = ""
            oa.client.credential.oauthTokenExpiresAt = nil
            DispatchQueue.main.async {
                RavelryBase.shared.focusedUser = nil
            }
        }
        if let oa = self.oauth1swift {
            keychain.delete("\(identifier):oauth1Token")
            keychain.delete("\(identifier):oauth1TokenSecret")
            keychain.delete("\(identifier):oauth1TokenExpiresAt")
            keychain.delete("\(identifier):focusedUser")
            oa.client.credential.oauthToken = ""
            oa.client.credential.oauthTokenSecret = ""
            oa.client.credential.oauthTokenExpiresAt = nil
            DispatchQueue.main.async {
                RavelryBase.shared.focusedUser = nil
            }
            
        }
    }
    
    public  func storeCredentialsInKeychain() {
        let keychain = KeychainSwift()
        if let oa = self.oauth1swift {
            keychain.set(oa.client.credential.oauthToken, forKey: "\(identifier):oauth1Token", withAccess: .accessibleAfterFirstUnlock)
            keychain.set(oa.client.credential.oauthTokenSecret, forKey: "\(identifier):oauth1TokenSecret", withAccess: .accessibleAfterFirstUnlock)
            if let exp = oa.client.credential.oauthTokenExpiresAt {
                keychain.set(String(Int(exp.timeIntervalSince1970)), forKey: "\(identifier):oauth1TokenExpiresAt", withAccess: .accessibleAfterFirstUnlock)
            }
            if let f = RavelryBase.shared.focusedUser {
                keychain.set(f, forKey: "\(identifier):focusedUser", withAccess: .accessibleAfterFirstUnlock)
            }
        }
        if let oa = self.oauth2swift {
            keychain.set(oa.client.credential.oauthToken, forKey: "\(identifier):oauthToken", withAccess: .accessibleAfterFirstUnlock)
            keychain.set(oa.client.credential.oauthTokenSecret, forKey: "\(identifier):oauthTokenSecret", withAccess: .accessibleAfterFirstUnlock)
            keychain.set(oa.client.credential.oauthRefreshToken, forKey: "\(identifier):oauthRefreshToken", withAccess: .accessibleAfterFirstUnlock)
            if let exp = oa.client.credential.oauthTokenExpiresAt {
                keychain.set(String(Int(exp.timeIntervalSince1970)), forKey: "\(identifier):oauthTokenExpiresAt", withAccess: .accessibleAfterFirstUnlock)
            }
            if let f = RavelryBase.shared.focusedUser {
                keychain.set(f, forKey: "\(identifier):focusedUser", withAccess: .accessibleAfterFirstUnlock)
            }
        }
        
        print("storeCredentialsInKeychain   , user: \(RavelryBase.shared.focusedUser ?? "<not yet defined>")")
        
    }
    
    public func get(url: URLConvertible, headers: OAuthSwift.Headers, parameters: OAuthSwift.Parameters? = nil, success: @escaping RavelryEnvironment.SuccessHandler, failure: @escaping RavelryEnvironment.FailureHandler) {
        print("call get \(url)")
        enqueueRequest(url: url, headers: headers, method: .GET, parameters: parameters, success: success, failure: failure)
    }
    
    public func post(url: URLConvertible, parameters: OAuthSwift.Parameters? = nil, success: @escaping RavelryEnvironment.SuccessHandler, failure: @escaping RavelryEnvironment.FailureHandler) {
        print("call post")
        enqueueRequest(url: url, method: .POST, parameters: parameters, success: success, failure: failure)
    }
    
    public func postMultipart(url: URLConvertible, parameters: OAuthSwift.Parameters, multiparts: [OAuthSwiftMultipartData],
                              success: @escaping RavelryEnvironment.SuccessHandler,
                              failure: @escaping RavelryEnvironment.FailureHandler) {
        if let oa = self.oauth2swift {
            oa.client.postMultiPartRequest(url,
                                           method: .POST,
                                           parameters: parameters,
                                           multiparts: multiparts,
                                           checkTokenExpiration: false) { result in
                switch result {
                case let .success(result):
                    success(result)
                case let .failure(error):
                    failure(error)
                }
            }
        }
        if let oa = self.oauth1swift {
            oa.client.postMultiPartRequest(url,
                                           method: .POST,
                                           parameters: parameters,
                                           multiparts: multiparts,
                                           checkTokenExpiration: false) { result in
                switch result {
                case let .success(result):
                    success(result)
                case let .failure(error):
                    failure(error)
                }
            }
        }
    }
    
    public func delete(url: URLConvertible, parameters: OAuthSwift.Parameters? = nil, success: @escaping RavelryEnvironment.SuccessHandler, failure: @escaping RavelryEnvironment.FailureHandler) {
        authorizeRequest(url: url, method: .DELETE, parameters: parameters, success: success, failure: failure)
    }
    
    struct RequestQueuePackage {
        var url: URLConvertible
        var headers: OAuthSwift.Headers?
        var method: OAuthSwiftHTTPRequest.Method
        var parameters: OAuthSwift.Parameters?
        var success: RavelryEnvironment.SuccessHandler
        var failure: RavelryEnvironment.FailureHandler
    }
    
    var runningRequest: RequestQueuePackage?
    var requestQueue = [RequestQueuePackage]()
    
    public func enqueueRequest(url: URLConvertible,
                               headers: OAuthSwift.Headers? = nil,
                               method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters?, success: @escaping RavelryEnvironment.SuccessHandler, failure: @escaping RavelryEnvironment.FailureHandler) {
        print("item added to queue: \(url)")
        let item = RequestQueuePackage(url: url,
                                       headers: headers,
                                       method: method,
                                       parameters: parameters,
                                       success: success,
                                       failure: failure)
        requestQueue.append(item)
        checkRequestQueue()
    }
    
    public func checkRequestQueue() {
        if runningRequest == nil {
            print("checking request queue, request queue size \(requestQueue.count)")
            if let runningRequest = requestQueue.popLast() {
                print("processing request queue item \(runningRequest.url)")
                authorizeRequest(url: runningRequest.url,
                                 headers: runningRequest.headers,
                                 method: runningRequest.method,
                                 parameters: runningRequest.parameters,
                                 success: runningRequest.success,
                                 failure: runningRequest.failure)
            }
        } else {
            print("checking request skipped because of running request ")
        }
    }
    
    public func authorizeRequest(url: URLConvertible,
                                 headers: OAuthSwift.Headers? = nil,
                                 method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters?, success: @escaping RavelryEnvironment.SuccessHandler, failure: @escaping RavelryEnvironment.FailureHandler) {
        print("authorizeRequest \(url) , user: \(RavelryBase.shared.focusedUser ?? "<not yet defined>")")
        
        if oauth2swift != nil {
            authorizeIfNeeded({
                if let oa = self.oauth2swift {
                    var p = OAuthSwift.Parameters()
                    if parameters != nil { p = parameters! }
                    print("invoke startAuthorizedRequest")
                    
                    oa.startAuthorizedRequest(url,
                                              method: method,
                                              parameters: p,
                                              headers: headers) { result in
                        switch result {
                        case let .success(result):
                            success(result)
                            self.runningRequest = nil
                            self.checkRequestQueue()
                        case let .failure(error):
                            failure(error)
                            self.runningRequest = nil
                            self.checkRequestQueue()
                        }
                    }
                }
                
            }) {
                self.runningRequest = nil
                self.checkRequestQueue()
                
                failure(OAuthSwiftError.cancelled)
            }
        }
        
        if let oa = self.oauth1swift {
            print("invoke startAuthorizedRequest")
            
            if oa.client.credential.oauthToken != "", !oa.client.credential.isTokenExpired() {
                switch method {
                case .GET:
                    
                    
                    if let p = parameters {
                        oa.client.get(url, parameters: p, headers: headers) { result in
                            switch result {
                            case let .success(result):
                                success(result)
                            case let .failure(error):
                                failure(error)
                                self.displayErrorMessage(error: error, url: url, method: method, parameters: parameters, success: success, failure: failure)
                            }
                            self.runningRequest = nil
                            self.checkRequestQueue()
                        }
                    } else {
                        oa.client.get(url, headers: headers) { result in
                            switch result {
                            case let .success(result):
                                success(result)
                            case let .failure(error):
                                failure(error)
                                self.displayErrorMessage(error: error, url: url, method: method, parameters: parameters, success: success, failure: failure)
                            }
                            self.runningRequest = nil
                            self.checkRequestQueue()
                        }
                    }
                case .POST:
                    if let p = parameters {
                        oa.client.post(url, parameters: p, headers: headers) { result in
                            switch result {
                            case let .success(result):
                                success(result)
                            case let .failure(error):
                                failure(error)
                                self.displayErrorMessage(error: error, url: url, method: method, parameters: parameters, success: success, failure: failure)
                            }
                            self.runningRequest = nil
                            self.checkRequestQueue()
                        }
                    } else {
                        oa.client.post(url, headers: headers) { result in
                            switch result {
                            case let .success(result):
                                success(result)
                            case let .failure(error):
                                failure(error)
                                self.displayErrorMessage(error: error, url: url, method: method, parameters: parameters, success: success, failure: failure)
                            }
                            self.runningRequest = nil
                            self.checkRequestQueue()
                        }
                    }
                case .DELETE:
                    if let p = parameters {
                        oa.client.delete(url, parameters: p, headers: headers) { result in
                            switch result {
                            case let .success(result):
                                success(result)
                            case let .failure(error):
                                failure(error)
                                self.displayErrorMessage(error: error, url: url, method: method, parameters: parameters, success: success, failure: failure)
                            }
                            self.runningRequest = nil
                            self.checkRequestQueue()
                        }
                        
                    } else {
                        oa.client.delete(url, headers: headers) { result in
                            switch result {
                            case let .success(result):
                                success(result)
                            case let .failure(error):
                                failure(error)
                                self.displayErrorMessage(error: error, url: url, method: method, parameters: parameters, success: success, failure: failure)
                            }
                            self.runningRequest = nil
                            self.checkRequestQueue()
                        }
                    }
                default:
                    print("not yet supported")
                }
            } else {
                let item = RequestQueuePackage(url: url,
                                               headers: headers,
                                               method: method,
                                               parameters: parameters,
                                               success: success,
                                               failure: failure)
                runningRequest = item // to prevent any other request to take over !
                
                oa.authorize(withCallbackURL: callback) { result in
                    switch result {
                    case let .success(result):
                        self.storeCredentialsInKeychain()
                        
                        print(result)
                        self.runningRequest = nil
                        self.enqueueRequest(url: url, method: method, parameters: parameters, success: success, failure: failure)
                    case let .failure(error):
                        print(error)
                        self.runningRequest = nil
                        self.displayErrorMessage(error: error, url: url, method: method, parameters: parameters, success: success, failure: failure)
                    }
                    self.checkRequestQueue()
                }
            }
        }
    }
    
    func displayErrorMessage(error: OAuthSwiftError, url: URLConvertible,
                             headers: OAuthSwift.Headers? = nil,
                             method: OAuthSwiftHTTPRequest.Method,
                             parameters: OAuthSwift.Parameters?,
                             success: @escaping RavelryEnvironment.SuccessHandler,
                             failure: @escaping RavelryEnvironment.FailureHandler) {
        print(error.localizedDescription)
        print(url)
        RavelryBase.shared.errorTitle = "failure"
        RavelryBase.shared.errorMessage = "Could not successfully request data from Ravelry"
        RavelryBase.shared.displayError = true
    }
    
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< length).map { _ in letters.randomElement()! })
    }
    
    public func deleteSimpleRequest(url: URLConvertible, parameters: OAuthSwift.Parameters? = nil, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        if let env = RavelryBase.shared.getCurrentEnvironment() {
            env.delete(url: url, parameters: parameters, success: { response in
                do {
                    if let res = try response.jsonObject() as? [String: Any] {
                        return completedRequest(res)
                    }
                } catch let err {
                    print(err)
                    completedRequest(nil)
                }
                completedRequest(nil)
            }) { err in
                print(err)
                completedRequest(nil)
            }
        }
    }
    
    public func getSimpleRequest(url: URLConvertible, parameters: OAuthSwift.Parameters? = nil, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var checkingURLKey: String?
        var foundEtagKey: String?
        var foundEtagData : String?
        let uc = URLComponents(string: url.string)
        if !url.string.contains("current_user") {
            if let uc = uc {
                if let p = parameters {
                    if var qi = uc.queryItems {
                        for anItem in p {
                            if let value = anItem.value as? String {
                                qi.append(URLQueryItem(name: anItem.key, value: value))
                            }
                        }
                    }
                }
                if let url = uc.url {
                    checkingURLKey = url.absoluteString
                    if let checkingURLKey = checkingURLKey {
                        do {
                            if let etag = try self.readFromCache(checkingURLKey) {
                                foundEtagKey = etag.etag
                                foundEtagData = etag.json
                                if checkingURLKey.contains("get.json") {
                                    // foundEtagKey = nil
                                }
                            }
                        } catch {
                            print(error)
                        }
                    }
                }
            }
        }
        
        if let env = RavelryBase.shared.getCurrentEnvironment() {
            var headers = OAuthSwift.Headers()
            if let etag = foundEtagKey {
                headers["If-None-Match"] = etag
            }
            env.get(url: url, headers: headers, parameters: parameters, success: { response in
                do {
                    if  response.response.statusCode  == 304 {
                        if let jsonString = foundEtagData {
                            if  let data = jsonString.data(using: .utf8, allowLossyConversion: false)  {
                                if let res =  try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:Any]{
                                    return completedRequest(res)
                                }
                            }
                        }
                    }
                    
                    if let res = try response.jsonObject() as? [String: Any] {
                        env.checkExtras(res)
                        
                        if let _ = uc, let checkingURLKey = checkingURLKey {
                            if let etag = (response.response.allHeaderFields)["Etag"] as? String {
                                let data1 = try JSONSerialization.data(withJSONObject: res, options: JSONSerialization.WritingOptions.prettyPrinted)
                                if let convertedString = String(data: data1, encoding: String.Encoding.utf8) {
                                    do {
                                        
                                        try self.storeToCache(value: EtagData(etag: etag, json:  convertedString), forKey: checkingURLKey)
                                    } catch {
                                        print(error)
                                    }
                                }
                            }
                        }
                        return completedRequest(res)
                    }
                } catch let err {
                    print(err)
                    //  print(headers)
                    
                    
                    return completedRequest(nil)
                }
                return completedRequest(nil)
            }) { err in
                print(err.errorCode)
                if err.errorCode == 403 {
                    env.authorize({
                        env.get(url: url, headers: OAuthSwift.Headers(), parameters: parameters, success: { response in
                            do {
                                if let res = try response.jsonObject() as? [String: Any] {
                                    return completedRequest(res)
                                }
                            } catch let err {
                                print(err)
                                return completedRequest(nil)
                            }
                            return completedRequest(nil)
                        }, failure: { _ in
                            completedRequest(nil)
                        })
                        
                        return
                        
                    }, failedRequest: {
                        completedRequest(nil)
                    })
                }
                return completedRequest(nil)
            }
        }
    }
    
    public func getPaginatedRequest(resultsKey: String, url: URLConvertible, parameters: OAuthSwift.Parameters? = nil,
                                    username: String? = nil, completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        if let env = RavelryBase.shared.getCurrentEnvironment() {
            env.get(url: url, headers: OAuthSwift.Headers(), parameters: parameters, success: { response in
                do {
                    if let res = try response.jsonObject() as? [String: Any] {
                        env.checkExtras(res)
                        
                        if resultsKey == "" {
                            if let paginator = res["paginator"] as? [String: Any] {
                                return completedRequest([res], paginator["page_count"]! as! Int, paginator["page"]! as! Int, paginator["page_size"]! as! Int, paginator["last_page"]! as! Int, paginator["results"]! as! Int)
                            }
                        }
                        
                        if let res2 = res[resultsKey] as? [[String: Any]],
                           let paginator = res["paginator"] as? [String: Any] {
                            var newResults = [[String: Any]]()
                            if let username = username {
                                for a in res2 {
                                    var newA = a
                                    var newU = [String: Any]()
                                    newU["username"] = username
                                    if newA["user"] == nil {
                                        newA["user"] = newU
                                    }
                                    newResults.append(newA)
                                }
                            } else {
                                newResults = res2
                            }
                            
                            return completedRequest(newResults, paginator["page_count"]! as! Int, paginator["page"]! as! Int, paginator["page_size"]! as! Int, paginator["last_page"]! as! Int, paginator["results"]! as! Int)
                        } else {
                            print("ISSUE: cannot obtain data for \(resultsKey)")
                            print("data is \(res)")
                            return   completedRequest(nil, 0, 0, 0, 0, 0)
                        }
                    }
                } catch let err {
                    print(err)
                    return  completedRequest(nil, 0, 0, 0, 0, 0)
                }
                return  completedRequest(nil, 0, 0, 0, 0, 0)
            }) { err in
                print(err)
                return  completedRequest(nil, 0, 0, 0, 0, 0)
            }
        }
    }
    
    public func checkExtras(_ json: [String: Any]?) {
        if let j = json {
            if let extras = j["extras"] as? [String: Any] {
                
                var unreadMessages = 0
                var unreadForumReplies = 0
                
                if let unread_messages = extras["unread_messages"] as? Int {
                    unreadMessages = unread_messages
                }
                if let unread_forum_replies = extras["unread_forum_replies"] as? Int {
                    unreadForumReplies = unread_forum_replies
                }
                DispatchQueue.main.async {
                    RavelryBase.shared.unreadMessages = unreadMessages
                    RavelryBase.shared.unreadForumReplies = unreadForumReplies
                }
                /*
                 let application = UIApplication.shared
                 if #available(iOS 10.0, *) {
                 let center = UNUserNotificationCenter.current()
                 center.requestAuthorization(options: [.badge, .alert, .sound]) { _, _ in }
                 } else {
                 application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil))
                 }
                 application.registerForRemoteNotifications()
                 application.applicationIconBadgeNumber = unreadMessages + unreadForumReplies
                 */
            }
        }
    }
    
    
    
    public func postSimpleRequest(url: URLConvertible, parameters: OAuthSwift.Parameters? = nil,
                                  completedRequest: @escaping (_ json: [String: Any]?) -> Void,
                                  failure: @escaping (_ err: OAuthSwiftError?) -> Void ) {
        if let env = RavelryBase.shared.getCurrentEnvironment() {
            env.post(url: url, parameters: parameters, success: { response in
                do {
                    if let res = try response.jsonObject() as? [String: Any] {
                        return completedRequest(res)
                    }
                } catch let err {
                    print(err)
                    completedRequest(nil)
                }
                completedRequest(nil)
            }) { err in
                print(err)
                //completedRequest(nil)
                failure(err)
            }
        }
    }
}



public enum RavelryOauthMode: String {
    case oauth1
    case oauth2
}

public struct EtagData : Codable {
    var etag : String
    var json: String
}

public struct ForumDescription : Codable {
    var name: String
    var banner_url: String
    var badge_url: String
    var identifier: Int
    var short_description: String
    var mature  : Int
    var date: Date
}

struct MessagesState: Codable {
    var unreadMessages: Int
    var unreadForumReplies: Int
}

extension UIViewController {
    static func getCurrentController() -> UIViewController {
        let application = UIApplication.shared
        for scene in application.connectedScenes {
            if #available(iOS 15.0, *) {
                if let scene = scene as? UIWindowScene,
                   let window = scene.keyWindow,
                   let rootController = window.rootViewController {
                    
                    if let presentedController = rootController.presentedViewController {
                        return presentedController
                    }
                    return rootController
                    
                }
            } else {
                // Fallback on earlier versions
                return UIViewController()
                
            }
        }
        return UIViewController()
    }
}
