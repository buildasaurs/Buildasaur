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
import BuildaKit

class BranchWatchingViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    //these two must be set before viewDidLoad by its presenting view controller
    var syncer: HDGitHubXCBotSyncer!
    var watchedBranchNames: Set<String>!
    
    private var branches: [Branch] = []
    
    @IBOutlet weak var branchActivityIndicator: NSProgressIndicator!
    @IBOutlet weak var branchesTableView: NSTableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(self.syncer != nil, "Syncer has not been set")
        self.watchedBranchNames = Set(self.syncer.config.value.watchedBranchNames)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.fetchBranches { (branches, error) -> () in
            
            if let error = error {
                UIUtils.showAlertWithError(error)
            }
            
            self.branchesTableView.reloadData()
        }
    }
    
    func fetchBranches(completion: ([Branch]?, NSError?) -> ()) {
        
        self.branchActivityIndicator.startAnimation(nil)
        let repoName = self.syncer.project.githubRepoName()!
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
        //TODO: save the now-selected watched branches to the syncer config
//        self.syncer.config.watchedBranchNames.value = Array(self.watchedBranchNames)
//        StorageManager.sharedInstance.saveSyncers() //think of a better way to force saving
//        self.dismissController(nil)
    }
    
    //MARK: branches table view
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        
        if tableView == self.branchesTableView {
            return self.branches.count
        }
        return 0
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        
        if tableView == self.branchesTableView {
            
            switch tableColumn!.identifier {
            case "name":
                
                let branch = self.branches[row]
                return branch.name
            case "enabled":
                
                let branch = self.branches[row]
                return self.watchedBranchNames.contains(branch.name)
            default:
                return nil
            }
        }
        return nil
    }
    
    @IBAction func branchesTableViewRowCheckboxTapped(sender: AnyObject) {
        
        //toggle selection in model
        let branch = self.branches[self.branchesTableView.selectedRow]
        let branchName = branch.name
        
        //see if we are checking or unchecking
        let previouslyEnabled = self.watchedBranchNames.contains(branchName)
        
        if previouslyEnabled {
            //disable
            self.watchedBranchNames.remove(branchName)
        } else {
            //enable
            self.watchedBranchNames.insert(branchName)
        }
    }

}