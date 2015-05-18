//
//  GitHubSource.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 12/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

public class GitHubServer : GitServer {
    
    public let endpoints: GitHubEndpoints
    public var latestRateLimitInfo: GitHubRateLimit?

    public init(endpoints: GitHubEndpoints, http: HTTP? = nil) {
        
        self.endpoints = endpoints
        super.init(http: http)
    }
}

//TODO: from each of these calls, return a "cancellable" object which can be used for cancelling

//FYI - GitHub API has a rate limit of 5,000 requests per hour. should be more than enough, but keep it in mind
//when calling the API frequently.
extension GitHubServer {
    
    private func sendRequestWithPossiblePagination(request: NSURLRequest, accumulatedResponseBody: NSArray, completion: HTTP.Completion) {
        
        self.sendRequest(request) {
            (response, body, error) -> () in
            
            if error != nil {
                completion(response: response, body: body, error: error)
                return
            }
            
            if let arrayBody = body as? [AnyObject] {
                
                let newBody = accumulatedResponseBody.arrayByAddingObjectsFromArray(arrayBody)

                if let links = response?.allHeaderFields["Link"] as? String {
                    
                    //now parse page links
                    if let pageInfo = self.parsePageLinks(links) {
                        
                        //here look at the links and go to the next page, accumulate the body from this response
                        //and pass it through
                        
                        if let nextUrl = pageInfo[RelPage.Next] {
                            
                            let newRequest = request.mutableCopy() as! NSMutableURLRequest
                            newRequest.URL = nextUrl
                            self.sendRequestWithPossiblePagination(newRequest, accumulatedResponseBody: newBody, completion: completion)
                            return
                        }
                    }
                }
                
                completion(response: response, body: newBody, error: error)
            } else {
                completion(response: response, body: body, error: error)
            }
        }
    }
    
    enum RelPage: String {
        case First = "first"
        case Next = "next"
        case Previous = "previous"
        case Last = "last"
    }
    
    private func parsePageLinks(links: String) -> [RelPage: NSURL]? {
        
        var linkDict = [RelPage: NSURL]()
        
        for i in links.componentsSeparatedByString(",") {
            
            let link = i.componentsSeparatedByString(";")
            if link.count < 2 {
                continue
            }
            
            //url
            var urlString = link[0].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            if urlString.hasPrefix("<") && urlString.hasSuffix(">") {
                urlString = urlString.substringWithRange(Range<String.Index>(start: urlString.startIndex.successor(),
                    end: urlString.endIndex.predecessor()))
            }
            
            //rel
            let relString = link[1]
            let relComps = relString.componentsSeparatedByString("=")
            if relComps.count < 2 {
                continue
            }
            
            var relName = relComps[1]
            if relName.hasPrefix("\"") && relName.hasSuffix("\"") {
                relName = relName.substringWithRange(Range<String.Index>(start: relName.startIndex.successor(),
                    end: relName.endIndex.predecessor()))
            }
            
            if
                let rel = RelPage(rawValue: relName),
                let url = NSURL(string: urlString)
            {
                linkDict[rel] = url
            }
        }
        
        return linkDict
    }
    
    private func sendRequest(request: NSURLRequest, completion: HTTP.Completion) {
        
        self.http.sendRequest(request, completion: { (response, body, error) -> () in
            
            if let error = error {
                completion(response: response, body: body, error: error)
                return
            }
            
            if response == nil {
                completion(response: nil, body: body, error: Error.withInfo("Nil response"))
                return
            }
            
            if let response = response {
                let headers = response.allHeaderFields
                
                if
                    let resetTime = (headers["X-RateLimit-Reset"] as? NSString)?.doubleValue,
                    let limit = (headers["X-RateLimit-Limit"] as? NSString)?.integerValue,
                    let remaining = (headers["X-RateLimit-Remaining"] as? NSString)?.integerValue {
                        
                        let rateLimitInfo = GitHubRateLimit(resetTime: resetTime, limit: limit, remaining: remaining)
                        self.latestRateLimitInfo = rateLimitInfo

                } else {
                    Log.error("No X-RateLimit info provided by GitHub in headers: \(headers), we're unable to detect the remaining number of allowed requests. GitHub might fail to return data any time now :(")
                }
            }
            
            if
                let respDict = body as? NSDictionary,
                let message = respDict["message"] as? String
                where message == "Not Found" {
                    
                    let url = request.URL ?? ""
                    completion(response: nil, body: nil, error: Error.withInfo("Not found: \(url)"))
                    return
            }
            
            //error out on special HTTP status codes
            let statusCode = response!.statusCode
            switch statusCode {
                
            case 400 ... 500:
                let message = (body as? NSDictionary)?["message"] as? String ?? "Unknown error"
                let resultString = "\(statusCode): \(message)"
                completion(response: response, body: body, error: Error.withInfo(resultString, internalError: error))
                return
            default:
                break
            }
            
            completion(response: response, body: body, error: error)
        })
    }
    
    private func sendRequestWithMethod(method: HTTP.Method, endpoint: GitHubEndpoints.Endpoint, params: [String: String]?, query: [String: String]?, body: NSDictionary?, completion: HTTP.Completion) {
        
        var allParams = [
            "method": method.rawValue
        ]
        
        //merge the two params
        if let params = params {
            for (let key, let value) in params {
                allParams[key] = value
            }
        }
        
        if let request = self.endpoints.createRequest(method, endpoint: endpoint, params: allParams, query: query, body: body) {
            
            self.sendRequestWithPossiblePagination(request, accumulatedResponseBody: NSArray(), completion: completion)
        } else {
            completion(response: nil, body: nil, error: Error.withInfo("Couldn't create Request"))
        }
    }
    
    /**
    *   GET all open pull requests of a repo (full name).
    */
    public func getOpenPullRequests(repo: String, completion: (prs: [PullRequest]?, error: NSError?) -> ()) {
        
        let params = [
            "repo": repo
        ]
        self.sendRequestWithMethod(.GET, endpoint: .PullRequests, params: params, query: nil, body: nil) { (response, body, error) -> () in
            
            if error != nil {
                completion(prs: nil, error: error)
                return
            }
            
            if let body = body as? NSArray {
                let prs: [PullRequest] = GitHubArray(body)
                completion(prs: prs, error: nil)
            } else {
                completion(prs: nil, error: Error.withInfo("Wrong body \(body)"))
            }
        }
    }
    
    /**
    *   GET a pull requests of a repo (full name) by its number.
    */
    public func getPullRequest(pullRequestNumber: Int, repo: String, completion: (pr: PullRequest?, error: NSError?) -> ()) {
        
        let params = [
            "repo": repo,
            "pr": pullRequestNumber.description
        ]
        
        self.sendRequestWithMethod(.GET, endpoint: .PullRequests, params: params, query: nil, body: nil) { (response, body, error) -> () in
            
            if error != nil {
                completion(pr: nil, error: error)
                return
            }
            
            if let body = body as? NSDictionary {
                let pr = PullRequest(json: body)
                completion(pr: pr, error: nil)
            } else {
                completion(pr: nil, error: Error.withInfo("Wrong body \(body)"))
            }
        }
    }
    
    /**
    *   GET all open issues of a repo (full name).
    */
    public func getOpenIssues(repo: String, completion: (issues: [Issue]?, error: NSError?) -> ()) {
        
        let params = [
            "repo": repo
        ]
        self.sendRequestWithMethod(.GET, endpoint: .Issues, params: params, query: nil, body: nil) { (response, body, error) -> () in
            
            if error != nil {
                completion(issues: nil, error: error)
                return
            }
            
            if let body = body as? NSArray {
                let issues: [Issue] = GitHubArray(body)
                completion(issues: issues, error: nil)
            } else {
                completion(issues: nil, error: Error.withInfo("Wrong body \(body)"))
            }
        }
    }
    
    /**
    *   GET an issue of a repo (full name) by its number.
    */
    public func getIssue(issueNumber: Int, repo: String, completion: (issue: Issue?, error: NSError?) -> ()) {
        
        let params = [
            "repo": repo,
            "issue": issueNumber.description
        ]
        
        self.sendRequestWithMethod(.GET, endpoint: .Issues, params: params, query: nil, body: nil) { (response, body, error) -> () in
            
            if error != nil {
                completion(issue: nil, error: error)
                return
            }
            
            if let body = body as? NSDictionary {
                let issue = Issue(json: body)
                completion(issue: issue, error: nil)
            } else {
                completion(issue: nil, error: Error.withInfo("Wrong body \(body)"))
            }
        }
    }
    
    /**
    *   POST a new Issue
    */
    public func postNewIssue(issueTitle: String, issueBody: String?, repo: String, completion: (issue: Issue?, error: NSError?) -> ()) {
        
        let params = [
            "repo": repo,
        ]
        
        let body = [
            "title": issueTitle,
            "body": issueBody ?? ""
        ]
        
        self.sendRequestWithMethod(.POST, endpoint: .Issues, params: params, query: nil, body: body) { (response, body, error) -> () in
            
            if error != nil {
                completion(issue: nil, error: error)
                return
            }
            
            if let body = body as? NSDictionary {
                let issue = Issue(json: body)
                completion(issue: issue, error: nil)
            } else {
                completion(issue: nil, error: Error.withInfo("Wrong body \(body)"))
            }
        }
    }
    
    /**
    *   POST a new Issue
    */
    public func closeIssue(issueNumber: Int, repo: String, completion: (issue: Issue?, error: NSError?) -> ()) {
        
        let params = [
            "repo": repo,
            "issue": issueNumber.description
        ]
        
        let body = [
            "state": "closed"
        ]
        
        self.sendRequestWithMethod(.PATCH, endpoint: .Issues, params: params, query: nil, body: body) { (response, body, error) -> () in
            
            if error != nil {
                completion(issue: nil, error: error)
                return
            }
            
            if let body = body as? NSDictionary {
                let issue = Issue(json: body)
                completion(issue: issue, error: nil)
            } else {
                completion(issue: nil, error: Error.withInfo("Wrong body \(body)"))
            }
        }
    }
    
    /**
    *   GET the status of a commit (sha) from a repo.
    */
    public func getStatusOfCommit(sha: String, repo: String, completion: (status: Status?, error: NSError?) -> ()) {
        
        let params = [
            "repo": repo,
            "sha": sha
        ]
        
        self.sendRequestWithMethod(.GET, endpoint: .Statuses, params: params, query: nil, body: nil) { (response, body, error) -> () in
            
            if error != nil {
                completion(status: nil, error: error)
                return
            }
            
            if let body = body as? NSArray {
                let statuses: [Status] = GitHubArray(body)
                //sort them by creation date
                let mostRecentStatus = statuses.sorted({ return $0.created! > $1.created! }).first
                completion(status: mostRecentStatus, error: nil)
            } else {
                completion(status: nil, error: Error.withInfo("Wrong body \(body)"))
            }
        }
    }
    
    /**
    *   POST a new status on a commit.
    */
    public func postStatusOfCommit(status: Status, sha: String, repo: String, completion: (status: Status?, error: NSError?) -> ()) {
        
        let params = [
            "repo": repo,
            "sha": sha
        ]
        
        let body = status.dictionarify()
        self.sendRequestWithMethod(.POST, endpoint: .Statuses, params: params, query: nil, body: body) { (response, body, error) -> () in
            
            if error != nil {
                completion(status: nil, error: error)
                return
            }
            
            if let body = body as? NSDictionary {
                let status = Status(json: body)
                completion(status: status, error: nil)
            } else {
                completion(status: nil, error: Error.withInfo("Wrong body \(body)"))
            }
        }
    }
    
    /**
    *   GET comments of an issue - WARNING - there is a difference between review comments (on a PR, tied to code)
    *   and general issue comments - which appear in both Issues and Pull Requests (bc a PR is an Issue + code)
    *   This API only fetches the general issue comments, NOT comments on code.
    */
    public func getCommentsOfIssue(issueNumber: Int, repo: String, completion: (comments: [Comment]?, error: NSError?) -> ()) {
        
        let params = [
            "repo": repo,
            "issue": issueNumber.description
        ]
        
        self.sendRequestWithMethod(.GET, endpoint: .IssueComments, params: params, query: nil, body: nil) { (response, body, error) -> () in
            
            if error != nil {
                completion(comments: nil, error: error)
                return
            }
            
            if let body = body as? NSArray {
                let comments: [Comment] = GitHubArray(body)
                completion(comments: comments, error: nil)
            } else {
                completion(comments: nil, error: Error.withInfo("Wrong body \(body)"))
            }
        }
    }
    
    /**
    *   POST a comment on an issue.
    */
    public func postCommentOnIssue(commentBody: String, issueNumber: Int, repo: String, completion: (comment: Comment?, error: NSError?) -> ()) {
        
        let params = [
            "repo": repo,
            "issue": issueNumber.description
        ]
        
        let body = [
            "body": commentBody
        ]
        
        self.sendRequestWithMethod(.POST, endpoint: .IssueComments, params: params, query: nil, body: body) { (response, body, error) -> () in
            
            if error != nil {
                completion(comment: nil, error: error)
                return
            }
            
            if let body = body as? NSDictionary {
                let comment = Comment(json: body)
                completion(comment: comment, error: nil)
            } else {
                completion(comment: nil, error: Error.withInfo("Wrong body \(body)"))
            }
        }
    }
    
    /**
    *   PATCH edit a comment with id
    */
    public func editCommentOnIssue(commentId: Int, newCommentBody: String, repo: String, completion: (comment: Comment?, error: NSError?) -> ()) {
        
        let params = [
            "repo": repo,
            "comment": commentId.description
        ]
        
        let body = [
            "body": newCommentBody
        ]
        
        self.sendRequestWithMethod(.PATCH, endpoint: .IssueComments, params: params, query: nil, body: body) { (response, body, error) -> () in
            
            if error != nil {
                completion(comment: nil, error: error)
                return
            }
            
            if let body = body as? NSDictionary {
                let comment = Comment(json: body)
                completion(comment: comment, error: nil)
            } else {
                completion(comment: nil, error: Error.withInfo("Wrong body \(body)"))
            }
        }
    }
    
    /**
    *   POST merge a head branch/commit into a base branch.
    *   has a couple of different responses, a bit tricky
    */
    public func mergeHeadIntoBase(#head: String, base: String, commitMessage: String, repo: String, completion: (result: GitHubEndpoints.MergeResult?, error: NSError?) -> ()) {
        
        let params = [
            "repo": repo
        ]
        
        let body = [
            "head": head,
            "base": base,
            "commit_message": commitMessage
        ]
        
        self.sendRequestWithMethod(.POST, endpoint: .Merges, params: params, query: nil, body: body) { (response, body, error) -> () in
            
            if error != nil {
                completion(result: nil, error: error)
                return
            }
            
            if let response = response {
                let code = response.statusCode
                switch code {
                case 201:
                    //success
                    completion(result: GitHubEndpoints.MergeResult.Success(body as! NSDictionary), error: error)
                    
                case 204:
                    //no-op
                    completion(result: GitHubEndpoints.MergeResult.NothingToMerge, error: error)
                    
                case 409:
                    //conflict
                    completion(result: GitHubEndpoints.MergeResult.Conflict, error: error)
                    
                case 404:
                    //missing
                    let bodyDict = body as! NSDictionary
                    let message = bodyDict["message"] as! String
                    completion(result: GitHubEndpoints.MergeResult.Missing(message), error: error)
                default:
                    completion(result: nil, error: error)
                }
            } else {
                completion(result: nil, error: Error.withInfo("Nil response"))
            }
        }
    }
    
    /**
    *   GET branches of a repo
    */
    public func getBranchesOfRepo(repo: String, completion: (branches: [Branch]?, error: NSError?) -> ()) {
        
        let params = [
            "repo": repo
        ]
        
        self.sendRequestWithMethod(.GET, endpoint: .Branches, params: params, query: nil, body: nil) {
            (response, body, error) -> () in
            
            if error != nil {
                completion(branches: nil, error: error)
                return
            }
            
            if let body = body as? NSArray {
                let branches: [Branch] = GitHubArray(body)
                completion(branches: branches, error: nil)
            } else {
                completion(branches: nil, error: Error.withInfo("Wrong body \(body)"))
            }
        }
    }
    
    /**
    *   GET repo metadata
    */
    public func getRepo(repo: String, completion: (repo: Repo?, error: NSError?) -> ()) {
        
        let params = [
            "repo": repo
        ]
        
        self.sendRequestWithMethod(.GET, endpoint: .Repos, params: params, query: nil, body: nil) {
            (response, body, error) -> () in
            
            if error != nil {
                completion(repo: nil, error: error)
                return
            }
            
            if let body = body as? NSDictionary {
                let repository: Repo = Repo(json: body)
                completion(repo: repository, error: nil)
            } else {
                completion(repo: nil, error: Error.withInfo("Wrong body \(body)"))
            }
        }
    }
    
}





