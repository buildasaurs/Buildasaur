//
//  BranchWatchingViewController.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 23/05/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation

import AppKit
import BuildaGitServer
import BuildaUtils

class BranchWatchingViewController: NSViewController {
    
    //these two must be set before viewDidLoad by its presenting view controller
    var syncer: HDGitHubXCBotSyncer!
    var watchedBranchNames: [String]!
    
    private var branches: [Branch] = []
    
    @IBOutlet weak var branchActivityIndicator: NSProgressIndicator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(self.syncer != nil, "Syncer has not been set")
        self.watchedBranchNames = self.syncer.watchedBranchNames
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.fetchBranches { (branches, error) -> () in
            
            if let error = error {
                UIUtils.showAlertWithError(error)
            }
        }
    }
    
    func fetchBranches(completion: ([Branch]?, NSError?) -> ()) {
        
        self.branchActivityIndicator.startAnimation(nil)
        let repoName = self.syncer.localSource.githubRepoName()!
        self.syncer.github.getBranchesOfRepo(repoName, completion: { (branches, error) -> () in
            
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                
                if let branches = branches {
                    self.branches = branches
                }
                
                completion(branches, error)
                self.branchActivityIndicator.stopAnimation(nil)
            })
        })
    }
    
    @IBAction func cancelTapped(sender: AnyObject) {
        self.dismissController(nil)
    }
    
    @IBAction func doneTapped(sender: AnyObject) {
        //save the now-selected watched branches to the syncer
        self.syncer.watchedBranchNames = self.watchedBranchNames
        StorageManager.sharedInstance.saveSyncers() //think of a better way to force saving
        self.dismissController(nil)
    }
}