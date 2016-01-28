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

extension StandardSyncer: BuildStatusCreator {
    
    public func createStatusFromState(state: BuildState, description: String?, targetUrl: String?) -> StatusType {
        
        return self._sourceServer.createStatusFromState(state, description: description, targetUrl: targetUrl)
    }
}

extension StandardSyncer {
    
    func updateCommitStatusIfNecessary(
        newStatus: StatusAndComment,
        commit: String,
        issue: IssueType?,
        completion: SyncPair.Completion) {
        
        let repoName = self.repoName()!
        self._sourceServer.getStatusOfCommit(commit, repo: repoName, completion: { (status, error) -> () in
            
            if error != nil {
                let e = Error.withInfo("Commit \(commit) failed to return status", internalError: error as? NSError)
                completion(error: e)
                return
            }
            
            if status == nil || !newStatus.status.isEqual(status!) {
                
                //TODO: add logic for handling the creation of a new Issue for branch tracking
                //and the deletion of it when build succeeds etc.
                
                self.postStatusWithComment(newStatus, commit: commit, repo: repoName, issue: issue, completion: completion)
                
            } else {
                completion(error: nil)
            }
        })
    }

    func postStatusWithComment(statusWithComment: StatusAndComment, commit: String, repo: String, issue: IssueType?, completion: SyncPair.Completion) {
        
        self._sourceServer.postStatusOfCommit(commit, status: statusWithComment.status, repo: repo) { (status, error) -> () in
            
            if error != nil {
                let e = Error.withInfo("Failed to post a status on commit \(commit) of repo \(repo)", internalError: error as? NSError)
                completion(error: e)
                return
            }
            
            //have a chance to NOT post a status comment...
            let postStatusComments = self._postStatusComments
            
            //optional there can be a comment to be posted and there's an issue to be posted on
            if
                let issue = issue,
                let comment = statusWithComment.comment where postStatusComments {
                
                //we have a comment, post it
                self._sourceServer.postCommentOnIssue(comment, issueNumber: issue.number, repo: repo, completion: { (comment, error) -> () in
                    
                    if error != nil {
                        let e = Error.withInfo("Failed to post a comment \"\(comment)\" on Issue \(issue.number) of repo \(repo)", internalError: error as? NSError)
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
