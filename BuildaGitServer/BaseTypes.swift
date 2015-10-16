//
//  BaseTypes.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/16/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation

//TODO: migrate all of buildasaur to handle the protocol types below so
//that we can start hiding away the Git server details and support not just
//GitHub but more, like Bitbucket.

public protocol SourceServerType {
    
    func getBranchesOfRepo(repo: String, completion: (branches: [BranchType]?, error: ErrorType?))
    func getOpenPullRequests(repo: String, completion: (prs: [PullRequestType]?, error: ErrorType?))
    func getRepo(repo: String, completion: (repo: RepoType?, error: ErrorType?))
    func getStatusOfCommit(commit: String, repo: String, completion: (status: StatusType?, error: ErrorType?))
    func postStatusOfCommit(commit: String, status: StatusType, repo: String, completion: (status: StatusType?, error: ErrorType?))
    func postCommentOnIssue(comment: String, issueNumber: Int, repo: String, completion: (comment: CommentType?, error: ErrorType?))
    func findMatchingCommentInIssue(keyword: String, issueNumber: Int, repo: String, completion: (foundComments: [CommentType]?, error: ErrorType?))
}

public protocol SourceServerFactory {
    
    func createServer(config: NSDictionary) -> SourceServerType
}

public protocol RepoType {
    //TODO: add required properties
}

public protocol BranchType {
    //TODO: add required properties
}

public protocol PullRequestType {
    //TODO: add required properties
}

public protocol StatusType {
    //TODO: add required properties
}

public protocol CommentType {
    //TODO: add required properties
}

