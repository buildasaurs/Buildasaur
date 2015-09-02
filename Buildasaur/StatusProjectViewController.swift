//
//  StatusProjectViewController.swift
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

let kBuildTemplateAddNewString = "Create New..."
class StatusProjectViewController: StatusViewController, NSComboBoxDelegate, SetupViewControllerDelegate {
    
    private var _dataSource : ProjectDataSource?
    
    //no project yet
    @IBOutlet weak var addProjectButton: NSButton!
    
    //we have a project
    @IBOutlet weak var statusContentView: NSView!
    @IBOutlet weak var projectNameLabel: NSTextField!
    @IBOutlet weak var projectPathLabel: NSTextField!
    @IBOutlet weak var projectURLLabel: NSTextField!
    @IBOutlet weak var buildTemplateComboBox: NSComboBox!
    @IBOutlet weak var selectSSHPrivateKeyButton: NSButton!
    @IBOutlet weak var selectSSHPublicKeyButton: NSButton!
    @IBOutlet weak var sshPassphraseTextField: NSSecureTextField!

    //GitHub.com: Settings -> Applications -> Personal access tokens - create one for Buildasaur and put it in this text field
    @IBOutlet weak var tokenTextField: NSTextField!
    
    override func availabilityChanged(state: AvailabilityCheckState) {
        
        if let project = self.getProject() {
            project.availabilityState = state
        }
        super.availabilityChanged(state)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.buildTemplateComboBox.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tokenTextField.delegate = self
        self.lastAvailabilityCheckStatus = .Unchecked
    }
    
    //Returns the data source's project instance
    func getProject() -> Project? {
        return self.dataSource?.project
    }
    
    func buildTemplates() -> [BuildTemplate] {
        
        return self.storageManager.buildTemplates.filter { (template: BuildTemplate) -> Bool in
            if
                let projectName = template.projectName,
                let project = self.getProject()
            {
                return projectName == project.projectName ?? ""
            } else {
                //if it doesn't yet have a project name associated, assume we have to show it
                return true
            }
        }
    }
    
    override func reloadStatus() {
        
        //if there is a local project, show status. otherwise show button to add one.
        if let project = self.getProject() {
            
            self.statusContentView.hidden = false
            self.addProjectButton.hidden = true
            
            self.buildTemplateComboBox.enabled = self.editing
            self.deleteButton.hidden = !self.editing
            self.editButton.title = self.editing ? "Done" : "Edit"
            self.selectSSHPrivateKeyButton.enabled = self.editing
            self.selectSSHPublicKeyButton.enabled = self.editing
            self.sshPassphraseTextField.enabled = self.editing
            
            self.selectSSHPublicKeyButton.title = project.publicSSHKeyUrl?.lastPathComponent ?? "Select SSH Public Key"
            self.selectSSHPrivateKeyButton.title = project.privateSSHKeyUrl?.lastPathComponent ?? "Select SSH Private Key"
            self.sshPassphraseTextField.stringValue = project.sshPassphrase ?? ""
            
            //fill data in
            self.projectNameLabel.stringValue = project.projectName ?? "<NO NAME>"
            self.projectURLLabel.stringValue = project.projectURL?.absoluteString ?? "<NO URL>"
            self.projectPathLabel.stringValue = project.url.path ?? "<NO PATH>"
            
            if let githubToken = project.githubToken {
                self.tokenTextField.stringValue = githubToken
            }
            self.tokenTextField.enabled = self.editing
            
            let selectedBefore = self.buildTemplateComboBox.objectValueOfSelectedItem as? String
            self.buildTemplateComboBox.removeAllItems()
            let buildTemplateNames = self.buildTemplates().map { $0.name! }
            self.buildTemplateComboBox.addItemsWithObjectValues(buildTemplateNames + [kBuildTemplateAddNewString])
            self.buildTemplateComboBox.selectItemWithObjectValue(selectedBefore)
            
            if
                let preferredTemplateId = project.preferredTemplateId,
                let template = self.buildTemplates().filter({ $0.uniqueId == preferredTemplateId }).first
            {
                self.buildTemplateComboBox.selectItemWithObjectValue(template.name!)
            }
            
        } else {
            self.statusContentView.hidden = true
            self.addProjectButton.hidden = false
            self.tokenTextField.stringValue = ""
            self.buildTemplateComboBox.removeAllItems()
        }
    }
    
    override func checkAvailability(statusChanged: ((status: AvailabilityCheckState, done: Bool) -> ())?) {
        
        let statusChangedPersist: (status: AvailabilityCheckState, done: Bool) -> () = {
            (status: AvailabilityCheckState, done: Bool) -> () in
            self.lastAvailabilityCheckStatus = status
            statusChanged?(status: status, done: done)
        }
        
        if let _ = self.getProject() {

            statusChangedPersist(status: .Checking, done: false)

            NetworkUtils.checkAvailabilityOfGitHubWithCurrentSettingsOfProject(self.getProject()!, completion: { (success, error) -> () in
                
                let status: AvailabilityCheckState
                if success {
                    status = .Succeeded
                } else {
                    Log.error("Checking github availability error: " + (error?.description ?? "Unknown error"))
                    status = AvailabilityCheckState.Failed(error)
                }
                
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    
                    statusChangedPersist(status: status, done: true)
                })
            })

        } else {
            statusChangedPersist(status: .Unchecked, done: true)
        }
    }
        
    @IBAction func addProjectButtonTapped(sender: AnyObject) {
        
        if let url = StorageUtils.openWorkspaceOrProject() {
            
            do {
                
                try self.storageManager.addProjectAtURL(url)
                //we have just added a local source, good stuff!
                //check if we have everything, if so, enable the "start syncing" button
                self.editing = true
                
                //Set the dataSource to self here because the user is creating
                //and saving a new project.
                self.dataSource = self
                
            } catch {
                //local source is malformed, something terrible must have happened, inform the user this can't be used (log should tell why exactly)
                UIUtils.showAlertWithText("Couldn't add Xcode project at path \(url.absoluteString), error: \((error as NSError).localizedDescription).", style: NSAlertStyle.CriticalAlertStyle, completion: { (resp) -> () in
                    //
                })
            }
            
            self.reloadStatus()
        } else {
            //user cancelled
        }
    }
    
    //Combo Box Delegate
    func comboBoxWillDismiss(notification: NSNotification) {
        
        if let templatePulled = self.buildTemplateComboBox.objectValueOfSelectedItem as? String {
            
            //it's string
            var buildTemplate: BuildTemplate?
            if templatePulled != kBuildTemplateAddNewString {
                buildTemplate = self.buildTemplates().filter({ $0.name == templatePulled }).first
            }
            if buildTemplate == nil {
                buildTemplate = BuildTemplate(projectName: self.getProject()!.projectName!)
            }
            
            self.delegate.showBuildTemplateViewControllerForTemplate(buildTemplate, project: self.getProject()!, sender: self)
        }
    }
    
    func pullTemplateFromUI() -> Bool {
        
        if let _ = self.getProject() {
            let selectedIndex = self.buildTemplateComboBox.indexOfSelectedItem
            
            if selectedIndex == -1 {
                //not yet selected
                UIUtils.showAlertWithText("You need to select a Build Template first")
                return false
            }
            
            let template = self.buildTemplates()[selectedIndex]
            if let project = self.getProject() {
                project.preferredTemplateId = template.uniqueId
                return true
            }
            return false
        }
        return false
    }
    
    override func pullDataFromUI() -> Bool {
        
        if super.pullDataFromUI() {
            let successCreds = self.pullCredentialsFromUI()
            let template = self.pullTemplateFromUI()
            
            return successCreds && template
        }
        return false
    }
    
    func pullCredentialsFromUI() -> Bool {
        
        if let project = self.getProject() {
            
            _ = self.pullTokenFromUI()
            let privateUrl = project.privateSSHKeyUrl
            let publicUrl = project.publicSSHKeyUrl
            _ = self.pullSSHPassphraseFromUI() //can't fail
            let githubToken = project.githubToken
            
            let tokenPresent = githubToken != nil
            let sshValid = privateUrl != nil && publicUrl != nil
            let success = tokenPresent && sshValid
            if success {
                return true
            }
            
            UIUtils.showAlertWithText("Credentials error - you need to specify a valid personal GitHub token and valid SSH keys - SSH keys are used by Git and the token is used for talking to the API (Pulling Pull Requests, updating commit statuses etc). Please, also make sure all are added correctly.")
        }
        return false
    }
    
    func pullSSHPassphraseFromUI() -> Bool {
        
        let string = self.sshPassphraseTextField.stringValue
        if let project = self.getProject() {
            if !string.isEmpty {
                project.sshPassphrase = string
            } else {
                project.sshPassphrase = nil
            }
        }
        return true
    }
    
    func pullTokenFromUI() -> Bool {
        
        let string = self.tokenTextField.stringValue
        if let project = self.getProject() {
            if !string.isEmpty {
                project.githubToken = string
            } else {
                project.githubToken = nil
            }
        }
        return true
    }
    
    func control(control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        
        if control == self.tokenTextField {
            self.pullTokenFromUI()
        }
        if control == self.sshPassphraseTextField {
            self.pullSSHPassphraseFromUI()
        }
        return true
    }
    
    override func removeCurrentConfig() {
        
        if let project = self.getProject() {
            
            //also cleanup comboBoxes
            self.buildTemplateComboBox.stringValue = ""
            
            self.storageManager.removeProject(project)
            self.storageManager.saveProjects()
            self.reloadStatus()
        }
    }
    
    func selectKey(type: String) {
        if let url = StorageUtils.openSSHKey(type) {
            do {
                _ = try NSString(contentsOfURL: url, encoding: NSASCIIStringEncoding)
                let project = self.getProject()!
                if type == "public" {
                    project.publicSSHKeyUrl = url
                } else {
                    project.privateSSHKeyUrl = url
                }
            } catch {
                UIUtils.showAlertWithError(error as NSError)
            }
        }
        self.reloadStatus()
    }
    
    @IBAction func selectPublicKeyTapped(sender: AnyObject) {
        self.selectKey("public")
    }
    
    @IBAction func selectPrivateKeyTapped(sender: AnyObject) {
        self.selectKey("private")
    }
    
    func setupViewControllerDidSave(viewController: SetupViewController) {
        
        if let templateViewController = viewController as? BuildTemplateViewController {
            
            //select the passed in template
            var foundIdx: Int? = nil
            let template = templateViewController.buildTemplate
            for (idx, obj) in self.buildTemplates().enumerate() {
                if obj.uniqueId == template.uniqueId {
                    foundIdx = idx
                    break
                }
            }
            
            if let project = self.getProject() {
                project.preferredTemplateId = template.uniqueId
            }
            
            if let foundIdx = foundIdx {
                self.buildTemplateComboBox.selectItemAtIndex(foundIdx)
            } else {
                UIUtils.showAlertWithText("Couldn't find saved template, please report this error!")
            }
            
            self.reloadStatus()
        }
    }
    
    func setupViewControllerDidCancel(viewController: SetupViewController) {
        
        if let _ = viewController as? BuildTemplateViewController {
            //nothing to do really, reset the selection of the combo box to nothing
            self.buildTemplateComboBox.deselectItemAtIndex(self.buildTemplateComboBox.indexOfSelectedItem)
            self.reloadStatus()
        }
    }
    
}


//MARK: ProjectDataSource
extension StatusProjectViewController: ProjectDataSource {
    
    var project : Project? {
        
        return StorageManager.sharedInstance.projects.last
    }
    
    var dataSource: ProjectDataSource? {
        get {
            return self._dataSource
        }
        set {
            
            self._dataSource = newValue
        }
    }
}
