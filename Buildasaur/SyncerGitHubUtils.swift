//
//  SyncerGitHubUtils.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 16/05/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaCIServer
import BuildaGitServer
import BuildaUtils

extension HDGitHubXCBotSyncer {
    
    class func createStatusFromState(state: Status.State, description: String?) -> Status {
        
        //TODO: add useful targetUrl and potentially have multiple contexts to show multiple stats on the PR
        let context = "Buildasaur"
        let newDescription: String?
        if let description = description {
            newDescription = "\(context): \(description)"
        } else {
            newDescription = nil
        }
        return Status(state: state, description: newDescription, targetUrl: nil, context: context)
    }
    
    func updateCommitStatusIfNecessary(
        newStatus: GitHubStatusAndComment,
        commit: String,
        issue: Issue?,
        completion: SyncPair.Completion) {
        
        let repoName = self.repoName()!
        self.github.getStatusOfCommit(commit, repo: repoName, completion: { (status, error) -> () in
            
            if error != nil {
                let e = Error.withInfo("Commit \(commit) failed to return status", internalError: error)
                completion(error: e)
                return
            }
            
            if status == nil || newStatus.status != status! {
                
                //TODO: add logic for handling the creation of a new Issue for branch tracking
                //and the deletion of it when build succeeds etc.
                
                self.postStatusWithComment(newStatus, commit: commit, repo: repoName, issue: issue, completion: completion)
                
            } else {
                completion(error: nil)
            }
        })
    }

    func postStatusWithComment(statusWithComment: GitHubStatusAndComment, commit: String, repo: String, issue: Issue?, completion: SyncPair.Completion) {
        
        self.github.postStatusOfCommit(statusWithComment.status, sha: commit, repo: repo) { (status, error) -> () in
            
            if error != nil {
                let e = Error.withInfo("Failed to post a status on commit \(commit) of repo \(repo)", internalError: error)
                completion(error: e)
                return
            }
            
            //have a chance to NOT post a status comment...
            let postStatusComments = self.postStatusComments
            
            //optional there can be a comment to be posted and there's an issue to be posted on
            if
                let issue = issue,
                let comment = statusWithComment.comment where postStatusComments {
                
                //we have a comment, post it
                self.github.postCommentOnIssue(comment, issueNumber: issue.number, repo: repo, completion: { (comment, error) -> () in
                    
                    if error != nil {
                        let e = Error.withInfo("Failed to post a comment \"\(comment)\" on Issue \(issue.number) of repo \(repo)", internalError: error)
                        completion(error: e)
                    } else {
                        completion(error: nil)
                    }
                })
                
            } else {
                completion(error: nil)
            }
        }
    }
}
