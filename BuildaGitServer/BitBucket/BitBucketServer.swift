//
//  BitBucketServer.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/27/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

class BitBucketServer : GitServer {
    
    let endpoints: BitBucketEndpoints
    let cache = InMemoryURLCache()
    
    //TODO: add a signal for getting auth changes from the server here
    // -> used for saving credentials back into the keychain
    
    init(endpoints: BitBucketEndpoints, http: HTTP? = nil) {
        
        self.endpoints = endpoints
        super.init(service: .GitHub, http: http)
    }
}

extension BitBucketServer: SourceServerType {
    
    func createStatusFromState(state: BuildState, description: String?, targetUrl: String?) -> StatusType {
        
        let bbState = BitBucketStatus.BitBucketState.fromBuildState(state)
        let key = "Buildasaur"
        let url = targetUrl ?? "https://github.com/czechboy0/Buildasaur"
        return BitBucketStatus(state: bbState, key: key, name: key, description: description, url: url)
    }
    
    func getBranchesOfRepo(repo: String, completion: (branches: [BranchType]?, error: ErrorType?) -> ()) {
        
        //TODO: start returning branches
        completion(branches: [], error: nil)
    }
    
    func getOpenPullRequests(repo: String, completion: (prs: [PullRequestType]?, error: ErrorType?) -> ()) {
        
        let params = [
            "repo": repo
        ]
        self._sendRequestWithMethod(.GET, endpoint: .PullRequests, params: params, query: nil, body: nil) { (response, body, error) -> () in
            
            if error != nil {
                completion(prs: nil, error: error)
                return
            }
            
            if let body = body as? NSDictionary {
                let prs: [BitBucketPullRequest] = BitBucketArray(body)
                completion(prs: prs.map { $0 as PullRequestType }, error: nil)
            } else {
                completion(prs: nil, error: Error.withInfo("Wrong body \(body)"))
            }
        }
    }
    
    func getPullRequest(pullRequestNumber: Int, repo: String, completion: (pr: PullRequestType?, error: ErrorType?) -> ()) {
        
        let params = [
            "repo": repo,
            "pr": pullRequestNumber.description
        ]
        
        self._sendRequestWithMethod(.GET, endpoint: .PullRequests, params: params, query: nil, body: nil) { (response, body, error) -> () in
            
            if error != nil {
                completion(pr: nil, error: error)
                return
            }
            
            if let body = body as? NSDictionary {
                let pr = BitBucketPullRequest(json: body)
                completion(pr: pr, error: nil)
            } else {
                completion(pr: nil, error: Error.withInfo("Wrong body \(body)"))
            }
        }
    }
    
    func getRepo(repo: String, completion: (repo: RepoType?, error: ErrorType?) -> ()) {
        
        let params = [
            "repo": repo
        ]
        
        self._sendRequestWithMethod(.GET, endpoint: .Repos, params: params, query: nil, body: nil) {
            (response, body, error) -> () in
            
            if error != nil {
                completion(repo: nil, error: error)
                return
            }
            
            if let body = body as? NSDictionary {
                let repository = BitBucketRepo(json: body)
                completion(repo: repository, error: nil)
            } else {
                completion(repo: nil, error: Error.withInfo("Wrong body \(body)"))
            }
        }
    }
    
    func getStatusOfCommit(commit: String, repo: String, completion: (status: StatusType?, error: ErrorType?) -> ()) {
        
        let params = [
            "repo": repo,
            "sha": commit,
            "status_key": "Buildasaur"
        ]
        
        self._sendRequestWithMethod(.GET, endpoint: .CommitStatuses, params: params, query: nil, body: nil) { (response, body, error) -> () in
            
            if response?.statusCode == 404 {
                //no status yet, just pass nil but OK
                completion(status: nil, error: nil)
                return
            }
            
            if error != nil {
                completion(status: nil, error: error)
                return
            }
            
            if let body = body as? NSDictionary {
                let status = BitBucketStatus(json: body)
                completion(status: status, error: nil)
            } else {
                completion(status: nil, error: Error.withInfo("Wrong body \(body)"))
            }
        }
    }
    
    func postStatusOfCommit(commit: String, status: StatusType, repo: String, completion: (status: StatusType?, error: ErrorType?) -> ()) {
        
        let params = [
            "repo": repo,
            "sha": commit
        ]
        
        let body = (status as! BitBucketStatus).dictionarify()
        self._sendRequestWithMethod(.POST, endpoint: .CommitStatuses, params: params, query: nil, body: body) { (response, body, error) -> () in
            
            if error != nil {
                completion(status: nil, error: error)
                return
            }
            
            if let body = body as? NSDictionary {
                let status = BitBucketStatus(json: body)
                completion(status: status, error: nil)
            } else {
                completion(status: nil, error: Error.withInfo("Wrong body \(body)"))
            }
        }
    }
    
    func postCommentOnIssue(comment: String, issueNumber: Int, repo: String, completion: (comment: CommentType?, error: ErrorType?) -> ()) {
        
        //TODO
        completion(comment: nil, error: Error.withInfo("Posting comments on BitBucket not yet supported"))
    }
    
    func getCommentsOfIssue(issueNumber: Int, repo: String, completion: (comments: [CommentType]?, error: ErrorType?) -> ()) {
        
        let params = [
            "repo": repo,
            "pr": issueNumber.description
        ]
        
        self._sendRequestWithMethod(.GET, endpoint: .PullRequestComments, params: params, query: nil, body: nil) { (response, body, error) -> () in
            
            if error != nil {
                completion(comments: nil, error: error)
                return
            }
            
            if let body = body as? NSDictionary {
                let comments: [BitBucketComment] = BitBucketArray(body)
                completion(comments: comments.map { $0 as CommentType }, error: nil)
            } else {
                completion(comments: nil, error: Error.withInfo("Wrong body \(body)"))
            }
        }
    }
}

extension BitBucketServer {
    
    private func _sendRequest(request: NSMutableURLRequest, isRetry: Bool = false, completion: HTTP.Completion) {
        
//        let cachedInfo = self.cache.getCachedInfoForRequest(request)
//        if let etag = cachedInfo.etag {
//            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
//        }
        
        self.http.sendRequest(request) { (response, body, error) -> () in
            
            if let error = error {
                completion(response: response, body: body, error: error)
                return
            }
            
//            if let response = response {
//                let headers = response.allHeaderFields
//
//                if
//                    let resetTime = (headers["X-RateLimit-Reset"] as? NSString)?.doubleValue,
//                    let limit = (headers["X-RateLimit-Limit"] as? NSString)?.integerValue,
//                    let remaining = (headers["X-RateLimit-Remaining"] as? NSString)?.integerValue {
//
//                        let rateLimitInfo = GitHubRateLimit(resetTime: resetTime, limit: limit, remaining: remaining)
//                        self.latestRateLimitInfo = rateLimitInfo
//
//                } else {
//                    Log.error("No X-RateLimit info provided by GitHub in headers: \(headers), we're unable to detect the remaining number of allowed requests. GitHub might fail to return data any time now :(")
//                }
//            }
            
            //error out on special HTTP status codes
            let statusCode = response!.statusCode
            switch statusCode {
                //            case 200...299: //good response, cache the returned data
                //                let responseInfo = ResponseInfo(response: response!, body: body)
                //                cachedInfo.update(responseInfo)
                //            case 304: //not modified, return the cached response
                //                let responseInfo = cachedInfo.responseInfo!
                //                completion(response: responseInfo.response, body: responseInfo.body, error: nil)
                //                return
            case 401: //unauthorized, use refresh token to get a new access token
                      //only try to refresh token once
                if !isRetry {
                    self._handle401(request, completion: completion)
                }
                return
            case 400, 402 ... 500:
                
                let message = ((body as? NSDictionary)?["error"] as? NSDictionary)?["message"] as? String ?? (body as? String ?? "Unknown error")
                let resultString = "\(statusCode): \(message)"
                completion(response: response, body: body, error: Error.withInfo(resultString, internalError: error))
                return
            default:
                break
            }
            
            completion(response: response, body: body, error: error)
        }
    }
    
    private func _handle401(request: NSMutableURLRequest, completion: HTTP.Completion) {
        
        //we need to use the refresh token to request a new access token
        //then we need to notify that we updated the secret, so that it can
        //be saved by buildasaur
        //then we need to set the new access token to this waiting request and
        //run it again. if that fails too, we fail for real.
        
        Log.verbose("Got 401, starting a BitBucket refresh token flow...")
        
        //get a new access token
        self._refreshAccessToken(request) { error in
            
            if let error = error {
                Log.verbose("Failed to get a new access token")
                completion(response: nil, body: nil, error: error)
                return
            }

            //we have a new access token, force set the new cred on the original
            //request
            self.endpoints.setAuthOnRequest(request)
            
            Log.verbose("Successfully refreshed a BitBucket access token")
            
            //retrying the original request
            self._sendRequest(request, isRetry: true, completion: completion)
        }
    }
    
    private func _refreshAccessToken(request: NSMutableURLRequest, completion: (NSError?) -> ()) {
        
        let refreshRequest = self.endpoints.createRefreshTokenRequest()
        self.http.sendRequest(refreshRequest) { (response, body, error) -> () in
            
            if let error = error {
                completion(error)
                return
            }
            
            guard response?.statusCode == 200 else {
                completion(Error.withInfo("Wrong status code returned, refreshing access token failed"))
                return
            }
            
            let payload = body as! NSDictionary
            let accessToken = payload.stringForKey("access_token")
            let refreshToken = payload.stringForKey("refresh_token")
            let secret = [refreshToken, accessToken].joinWithSeparator(":")
            
            let newAuth = ProjectAuthenticator(service: .BitBucket, username: "GIT", type: .OAuthToken, secret: secret)
            self.endpoints.auth = newAuth
            completion(nil)
        }
    }
    
    private func _sendRequestWithMethod(method: HTTP.Method, endpoint: BitBucketEndpoints.Endpoint, params: [String: String]?, query: [String: String]?, body: NSDictionary?, completion: HTTP.Completion) {
        
        var allParams = [
            "method": method.rawValue
        ]
        
        //merge the two params
        if let params = params {
            for (key, value) in params {
                allParams[key] = value
            }
        }
        
        do {
            let request = try self.endpoints.createRequest(method, endpoint: endpoint, params: allParams, query: query, body: body)
            self._sendRequest(request, completion: completion)
        } catch {
            completion(response: nil, body: nil, error: Error.withInfo("Couldn't create Request, error \(error)"))
        }
    }
}
