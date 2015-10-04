//
//  XcodeServerViewController.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 08/03/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils
import XcodeServerSDK
import BuildaKit
import ReactiveCocoa

protocol XcodeServerViewControllerDelegate: class {
    func didCancelEditingOfXcodeServerConfig(config: XcodeServerConfig)
}

class XcodeServerViewController: StatusViewController {
    
    var serverConfig = MutableProperty<XcodeServerConfig>(XcodeServerConfig())
    
    weak var cancelDelegate: XcodeServerViewControllerDelegate?
    
    @IBOutlet weak var serverHostTextField: NSTextField!
    @IBOutlet weak var serverUserTextField: NSTextField!
    @IBOutlet weak var serverPasswordTextField: NSSecureTextField!
    @IBOutlet weak var serverStatusImageView: NSImageView!
    @IBOutlet weak var trashButton: NSButton!
    @IBOutlet weak var gearButton: NSButton!
    
    @IBOutlet weak var nextButton: NSButton!
    @IBOutlet weak var previousButton: NSButton!
    
    private var valid: SignalProducer<Bool, NoError>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }
    
    func setup() {
        
        let server = self.serverConfig
        let servProd = server.producer
        let editing = self.editing.producer
        let notEditing = editing.producer.map { !$0 }
        
        //listening to changes to textfields
        let host = self.serverHostTextField.rac_text
        let user = self.serverUserTextField.rac_text
        let pass = self.serverPasswordTextField.rac_text
        let combined = combineLatest(host, user, pass)
        let valid = combined
            .map { try? XcodeServerConfig(host: $0, user: $1, password: $2) }
            .map { $0 != nil }
        self.valid = valid
        
        //status image
        let statusImage = self
            .availabilityCheckState
            .producer
            .map { XcodeServerViewController.imageNameForStatus($0) }
            .map { NSImage(named: $0) }
        self.serverStatusImageView.rac_image <~ statusImage
        
        //enabled
        self.serverHostTextField.rac_enabled <~ editing
        self.serverUserTextField.rac_enabled <~ editing
        self.serverPasswordTextField.rac_enabled <~ editing
        self.trashButton.rac_enabled <~ editing
        self.gearButton.rac_enabled <~ notEditing
        
        //string values
        self.serverHostTextField.rac_stringValue <~ servProd.map { $0.host }
        self.serverUserTextField.rac_stringValue <~ servProd.map { $0.user ?? "" }
        self.serverPasswordTextField.rac_stringValue <~ servProd.map { $0.password ?? "" }
    }
    
    private static func imageNameForStatus(status: AvailabilityCheckState) -> String {
        
        switch status {
        case .Unchecked:
            return NSImageNameStatusNone
        case .Checking:
            return NSImageNameStatusPartiallyAvailable
        case .Succeeded:
            return NSImageNameStatusAvailable
        case .Failed(_):
            return NSImageNameStatusUnavailable
        }
    }
    
    @IBAction func nextButtonClicked(sender: AnyObject) {
        
        //first check availability of these credentials
        self.recheckForAvailability { (state) -> () in
            
            print("State: \(state)")
        }
    }
    
    @IBAction func previousButtonClicked(sender: AnyObject) {
        
        //throw away this setup, don't save anything (but don't delete either)
        self.cancelDelegate?.didCancelEditingOfXcodeServerConfig(self.serverConfig.value)
    }
    
    @IBAction func trashButtonClicked(sender: AnyObject) {
    }
    
    @IBAction func gearButtonClicked(sender: AnyObject) {
    }
    
    
    //-----
    
    override func reloadStatus() {
        //
    }
    
    override func pullDataFromUI() -> Bool {
        
        if super.pullDataFromUI() {
            
            let host = self.serverHostTextField.stringValue.nonEmpty()
            let user = self.serverUserTextField.stringValue.nonEmpty()
            let password = self.serverPasswordTextField.stringValue.nonEmpty()
            
            if let host = host {
                let oldConfigId = self.serverConfig.value.id
                let config = try! XcodeServerConfig(host: host, user: user, password: password, id: oldConfigId)
                
                do {
                    try self.storageManager.addServerConfig(config)
                    return true
                } catch StorageManagerError.DuplicateServerConfig(let duplicate) {
                    let userError = Error.withInfo("You already have a Xcode Server with host \"\(duplicate.host)\" and username \"\(duplicate.user ?? String())\", please go back and select it from the previous screen.")
                    UIUtils.showAlertWithError(userError)
                } catch {
                    UIUtils.showAlertWithError(error)
                    return false
                }
            } else {
                UIUtils.showAlertWithText("Please add a host name and IP address of your Xcode Server")
            }
        }
        return false
    }
    
    override func removeCurrentConfig() {
        
        let config = self.serverConfig.value
        self.storageManager.removeServer(config)
        self.storageManager.saveServerConfigs()
        self.editing.value = false
        self.serverHostTextField.stringValue = ""
        self.serverUserTextField.stringValue = ""
        self.serverPasswordTextField.stringValue = ""
        self.reloadStatus()
    }
    
    override func checkAvailability(statusChanged: ((status: AvailabilityCheckState, done: Bool) -> ())?) {
        
        let statusChangedPersist: (status: AvailabilityCheckState, done: Bool) -> () = {
            (status: AvailabilityCheckState, done: Bool) -> () in
            self.availabilityCheckState.value = status
            statusChanged?(status: status, done: done)
        }
        
        let config = self.serverConfig.value
        statusChangedPersist(status: .Checking, done: false)
        NetworkUtils.checkAvailabilityOfXcodeServerWithCurrentSettings(config, completion: { (success, error) -> () in
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                if success {
                    statusChangedPersist(status: .Succeeded, done: true)
                } else {
                    statusChangedPersist(status: .Failed(error), done: true)
                }
            })
        })
    }
}

