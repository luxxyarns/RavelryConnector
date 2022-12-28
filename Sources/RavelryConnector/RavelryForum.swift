import Foundation
import OAuthSwift

public extension RavelryEnvironment {
    func showForum(forum_post_id: Int,
                   completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/forum_posts/\(forum_post_id).json?extras=1", completedRequest: completedRequest)
    }

    func getUnreadForumPosts(include: [String], page: Int, page_size: Int,
                             completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["include"] = include.joined(separator: " ")
        parameters["page"] = page
        parameters["page_size"] = page_size

        getPaginatedRequest(resultsKey: "posts", url: "\(baseURI)/forum_posts/unread.json", parameters: parameters, completedRequest: completedRequest)
    }

    func updateForumPost(
        forum_post_id: Int,
        data: OAuthSwift.Parameters,
        completedRequest: @escaping (_ json: [String: Any]?) -> Void
    ) {
        postSimpleRequest(url: "\(baseURI)/forum_posts/\(forum_post_id).json", parameters: data, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func updateForumPostVote(forum_post_id: Int,
                             vote: Int,
                             type: String,
                             source_url _: String? = nil,
                             completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["vote"] = vote
        parameters["type"] = type
        postSimpleRequest(url: "\(baseURI)/forum_posts/\(forum_post_id)/vote.json", parameters: parameters, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func getFilteredTopics(status: String, sort: String, page: Int, page_size: Int,
                           completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["status"] = status
        parameters["sort"] = sort
        parameters["extras"] = 1
        parameters["page"] = page
        parameters["page_size"] = page_size

        getPaginatedRequest(resultsKey: "topics", url: "\(baseURI)/forums/filtered_topics.json",
                            parameters: parameters, completedRequest: completedRequest)
    }

    func getForumSets(completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/forums/sets.json", completedRequest: completedRequest)
    }

    func getForumTopics(forum_id: Int, page: Int,
                        completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["page"] = page

        getPaginatedRequest(resultsKey: "topics", url: "\(baseURI)/forums/\(forum_id)/topics.json?extras=1",
                            parameters: parameters, completedRequest: completedRequest)
    }
    
    func obtainForumBanner(name: String, identifier: Int,
                           completed: @escaping (_ badgeURL : URL? ) -> Void ) {
        obtainForumDescription(name: name, identifier: identifier, tag: "banner_url", completed: completed)
    }
    func getForumShortDescription(name: String, identifier: Int) -> String? {
        do {
            if let badge = try self.readForumDescriptionFromCache(name) {
                return badge.short_description
            }
        } catch let err {
            print(err)
        }
        return nil
    }
    func obtainForumBadge(name: String, identifier: Int,
                          completed: @escaping (_ badgeURL : URL? ) -> Void ) {
        obtainForumDescription(name: name, identifier: identifier, tag: "badge_url", completed: completed)
    }
    
    func obtainForumDescription(name: String, identifier: Int, tag: String,
                          completed: @escaping (_ badgeURL : URL? ) -> Void ) {
         do {
            if let badge = try self.readForumDescriptionFromCache(name) {
                var urlString = badge.badge_url
                if tag.contains("banner") {
                    urlString = badge.banner_url
                }
                if tag.contains("short_description") {
                    urlString = badge.short_description
                }
                if let url = URL(string: urlString) {
                    completed(url)
                    return
                }
                completed(nil)
                return
            }
        } catch let err {
            print(err)
         }
         
        searchGroups(query: name.replacingOccurrences(of: "-", with: " ").lowercased(),
                     sort: "", page: 1, page_size: 100) { (json, pageCount, page, pageSize, lastPage, results) in
                        if let json = json, json.count > 0  {
                            var found = false
                            for set in json {
                                if  let checkIdentifier = set["forum_id"] as? Int,  checkIdentifier == identifier {
                                    var badge_url = ""
                                    var banner_url = ""
                                    var mature = -1
                                    var description = ""
                                    
                                    if  let url = set["badge_url"] as? String {
                                        badge_url = url
                                    }
                                    if  let url = set["banner_url"] as? String {
                                        banner_url = url
                                    }
                                    if  let text = set["short_description"] as? String {
                                        description = text
                                    }
                                    if  let flag = set["mature"] as? Int {
                                        mature = flag
                                    }
                                    found = true
                                    do {
                                        try self.storeForumDescriptionToCache(value: ForumDescription(name: name, banner_url: banner_url,  badge_url: badge_url, identifier: identifier, short_description: description, mature: mature,  date: Date()), forKey: name)
                                    } catch let err {
                                        print(err)
                                    }
                                    if let requiredTag = set[tag] as? String , let tagURL = URL(string: requiredTag) {
                                        completed(tagURL)
                                    }
                                    return
                                }
                            }
                        }
                        do {
                            var description = ""
                            switch identifier {
                            case 3,19666,1,2,4,5:
                                description = "Official Ravelry Forum"
                            default:
                                break;
                            }
                            try self.storeForumDescriptionToCache(value: ForumDescription(name: name, banner_url: "", badge_url: "", identifier: identifier, short_description: description, mature: 0, date: Date()), forKey: name)
                            
                            completed(nil)
                        } catch let err {
                            print(err)
                        }
        }
        
        
        
    }

    func searchGroups(query: String, sort: String, page: Int, page_size: Int,
                      completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["query"] = query
        parameters["sort"] = sort
        parameters["page"] = page
        parameters["page_size"] = page_size

        getPaginatedRequest(resultsKey: "groups", url: "\(baseURI)/groups/search.json", parameters: parameters, completedRequest: completedRequest)
    }

    func createTopic(forum_id _: Int,
                     title: String,
                     tag_list: [String],
                     body: String,
                     summary: String,
                     sticky: Bool,
                     locked: Bool,
                     archived: Bool,
                     completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["title"] = title
        parameters["tag_list"] = tag_list.joined(separator: " ")
        parameters["body"] = body
        parameters["summary"] = summary
        parameters["sticky"] = sticky
        parameters["locked"] = locked
        parameters["archived"] = archived

        postSimpleRequest(url: "\(baseURI)/topics/create.json", parameters: parameters, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func getTopicPostList(topic_id: Int, sort_reverse: Bool, include: [String], page: Int, page_size: Int,
                          completedRequest: @escaping (_ json: [[String: Any]]?, _ pageCount: Int, _ page: Int, _ pageSize: Int, _ lastPage: Int, _ results: Int) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["include"] = include.joined(separator: " ")
        parameters["sort_reverse"] = sort_reverse
        parameters["page"] = page
        parameters["extras"] = 1
        parameters["page_size"] = page_size

        getPaginatedRequest(resultsKey: "", url: "\(baseURI)/topics/\(topic_id)/posts.json", parameters: parameters, completedRequest: completedRequest)
    }

    func updateReadMarkerForTopic(topic_id: Int, last_read: Int, force: Bool?, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["last_read"] = last_read
        if let f = force {
            parameters["force"] = f
        }
        postSimpleRequest(url: "\(baseURI)/topics/\(topic_id)/read.json", parameters: parameters, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func replyToTopic(topic_id: Int, body: String, parent_post_id: Int? = nil, completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        var parameters = OAuthSwift.Parameters()
        parameters["body"] = body
        if let f = parent_post_id {
            parameters["parent_post_id"] = f
        }
        postSimpleRequest(url: "\(baseURI)/topics/\(topic_id)/reply.json", parameters: parameters, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }

    func showTopic(topic_id: Int,
                   completedRequest: @escaping (_ json: [String: Any]?) -> Void) {
        getSimpleRequest(url: "\(baseURI)/topics/\(topic_id).json", completedRequest: completedRequest)
    }
 
    func updateTopic(
        topic_id: Int,
        title: String,
        tag_list: [String],
        body: String,
        summary: String,
        sticky: Bool,
        locked: Bool,
        archived: Bool,
        completedRequest: @escaping (_ json: [String: Any]?) -> Void
    ) {
        var parameters = OAuthSwift.Parameters()
        parameters["body"] = body
        parameters["title"] = title
        parameters["tag_list"] = tag_list.joined(separator: " ")
        parameters["body"] = body
        parameters["summary"] = summary
        parameters["sticky"] = sticky
        parameters["locked"] = locked
        parameters["archived"] = archived
        postSimpleRequest(url: "\(baseURI)/topics/\(topic_id).json", parameters: parameters, completedRequest: completedRequest, failure:  { (err) in
            if err != nil { print ("error in post request: \(err!.description)") }
        })
    }
}
