//
//  GitHubURLFactory.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

public class GitHubEndpoints {
    
    public enum Endpoint {
        case Users
        case Repos
        case PullRequests
        case Issues
        case Branches
        case Commits
        case Statuses
        case IssueComments
        case Merges
    }
    
    public enum MergeResult {
        case Success(NSDictionary)
        case NothingToMerge
        case Conflict
        case Missing(String)
    }
    
    private let baseURL: String
    private let token: String?
    
    public init(baseURL: String, token: String?) {
        self.baseURL = baseURL
        self.token = token
    }
    
    private func endpointURL(endpoint: Endpoint, params: [String: String]? = nil) -> String {
        
        switch endpoint {
        case .Users:
            
            if let user = params?["user"] {
                return "/users/\(user)"
            } else {
                return "/user"
            }
        
            //FYI - repo must be in its full name, e.g. czechboy0/Buildasaur, not just Buildasaur
        case .Repos:
            
            if let repo = params?["repo"] {
                return "/repos/\(repo)"
            } else {
                let user = self.endpointURL(.Users, params: params)
                return "\(user)/repos"
            }
            
        case .PullRequests:
            
            assert(params?["repo"] != nil, "A repo must be specified")
            let repo = self.endpointURL(.Repos, params: params)
            let pulls = "\(repo)/pulls"
            
            if let pr = params?["pr"] {
                return "\(pulls)/\(pr)"
            } else {
                return pulls
            }
            
        case .Issues:
            
            assert(params?["repo"] != nil, "A repo must be specified")
            let repo = self.endpointURL(.Repos, params: params)
            let issues = "\(repo)/issues"
            
            if let issue = params?["issue"] {
                return "\(issues)/\(issue)"
            } else {
                return issues
            }
            
        case .Branches:
            
            let repo = self.endpointURL(.Repos, params: params)
            let branches = "\(repo)/branches"
            
            if let branch = params?["branch"] {
                return "\(branches)/\(branch)"
            } else {
                return branches
            }
            
        case .Commits:
            
            let repo = self.endpointURL(.Repos, params: params)
            let commits = "\(repo)/commits"
            
            if let commit = params?["commit"] {
                return "\(commits)/\(commit)"
            } else {
                return commits
            }
            
        case .Statuses:
            
            let sha = params!["sha"]!
            let method = params?["method"]
            if let method = method {
                if method == HTTP.Method.POST.rawValue {
                    //POST, we need slightly different url
                    let repo = self.endpointURL(.Repos, params: params)
                    return "\(repo)/statuses/\(sha)"
                }
            }
            
            //GET, default
            let commits = self.endpointURL(.Commits, params: params)
            return "\(commits)/\(sha)/statuses"
            
        case .IssueComments:
            
            let issues = self.endpointURL(.Issues, params: params)
            let comments = "\(issues)/comments"
            
            if let comment = params?["comment"] {
                return "\(comments)/\(comment)"
            } else {
                return comments
            }
            
        case .Merges:
            
            assert(params?["repo"] != nil, "A repo must be specified")
            let repo = self.endpointURL(.Repos, params: params)
            return "\(repo)/merges"
        }
    }
    
    
    public func createRequest(method:HTTP.Method, endpoint:Endpoint, params: [String : String]? = nil, query: [String : String]? = nil, body:NSDictionary? = nil) throws -> NSMutableURLRequest {
        
        let endpointURL = self.endpointURL(endpoint, params: params)
        let queryString = HTTP.stringForQuery(query)
        let wholePath = "\(self.baseURL)\(endpointURL)\(queryString)"
        
        let url = NSURL(string: wholePath)!
        
        let request = NSMutableURLRequest(URL: url)
        
        request.HTTPMethod = method.rawValue
        if let token = self.token {
            request.setValue("token \(token)", forHTTPHeaderField:"Authorization")
        }
        
        if let body = body {
            
            let data = try NSJSONSerialization.dataWithJSONObject(body, options: NSJSONWritingOptions())
            request.HTTPBody = data
        }
        
        return request
    }
}
