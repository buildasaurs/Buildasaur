//
//  ManualBotManagementViewController.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 15/03/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import AppKit
import BuildaGitServer
import BuildaUtils
import XcodeServerSDK
import BuildaKit

class ManualBotManagementViewController: NSViewController {
    
    var syncer: HDGitHubXCBotSyncer!
    var storageManager: StorageManager!
    
    @IBOutlet weak var nameTextField: NSTextField!
    @IBOutlet weak var branchComboBox: NSComboBox!
    @IBOutlet weak var branchActivityIndicator: NSProgressIndicator!
    @IBOutlet weak var templateComboBox: NSComboBox!
    
    @IBOutlet weak var creatingActivityIndicator: NSProgressIndicator!
    
    private var buildTemplates: [BuildTemplate] {
        return Array(self.storageManager.buildTemplates.value.values)
            .sort {$0.id < $1.id }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(self.syncer != nil, "We need a syncer here")
        
        let names = self.buildTemplates.map({ $0.name })
        self.templateComboBox.addItemsWithObjectValues(names)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.fetchBranches { (branches, error) -> () in
            
            if let error = error {
                UIUtils.showAlertWithError(error)
            }
        }
    }
    
    func fetchBranches(completion: ([BranchType]?, ErrorType?) -> ()) {
        
        self.branchActivityIndicator.startAnimation(nil)
        let repoName = self.syncer.project.githubRepoName()!
        self.syncer.sourceServer.getBranchesOfRepo(repoName, completion: { (branches, error) -> () in
            
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                
                self.branchComboBox.removeAllItems()
                if let branches = branches {
                    let names = branches.map { $0.name }
                    self.branchComboBox.addItemsWithObjectValues(names)
                }
                
                completion(branches, error)
                self.branchActivityIndicator.stopAnimation(nil)
            })
        })
    }
    
    func pullBotName() -> String? {
        
        let name = self.nameTextField.stringValue
        if name.isEmpty {
            UIUtils.showAlertWithText("Please specify the bot's name")
            return nil
        }
        return name
    }
    
    func pullBranchName() -> String? {
        
        if let branch = self.branchComboBox.objectValueOfSelectedItem as? String where !branch.isEmpty {
            return branch
        }
        UIUtils.showAlertWithText("Please specify a valid branch")
        return nil
    }
    
    func pullTemplate() -> BuildTemplate? {
        
        let index = self.templateComboBox.indexOfSelectedItem
        if index > -1 {
            let template = self.buildTemplates[index]
            return template
        }
        UIUtils.showAlertWithText("Please specify a valid build template")
        return nil
    }
    
    func createBot() {
        
        if
            let name = self.pullBotName(),
            let branch = self.pullBranchName(),
            let template = self.pullTemplate()
        {
            let project = self.syncer.project
            let xcodeServer = self.syncer.xcodeServer
            
            self.creatingActivityIndicator.startAnimation(nil)
            XcodeServerSyncerUtils.createBotFromBuildTemplate(name, syncer: syncer,template: template, project: project, branch: branch, scheduleOverride: nil, xcodeServer: xcodeServer, completion: { (bot, error) -> () in
                
                self.creatingActivityIndicator.stopAnimation(nil)
                
                if let error = error {
                    UIUtils.showAlertWithError(error)
                } else if let bot = bot {
                    let text = "Successfully created bot \(bot.name) for branch \(bot.configuration.sourceControlBlueprint.branch)"
                    UIUtils.showAlertWithText(text, style: nil, completion: { (resp) -> () in
                        self.dismissController(nil)
                    })
                    
                } else {
                    //should never get here
                    UIUtils.showAlertWithText("Unexpected error, please report this!")
                }
                
            })

        } else {
            Log.error("Failed to satisfy some bot dependencies, ignoring...")
        }
    }
    
    @IBAction func cancelTapped(sender: AnyObject) {
        self.dismissController(nil)
    }
    
    @IBAction func createTapped(sender: AnyObject) {
        self.createBot()
    }

}

