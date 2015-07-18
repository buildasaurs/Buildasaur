//
//  GitHubServerExtensions.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 14/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

//functions to make working with github easier - utility functions
public extension GitHubServer {
    
    /**
    *   Get the latest status of a pull request.
    */
    public func getStatusOfPullRequest(pullRequestNumber: Int, repo: String, completion: (status: Status?, error: NSError?) -> ()) {
        
        self.getPullRequest(pullRequestNumber, repo: repo) { (pr, error) -> () in
            
            if error != nil {
                completion(status: nil, error: error)
                return
            }
            
            if let pr = pr {
                //fetched PR, now take its head's sha - that's the commit we care about.
                let sha = pr.head.sha
                self.getStatusOfCommit(sha, repo: repo, completion: completion)
            } else {
                completion(status: nil, error: Error.withInfo("PR is nil and error is nil"))
            }
        }
    }

    //TODO: support paging through all the comments. currently we only fetch the last ~30 comments.
    public func findMatchingCommentInIssue(commentsToMatch: [String], issue: Int, repo: String, completion: (foundComments: [Comment]?, error: NSError?) -> ()) {
        
        self.getCommentsOfIssue(issue, repo: repo) { (comments, error) -> () in
            
            if error != nil {
                completion(foundComments: nil, error: error)
                return
            }
            
            if let comments = comments {
                let filtered = comments.filter { (comment: Comment) -> Bool in
                    
                    let filteredSearch = commentsToMatch.filter {
                        (searchString: String) -> Bool in
                        if searchString == comment.body {
                            return true
                        }
                        return false
                    }
                    return filteredSearch.count > 0
                }
                completion(foundComments: filtered, error: nil)
            } else {
                completion(foundComments: nil, error: Error.withInfo("Nil comments and nil error. Wat?"))
            }
        }
    }

}
