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
import XcodeServerSDK

extension HDGitHubXCBotSyncer {
    
    class func createPendingStatusFromIntegration(integration: Integration, link: (Integration) -> String?) -> Status {
        
        var text: String
        if integration.currentStep == .Pending {
            text = "Build waiting in the queue..."
        } else {
            let currentStepString = integration.currentStep.rawValue
            text = "Integration step: \(currentStepString)..."
        }
        
        //if we have the estimated completion time, add it to the text
        if let estimatedCompletionTime = integration.expectedCompletionDate {
            let diff = estimatedCompletionTime.timeIntervalSinceNow
            let minutesLeftOverestimate = Int(ceil(diff / 60.0))
            text += " (< \(minutesLeftOverestimate) \("min".pluralizeStringIfNecessary(minutesLeftOverestimate)) left)"
        }
        
        let url = link(integration)
        return self.createStatusFromState(.Pending, description: text, targetUrl: url)
    }
    
    class func createStatusFromState(state: Status.State, description: String?, targetUrl: String?) -> Status {
        
        //TODO: potentially have multiple contexts to show multiple stats on the PR
        let context = "Buildasaur"
        return Status(state: state, description: description, targetUrl: targetUrl, context: context)
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
            let postStatusComments = self._postStatusComments
            
            //optional there can be a comment to be posted and there's an issue to be posted on
            if
                let issue = issue,
                let comment = statusWithComment.comment where postStatusComments {
                
                //we have a comment, post it
                self._github.postCommentOnIssue(comment, issueNumber: issue.number, repo: repo, completion: { (comment, error) -> () in
                    
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
