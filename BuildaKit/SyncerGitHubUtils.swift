//
//  SyncerGitHubUtils.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 16/05/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaGitServer
import BuildaUtils

extension HDGitHubXCBotSyncer {
    
    class func createStatusFromState(state: Status.State, description: String?) -> Status {
        
        //TODO: add useful targetUrl and potentially have multiple contexts to show multiple stats on the PR
        let context = "Buildasaur"
        return Status(state: state, description: description, targetUrl: nil, context: context)
    }
    
    func updateCommitStatusIfNecessary(
        newStatus: GitHubStatusAndComment,
        commit: String,
        issue: Issue?,
        completion: SyncPair.Completion) {
        
        let repoName = self.repoName()!
        self._github.getStatusOfCommit(commit, repo: repoName, completion: { (status, error) -> () in
            
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
        
        self._github.postStatusOfCommit(statusWithComment.status, sha: commit, repo: repo) { (status, error) -> () in
            
            if error != nil {
                let e = Error.withInfo("Failed to post a status on commit \(commit) of repo \(repo)", internalError: error)
                completion(error: e)
                return
            }
            
            //have a chance to NOT post a status comment...
            let shouldPostStatusComments = self._postStatusComments
            
            //optional there can be a comment to be posted and there's an issue to be posted on
            guard
                let issue = issue,
                let comment = statusWithComment.comment where shouldPostStatusComments else {
                    completion(error: nil)
                    return
            }
            
            //actually, in an attempt to fix https://github.com/czechboy0/Buildasaur/issues/163,
            //we're going to once more fetch comments to make sure we wouldn't
            //be reposting the same thing again (sigh, delayed GitHub servers are ruining
            //the party)
            
            self._github.getCommentsOfIssue(issue.number, repo: repo, completion: { (comments, error) -> () in
                
                if error != nil {
                    let e = Error.withInfo("Failed to get comments \"\(comment)\" of Issue \(issue.number) of repo \(repo)", internalError: error)
                    completion(error: e)
                    return
                }
                
                //just look at the last one and compare with what we want to post
                var shouldPost = true
                if let lastComment: Comment = comments?.last where lastComment.body == comment {
                    shouldPost = false
                }
                
                guard shouldPost else {
                    Log.verbose("Skipping posting of a comment on Issue \(issue.number) in repo \(repo), because we already found exactly the same comment in the conversation. Avoiding reposting.")
                    completion(error: nil)
                    return
                }
                
                //we have a comment, post it
                self._github.postCommentOnIssue(comment, issueNumber: issue.number, repo: repo, completion: { (comment, error) -> () in
                    
                    if error != nil {
                        let e = Error.withInfo("Failed to post a comment \"\(comment)\" on Issue \(issue.number) of repo \(repo)", internalError: error)
                        completion(error: e)
                    } else {
                        completion(error: nil)
                    }
                })
            })
        }
    }
}

