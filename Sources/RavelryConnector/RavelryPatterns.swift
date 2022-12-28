import Foundation
import OAuthSwift
import Cache 

public struct PatternCache : Codable {
    var history = [Date:Int]()
    static   var storagePatterns : Storage<String,PatternCache>!
    
    static func initCacheIfRequired() {
        if storagePatterns == nil {
            let diskConfig = DiskConfig(name: "patcache")
            storagePatterns = try? Storage<String,PatternCache>(
                diskConfig: diskConfig, memoryConfig: MemoryConfig(),
                transformer: TransformerFactory.forCodable(ofType: PatternCache.self)
            )
        }
    }
    
    static func storePosition(_ permalink: String, timestamp: Date, position: Int) {
        initCacheIfRequired()
        do {
            if try storagePatterns.existsObject(forKey: permalink) {
                let obj = try storagePatterns.object(forKey: permalink)
                var newObj = obj
                var toremove = [Date]()
                for d in newObj.history {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH"
                    let f1 = formatter.string(from: d.key)
                    let f2 = formatter.string(from: timestamp)
                    if f1 == f2 {
                        toremove.append(d.key)
                    }
                }
                for d in toremove {
                    newObj.history.removeValue(forKey: d)
                }
                newObj.history[timestamp] = position
                try storagePatterns.setObject(newObj, forKey: permalink)
            } else {
                var obj = PatternCache()
                obj.history[timestamp] = position
                try storagePatterns.setObject(obj, forKey: permalink)
            }
        }catch let err {
            print(err)
        }
    }
    
    static func getHistory(_ permalink: String) -> [Date:Int] {
        initCacheIfRequired()

        do {
            if try storagePatterns.existsObject(forKey: permalink) {
                let obj = try storagePatterns.object(forKey: permalink)
                return obj.history
             }
        }catch let err {
            print(err)
        }
        return [Date:Int]()
    }
    
   static  func hoursFromNow(_ A: Date) -> Int {
           let dc = Calendar.current.dateComponents([.day,.hour], from: A, to: Date())
           return dc.day! * 24 + dc.hour!
       }
 static   func minutesFromNow(_ A: Date) -> Int {
           let dc = Calendar.current.dateComponents([.day,.hour, .minute], from: A, to: Date())
           return dc.day! * 24 * 60  + dc.hour! * 60 + dc.minute!
         }
       
    static func getTrend(_ permalink : String) -> PatternTrend? {
        let history = getHistory(permalink)
        var historyDates = history.keys.sorted { (A, B) -> Bool in
            let h1 = minutesFromNow(A)
            let h2 = minutesFromNow(B)
            return h1 > h2
        }
        let now = Date()
       /* historyDates.removeAll { (A) -> Bool in
              let c = Calendar.current.dateComponents([.hour], from: A, to: now).hour!
            return c > 14 * 24
        }*/
        var xs = [Double]()
        var ys = [Double]()
        for date in historyDates {
            let h = minutesFromNow(date)
           let position = history[date]!
            xs.append(Double(-h)/60)
            ys.append(Double(-position))
        }
        let slopevalue = slope(xs,ys)
        print(slopevalue)
        switch slopevalue {
        case let x where x < -1 :
            return .fallingMuch
        case let x where x > 1:
            return .risingMuch
        case let x where x < -0.01 :
            return .falling
        case let x where x > 0.01:
            return .rising
        default:
            if ys.count == 1 {
                return .none
            } else {
                return .stable
            }
        }
        //print(slope(xs, ys))
       // return nil
    }
    
    
    static   func average(_ input: [Double]) -> Double {
        return input.reduce(0, +) / Double(input.count)
    }
    static func multiply(_ a: [Double], _ b: [Double]) -> [Double] {
        return zip(a,b).map(*)
    }
    static  func linearRegression(_ xs: [Double], _ ys: [Double]) -> (Double) -> Double {
        let sum1 = average(multiply(ys, xs)) - average(xs) * average(ys)
        let sum2 = average(multiply(xs, xs)) - pow(average(xs), 2)
        let slope = sum1 / sum2
        let intercept = average(ys) - slope * average(xs)
        return { x in intercept + slope * x }
    }
    static  func slope(_ xs: [Double], _ ys: [Double]) ->   Double {
        let sum1 = average(multiply(ys, xs)) - average(xs) * average(ys)
        let sum2 = average(multiply(xs, xs)) - pow(average(xs), 2)
       return   sum1 / sum2
    }
}

enum PatternTrend {
    case  risingMuch, rising, fallingMuch, falling,  stable
}



public extension RavelryEnvironment {
    
    
    func getPatternCategories(completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/pattern_categories/list.json", completedRequest: completedRequest)
    }
    
    func getPatternAttributes(completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/pattern_attributes/groups.json", completedRequest: completedRequest)
    }
    
    func getPatternSourcePatterns(patternsource_id: Int, page: Int, page_size: Int,
                                  completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["page"] = page
        parameters["page_size"] = page_size
        
        getPaginatedRequest(resultsKey: "patterns", url: "\(baseURI)/pattern_sources/\(patternsource_id)/patterns.json", parameters: parameters, completedRequest: completedRequest)
    }
    
    func searchPatternSources(query: String, page: Int, page_size: Int,
                              completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["query"] = query
        parameters["page"] = page
        parameters["page_size"] = page_size
        
        getPaginatedRequest(resultsKey: "patterns", url: "\(baseURI)/pattern_sources/search.json", parameters: parameters, completedRequest: completedRequest)
    }
    
    func showPatternSource(patternsource_id: Int,
                           completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/pattern_sources/\(patternsource_id).json", completedRequest: completedRequest)
    }
    
    func getPatternComments(identifier: Int, sort: String, include: [String], page: Int, page_size: Int,
                            completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["include"] = include.joined(separator: " ")
        parameters["sort"] = sort
        parameters["page"] = page
        parameters["page_size"] = page_size
        
        getPaginatedRequest(resultsKey: "comments", url: "\(baseURI)/patterns/\(identifier)/comments.json",
            parameters: parameters, completedRequest: completedRequest)
    }
    
    func getMultiPatternDetails(identifiers: [String], completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["ids"] = identifiers.joined(separator: " ")
        
        getSimpleRequest(url: "\(baseURI)/pattern.json", parameters: parameters, completedRequest: completedRequest)
    }
    
    func getProjectsForPattern(identifier: Int, sort: String, photoless: Bool, page: Int, page_size: Int,
                               completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["photoless"] = photoless
        parameters["sort"] = sort
        parameters["page"] = page
        parameters["page_size"] = page_size
        
        getPaginatedRequest(resultsKey: "projects", url: "\(baseURI)/patterns/\(identifier)/projects.json",
            parameters: parameters, completedRequest: completedRequest)
    }
    
    func searchPatterns(query: String, sort: String, additionalParameters: [String: String]? = nil, page: Int, page_size: Int,
                        completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        if let a = additionalParameters {
            parameters = a
        }
        parameters["query"] = query
        parameters["extras"] = 1
        
        parameters["sort"] = sort
        parameters["page"] = page
        parameters["personal_attributes"] = 1
        parameters["page_size"] = page_size
        
        print("pattern search parameters : \(parameters.description)")
        
        
        getPaginatedRequest(resultsKey: "patterns", url: "\(baseURI)/patterns/search.json", parameters: parameters, completedRequest: completedRequest)
    }
    
    func showPattern(identifier: Int, include _: [String],
                     completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/patterns/\(identifier).json", completedRequest: completedRequest)
    }
    
    func showPattern(name: String, include _: [String],
                     completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/patterns/\(name).json", completedRequest: completedRequest)
    }
}
