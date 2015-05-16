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
    
    func createStatusFromState(state: Status.State, description: String?) -> Status {
        
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

    func updatePRStatusIfNecessary(newStatus: GitHubStatusAndComment, prNumber: Int, completion: SyncPair.Completion) {
        
        let repoName = self.repoName()!
        
        self.github.getPullRequest(prNumber, repo: repoName) { (pr, error) -> () in
            
            if error != nil {
                let e = Error.withInfo("PR \(prNumber) failed to return data", internalError: error)
                completion(error: e)
                return
            }
            
            if let pr = pr {
                
                let latestCommit = pr.head.sha
                
                self.github.getStatusOfCommit(latestCommit, repo: repoName, completion: { (status, error) -> () in
                    
                    if error != nil {
                        let e = Error.withInfo("PR \(prNumber) failed to return status", internalError: error)
                        completion(error: e)
                        return
                    }
                    
                    if status == nil || newStatus.status != status! {
                        
                        self.postStatusWithComment(newStatus, commit: latestCommit, repo: repoName, pr: pr, completion: completion)
                        
                    } else {
                        completion(error: nil)
                    }
                })
                
            } else {
                let e = Error.withInfo("Fetching a PR", internalError: Error.withInfo("PR is nil and error is nil"))
                completion(error: e)
            }
        }
    }

    func postStatusWithComment(statusWithComment: GitHubStatusAndComment, commit: String, repo: String, pr: PullRequest, completion: SyncPair.Completion) {
        
        self.github.postStatusOfCommit(statusWithComment.status, sha: commit, repo: repo) { (status, error) -> () in
            
            if error != nil {
                let e = Error.withInfo("Failed to post a status on commit \(commit) of repo \(repo)", internalError: error)
                completion(error: e)
                return
            }
            
            //have a chance to NOT post a status comment...
            let postStatusComments = self.postStatusComments
            
            //optional there can be a comment to be posted as well
            if let comment = statusWithComment.comment where postStatusComments {
                
                //we have a comment, post it
                self.github.postCommentOnIssue(comment, issueNumber: pr.number, repo: repo, completion: { (comment, error) -> () in
                    
                    if error != nil {
                        let e = Error.withInfo("Failed to post a comment \"\(comment)\" on PR \(pr.number) of repo \(repo)", internalError: error)
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
