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

class XcodeServerViewController: StatusViewController {
    
    var serverConfig = MutableProperty<XcodeServerConfig>(XcodeServerConfig())
    
    //we have a project
    @IBOutlet weak var statusContentView: NSView!
    @IBOutlet weak var serverHostTextField: NSTextField!
    @IBOutlet weak var serverUserTextField: NSTextField!
    @IBOutlet weak var serverPasswordTextField: NSSecureTextField!
    
    private var valid: SignalProducer<Bool, NoError>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }
    
    func setup() {
        
        let server = self.serverConfig
        let servProd = server.producer
        let editing = self.editing
        
        let host = self.serverHostTextField.rac_text
        let user = self.serverUserTextField.rac_text
        let pass = self.serverPasswordTextField.rac_text
        let combined = combineLatest(host, user, pass)
        let valid = combined
            .map { try? XcodeServerConfig(host: $0, user: $1, password: $2) }
        .map { $0 != nil }
        self.valid = valid
        
        self.editButton.rac_enabled <~ valid
        
        self.deleteButton.rac_enabled <~ editing
        self.editButton.rac_title <~ editing.producer.map { $0 ? "Done" : "Edit" }
        self.serverHostTextField.rac_enabled <~ editing
        self.serverUserTextField.rac_enabled <~ editing
        self.serverPasswordTextField.rac_enabled <~ editing
        self.statusContentView.rac_hidden <~ editing.producer.map { !$0 }
        self.serverHostTextField.rac_stringValue <~ servProd.map { $0.host }
        self.serverUserTextField.rac_stringValue <~ servProd.map { $0.user ?? "" }
        self.serverPasswordTextField.rac_stringValue <~ servProd.map { $0.password ?? "" }
    }
    
    override func reloadStatus() {
        //
    }
    
    override func pullDataFromUI() -> Bool {
        if super.pullDataFromUI() {
            
            var host: String? = self.serverHostTextField.stringValue
            if host?.isEmpty ?? true {
                host = nil
            }

            var user: String? = self.serverUserTextField.stringValue
            if user?.isEmpty ?? true {
                user = nil
            }
            var password: String? = self.serverPasswordTextField.stringValue
            if password?.isEmpty ?? true {
                password = nil
            }
            
            if let host = host {
                self.storageManager.addServerConfig(host: host, user: user, password: password)
                return true
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

