//
//  ProjectViewController.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 07/03/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import AppKit
import BuildaUtils
import XcodeServerSDK
import BuildaKit
import ReactiveCocoa

protocol ProjectViewControllerDelegate: class {
    func didCancelEditingOfProjectConfig(config: ProjectConfig)
}

class ProjectViewController: StatusViewController {
    
    var projectConfig = MutableProperty<ProjectConfig>(ProjectConfig())
    weak var cancelDelegate: ProjectViewControllerDelegate?
    
    //-----
    
//    var project: Project!

    //we have a project
    @IBOutlet weak var projectNameLabel: NSTextField!
    @IBOutlet weak var projectPathLabel: NSTextField!
    @IBOutlet weak var projectURLLabel: NSTextField!
    
    @IBOutlet weak var tokenTextField: NSTextField!
    @IBOutlet weak var selectSSHPrivateKeyButton: NSButton!
    @IBOutlet weak var selectSSHPublicKeyButton: NSButton!
    @IBOutlet weak var sshPassphraseTextField: NSSecureTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
    }
    
    func setupUI() {
        
        let proj = self.projectConfig
        let prod = proj.producer
        let editing = self.editing
        
        //editing
        self.selectSSHPrivateKeyButton.rac_enabled <~ editing
        self.selectSSHPublicKeyButton.rac_enabled <~ editing
        self.sshPassphraseTextField.rac_enabled <~ editing
        
        //strings
        self.selectSSHPublicKeyButton.rac_title <~ prod.map { $0.publicSSHKeyPath }.map {
            $0.isEmpty ? "Select SSH Public Key" : ($0 as NSString).lastPathComponent
        }
        self.selectSSHPrivateKeyButton.rac_title <~ prod.map { $0.privateSSHKeyPath }.map {
            $0.isEmpty ? "Select SSH Private Key" : ($0 as NSString).lastPathComponent
        }
        self.sshPassphraseTextField.rac_stringValue <~ prod.map { $0.sshPassphrase ?? "" }
        
        //fill data in
//        self.projectNameLabel.stringValue = project.workspaceMetadata?.projectName ?? "<NO NAME>"
//        self.projectURLLabel.stringValue = project.workspaceMetadata?.projectURL.absoluteString ?? "<NO URL>"
//        self.projectPathLabel.stringValue = project.url.path ?? "<NO PATH>"
//        
//        let githubToken = projectConfig.githubToken
//        self.tokenTextField.stringValue = githubToken
//        
//        self.tokenTextField.enabled = self.editing
//        
//        let selectedBefore = self.buildTemplateComboBox.objectValueOfSelectedItem as? String
//        self.buildTemplateComboBox.removeAllItems()
//        let buildTemplateNames = self.buildTemplates().map { $0.name! }
//        self.buildTemplateComboBox.addItemsWithObjectValues(buildTemplateNames + [kBuildTemplateAddNewString])
//        self.buildTemplateComboBox.selectItemWithObjectValue(selectedBefore)

        //TODO: where are we moving build template?
//        if
//            let preferredTemplateId = project.preferredTemplateId,
//            let template = self.buildTemplates().filter({ $0.uniqueId == preferredTemplateId }).first
//        {
//            self.buildTemplateComboBox.selectItemWithObjectValue(template.name!)
//        }
    }
    
    override func next() {
        //pull data from UI, create config, save it and try to validate
        //TODO:
        
    }
    
    override func previous() {
        self.goBack()
    }
    
    private func goBack() {
        let config = self.projectConfig.value
        self.cancelDelegate?.didCancelEditingOfProjectConfig(config)
    }
    
    override func delete() {
        
        //ask if user really wants to delete
        UIUtils.showAlertAskingForRemoval("Do you really want to remove this Xcode Project configuration? This cannot be undone.", completion: { (remove) -> () in
            
            if remove {
                self.removeCurrentConfig()
            }
        })
    }
    
    override func checkAvailability(statusChanged: ((status: AvailabilityCheckState, done: Bool) -> ())) {
        
//        let statusChangedPersist: (status: AvailabilityCheckState, done: Bool) -> () = {
//            (status: AvailabilityCheckState, done: Bool) -> () in
//            self.lastAvailabilityCheckStatus = status
//            statusChanged?(status: status, done: done)
//        }
//        
//        let project = self.project
//        statusChangedPersist(status: .Checking, done: false)
//        
//        NetworkUtils.checkAvailabilityOfGitHubWithCurrentSettingsOfProject(project, completion: { (success, error) -> () in
//            
//            let status: AvailabilityCheckState
//            if success {
//                status = .Succeeded
//            } else {
//                Log.error("Checking github availability error: " + (error?.description ?? "Unknown error"))
//                status = AvailabilityCheckState.Failed(error)
//            }
//            
//            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
//                
//                statusChangedPersist(status: status, done: true)
//            })
//        })
    }
    
    //Combo Box Delegate
    func comboBoxWillDismiss(notification: NSNotification) {
        
//        if let templatePulled = self.buildTemplateComboBox.objectValueOfSelectedItem as? String {
//            
//            //it's string
//            var buildTemplate: BuildTemplate?
//            if templatePulled != kBuildTemplateAddNewString {
//                buildTemplate = self.buildTemplates().filter({ $0.name == templatePulled }).first
//            }
//            if buildTemplate == nil {
//                buildTemplate = BuildTemplate(projectName: self.project.workspaceMetadata!.projectName)
//            }
//            
//            self.delegate.showBuildTemplateViewControllerForTemplate(buildTemplate, project: self.project, sender: self)
//        }
    }
    
    func pullTemplateFromUI() -> Bool {
        
//        let selectedIndex = self.buildTemplateComboBox.indexOfSelectedItem
//        
//        if selectedIndex == -1 {
//            //not yet selected
//            UIUtils.showAlertWithText("You need to select a Build Template first")
//            return false
//        }
//        
//        let template = self.buildTemplates()[selectedIndex]
//        if let project = self.project {
//            project.preferredTemplateId = template.id
//            return true
//        }
        return false
    }
    
    func pullDataFromUI() -> Bool {
        
        let successCreds = self.pullCredentialsFromUI()
        let template = self.pullTemplateFromUI()
        
        return successCreds && template
    }
    
    func pullCredentialsFromUI() -> Bool {
        
        //TODO: redo validation
//        _ = self.pullTokenFromUI()
//        let privateUrl = project.privateSSHKeyUrl
//        let publicUrl = project.publicSSHKeyUrl
//        _ = self.pullSSHPassphraseFromUI() //can't fail
//        let githubToken = project.githubToken
//        
//        let tokenPresent = githubToken != nil
//        let sshValid = privateUrl != nil && publicUrl != nil
//        let success = tokenPresent && sshValid
//        if success {
//            return true
//        }
        
//        UIUtils.showAlertWithText("Credentials error - you need to specify a valid personal GitHub token and valid SSH keys - SSH keys are used by Git and the token is used for talking to the API (Pulling Pull Requests, updating commit statuses etc). Please, also make sure all are added correctly.")
        return false
    }
    
    func pullSSHPassphraseFromUI() -> Bool {
        
//        let string = self.sshPassphraseTextField.stringValue
//        let project = self.project
//        if !string.isEmpty {
//            project.sshPassphrase = string
//        } else {
//            project.sshPassphrase = nil
//        }
        return true
    }
    
    func pullTokenFromUI() -> Bool {
        
//        let string = self.tokenTextField.stringValue
//        let project = self.project
//        if !string.isEmpty {
//            project.githubToken = string
//        } else {
//            project.githubToken = nil
//        }
        return true
    }
    
    func removeCurrentConfig() {
    
        let config = self.projectConfig.value
        self.storageManager.removeProjectConfig(config)
        self.goBack()
    }
    
    func selectKey(type: String) {
        if
            let url = StorageUtils.openSSHKey(type),
            let path = url.path
        {
            do {
                _ = try NSString(contentsOfURL: url, encoding: NSASCIIStringEncoding)
                if type == "public" {
                    self.projectConfig.value.publicSSHKeyPath = path
                } else {
                    self.projectConfig.value.privateSSHKeyPath = path
                }
            } catch {
                UIUtils.showAlertWithError(error as NSError)
            }
        }
    }
    
    @IBAction func selectPublicKeyTapped(sender: AnyObject) {
        self.selectKey("public")
    }
    
    @IBAction func selectPrivateKeyTapped(sender: AnyObject) {
        self.selectKey("private")
    }
}
