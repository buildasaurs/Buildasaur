//
//  BaseTypes.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/16/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Result

public protocol BuildStatusCreator {
    func createStatusFromState(state: BuildState, description: String?, targetUrl: String?) -> StatusType
}

public protocol SourceServerType: BuildStatusCreator {
    
    func getBranchesOfRepo(repo: String, completion: (branches: [BranchType]?, error: ErrorType?) -> ())
    func getOpenPullRequests(repo: String, completion: (prs: [PullRequestType]?, error: ErrorType?) -> ())
    func getPullRequest(pullRequestNumber: Int, repo: String, completion: (pr: PullRequestType?, error: ErrorType?) -> ())
    func getRepo(repo: String, completion: (repo: RepoType?, error: ErrorType?) -> ())
    func getStatusOfCommit(commit: String, repo: String, completion: (status: StatusType?, error: ErrorType?) -> ())
    func postStatusOfCommit(commit: String, status: StatusType, repo: String, completion: (status: StatusType?, error: ErrorType?) -> ())
    func postCommentOnIssue(comment: String, issueNumber: Int, repo: String, completion: (comment: CommentType?, error: ErrorType?) -> ())
    func getCommentsOfIssue(issueNumber: Int, repo: String, completion: (comments: [CommentType]?, error: ErrorType?) -> ())
    
    func authChangedSignal() -> Signal<ProjectAuthenticator?, NoError>
}

public class SourceServerFactory {
    
    public init() { }
    
    public func createServer(service: GitService, auth: ProjectAuthenticator?) -> SourceServerType {
        
        if let auth = auth {
            precondition(service.type() == auth.service.type())
        }
        
        return GitServerFactory.server(service, auth: auth)
    }
}

public struct RepoPermissions {
    public let read: Bool
    public let write: Bool
    public init(read: Bool, write: Bool) {
        self.read = read
        self.write = write
    }
}

public protocol RateLimitType {
    
    var report: String { get }
}

public protocol RepoType {
    
    var permissions: RepoPermissions { get }
    var originUrlSSH: String { get }
    var latestRateLimitInfo: RateLimitType? { get }
}

public protocol BranchType {
    
    var name: String { get }
    var commitSHA: String { get }
}

public protocol IssueType {
    
    var number: Int { get }
}

public protocol PullRequestType: IssueType {
    
    var headName: String { get }
    var headCommitSHA: String { get }
    var headRepo: RepoType { get }
    
    var baseName: String { get }
    
    var title: String { get }
}

public enum BuildState {
    case NoState
    case Pending
    case Success
    case Error
    case Failure
}

public protocol StatusType {
    
    var state: BuildState { get }
    var description: String? { get }
    var targetUrl: String? { get }
}

extension StatusType {
    
    public func isEqual(rhs: StatusType) -> Bool {
        let lhs = self
        return lhs.state == rhs.state && lhs.description == rhs.description
    }
}

public protocol CommentType {
    
    var body: String { get }
}

