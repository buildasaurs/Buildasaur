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
        
        //pull data in from the provided config (can be changed externally!)
        servProd.startWithNext { [weak self] config in
            self?.serverHostTextField.stringValue = config.host
            self?.serverUserTextField.stringValue = config.user ?? ""
            self?.serverPasswordTextField.stringValue = config.password ?? ""
        }
        
        //listening to changes to textfields
        let host = self.serverHostTextField.rac_text
        let user = self.serverUserTextField.rac_text
        let pass = self.serverPasswordTextField.rac_text
        let allText = combineLatest(host, user, pass)
        self.valid = allText
            .map { try? XcodeServerConfig(host: $0, user: $1, password: $2) }
            .map { $0 != nil }
        
        //change state to .Unchecked whenever any change to a textfield has been done
        self.availabilityCheckState <~ allText.map { _ in AvailabilityCheckState.Unchecked }
        
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
        self.previousButton.rac_enabled <~ editing
        
        //next is enabled if editing && valid input
        let enableNext = combineLatest(self.valid, editing.producer)
            .map { $0 && $1 }
        self.nextButton.rac_enabled <~ enableNext
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
    
    override func next() {
        
        //pull the current credentials
        guard let newConfig = self.pullConfigFromUI() else { return }
        self.serverConfig.value = newConfig
        
        //first check availability of these credentials
        self.recheckForAvailability { [weak self] (state) -> () in
            
            print("State: \(state)")
            if case .Succeeded = state {
                //stop editing
                self?.editing.value = false
                //TODO: tell delegate this step is done!
            }
        }
    }
    
    override func previous() {
        self.goBack()
    }
    
    private func goBack() {
        //throw away this setup, don't save anything (but don't delete either)
        self.cancelDelegate?.didCancelEditingOfXcodeServerConfig(self.serverConfig.value)
    }
    
    override func delete() {
        
        //ask if user really wants to delete
        UIUtils.showAlertAskingForRemoval("Do you really want to remove this Xcode Server configuration? This cannot be undone.", completion: { (remove) -> () in
            
            if remove {
                self.removeCurrentConfig()
            }
        })
    }
    
    func pullConfigFromUI() -> XcodeServerConfig? {
        
        let host = self.serverHostTextField.stringValue.nonEmpty()
        let user = self.serverUserTextField.stringValue.nonEmpty()
        let password = self.serverPasswordTextField.stringValue.nonEmpty()
        
        if let host = host {
            let oldConfigId = self.serverConfig.value.id
            let config = try! XcodeServerConfig(host: host, user: user, password: password, id: oldConfigId)
            
            do {
                try self.storageManager.addServerConfig(config)
                return config
            } catch StorageManagerError.DuplicateServerConfig(let duplicate) {
                let userError = Error.withInfo("You already have a Xcode Server with host \"\(duplicate.host)\" and username \"\(duplicate.user ?? String())\", please go back and select it from the previous screen.")
                UIUtils.showAlertWithError(userError)
            } catch {
                UIUtils.showAlertWithError(error)
                return nil
            }
        } else {
            UIUtils.showAlertWithText("Please add a host name and IP address of your Xcode Server")
        }
        return nil
    }
    
    func removeCurrentConfig() {
        
        let config = self.serverConfig.value
        self.storageManager.removeServer(config)
        self.goBack()
    }
    
    override func checkAvailability(statusChanged: ((status: AvailabilityCheckState, done: Bool) -> ())) {
        
        let config = self.serverConfig.value
        statusChanged(status: .Checking, done: false)
        NetworkUtils.checkAvailabilityOfXcodeServerWithCurrentSettings(config, completion: { (success, error) -> () in
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                if success {
                    statusChanged(status: .Succeeded, done: true)
                } else {
                    statusChanged(status: .Failed(error), done: true)
                }
            })
        })
    }
}

