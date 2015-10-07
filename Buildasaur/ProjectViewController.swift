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

class ProjectViewController: ConfigEditViewController {
    
    var projectConfig = MutableProperty<ProjectConfig>(ProjectConfig())
    weak var cancelDelegate: ProjectViewControllerDelegate?
    
    private var project: Project!
    
    private var privateKeyUrl = MutableProperty<NSURL?>(nil)
    private var publicKeyUrl = MutableProperty<NSURL?>(nil)

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
        
        let projConf = self.projectConfig
        let prod = projConf.producer
        let editing = self.editing
        let proj = prod.map { newConfig in
            //this config already went through validation like a second ago.
            return try! Project(config: newConfig)
        }
        
        //project
        proj.startWithNext { [weak self] in self?.project = $0 }
        
        //enabled
        self.selectSSHPrivateKeyButton.rac_enabled <~ editing
        self.selectSSHPublicKeyButton.rac_enabled <~ editing
        self.sshPassphraseTextField.rac_enabled <~ editing
        self.tokenTextField.rac_enabled <~ editing
        
        //editable data
        let privateKey = self.privateKeyUrl.producer
        let publicKey = self.publicKeyUrl.producer
        
        let privateKeyPath = privateKey.map { $0?.path }
        let publicKeyPath = publicKey.map { $0?.path }
        
        self.selectSSHPrivateKeyButton.rac_title <~ privateKeyPath.map {
            $0 ?? "Select SSH Private Key"
        }
        self.selectSSHPublicKeyButton.rac_title <~ publicKeyPath.map {
            $0 ?? "Select SSH Public Key"
        }
        
        //dump whenever config changes
        prod.startWithNext { [weak self] in
            
            self?.tokenTextField.stringValue = $0.githubToken
            let priv = $0.privateSSHKeyPath
            self?.privateKeyUrl.value = priv.isEmpty ? nil : NSURL(fileURLWithPath: priv)
            let pub = $0.publicSSHKeyPath
            self?.publicKeyUrl.value = pub.isEmpty ? nil : NSURL(fileURLWithPath: pub)
            self?.sshPassphraseTextField.stringValue = $0.sshPassphrase ?? ""
        }
        
        let meta = proj.map { $0.workspaceMetadata! }
        
        //fill data in
        self.projectNameLabel.rac_stringValue <~ meta.map { $0.projectName }
        self.projectURLLabel.rac_stringValue <~ meta.map { $0.projectURL.absoluteString }
        self.projectPathLabel.rac_stringValue <~ meta.map { $0.projectPath }
        
        //invalidate availability on change of any input
        let privateKeyVoid = privateKey.map { _ in }
        let publicKeyVoid = publicKey.map { _ in }
        let githubTokenVoid = self.tokenTextField.rac_text.map { _ in }
        let sshPassphraseVoid = self.sshPassphraseTextField.rac_text.map { _ in }
        let all = combineLatest(privateKeyVoid, publicKeyVoid, githubTokenVoid, sshPassphraseVoid)
        all.startWithNext { [weak self] _ in self?.availabilityCheckState.value = .Unchecked }
        
        //listen for changes
        let privateKeyValid = privateKey.map { $0 != nil }
        let publicKeyValid = publicKey.map { $0 != nil }
        let githubTokenValid = self.tokenTextField.rac_text.map { !$0.isEmpty }
        
        let allInputs = combineLatest(privateKeyValid, publicKeyValid, githubTokenValid)
        let valid = allInputs.map { $0.0 && $0.1 && $0.2 }
        self.valid = valid
        
        //control buttons
        let enableNext = combineLatest(self.valid, editing.producer)
            .map { $0 && $1 }
        self.nextAllowed <~ enableNext
        self.trashButton.rac_enabled <~ editing
    }
    
    override func shouldGoNext() -> Bool {
        
        //pull data from UI, create config, save it and try to validate
        guard let newConfig = self.pullConfigFromUI() else { return false }
        self.projectConfig.value = newConfig
        
        //check availability of these credentials
        self.recheckForAvailability { [weak self] (state) -> () in
            
            if case .Succeeded = state {
                //stop editing
                self?.editing.value = false

                //animated!
                delayClosure(1) {
                    self?.goNext(animated: true)
                }
            }
        }
        return false
    }
    
    func previous() {
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
    
    override func checkAvailability(statusChanged: ((status: AvailabilityCheckState) -> ())) {
        
        AvailabilityChecker
            .projectAvailability()
            .apply(self.projectConfig.value)
            .startWithNext {
                statusChanged(status: $0)
        }
    }
    
    func pullConfigFromUI() -> ProjectConfig? {
        
        let sshPassphrase = self.sshPassphraseTextField.stringValue.nonEmpty()
        guard
            let privateKeyPath = self.privateKeyUrl.value?.path,
            let publicKeyPath = self.publicKeyUrl.value?.path,
            let githubToken = self.tokenTextField.stringValue.nonEmpty() else {
            return nil
        }
        
        var config = self.projectConfig.value
        config.githubToken = githubToken
        config.sshPassphrase = sshPassphrase
        config.privateSSHKeyPath = privateKeyPath
        config.publicSSHKeyPath = publicKeyPath
        
        do {
            try self.storageManager.addProjectConfig(config)
            return config
        } catch StorageManagerError.DuplicateProjectConfig(let duplicate) {
            let userError = Error.withInfo("You already have a Project at \"\(duplicate.url)\", please go back and select it from the previous screen.")
            UIUtils.showAlertWithError(userError)
        } catch {
            UIUtils.showAlertWithError(error)
        }
        return nil
    }
    
    func removeCurrentConfig() {
    
        let config = self.projectConfig.value
        self.storageManager.removeProjectConfig(config)
        self.goBack()
    }
    
    func selectKey(type: String) {
        
        if let url = StorageUtils.openSSHKey(type) {
            do {
                _ = try NSString(contentsOfURL: url, encoding: NSASCIIStringEncoding)
                if type == "public" {
                    self.publicKeyUrl.value = url
                } else {
                    self.privateKeyUrl.value = url
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
