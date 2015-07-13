//
//  StatusServerViewController.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 08/03/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils
import XcodeServerSDK

class StatusServerViewController: StatusViewController {
    
    //no project yet
    @IBOutlet weak var addServerButton: NSButton!
    
    //we have a project
    @IBOutlet weak var statusContentView: NSView!
    @IBOutlet weak var serverHostTextField: NSTextField!
    @IBOutlet weak var serverUserTextField: NSTextField!
    @IBOutlet weak var serverPasswordTextField: NSSecureTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.serverConfig() == nil {
            self.editing = false
        }
        
        self.lastConnectionView.stringValue = "-"
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
    }
    
    override func availabilityChanged(state: AvailabilityCheckState) {
        
        if let config = self.serverConfig() {
            config.availabilityState = state
        }
        super.availabilityChanged(state)
    }

    func serverConfig() -> XcodeServerConfig? {
        return self.storageManager.servers.first
    }
    
    override func reloadStatus() {
        
        self.deleteButton.hidden = !self.editing
        self.editButton.title = self.editing ? "Done" : "Edit"
        self.serverHostTextField.enabled = self.editing
        self.serverUserTextField.enabled = self.editing
        self.serverPasswordTextField.enabled = self.editing
        
        let server = self.serverConfig()
        
        if self.editing || server != nil {

            self.addServerButton.hidden = true
            self.statusContentView.hidden = false
            
            if let server = server {
                if self.serverHostTextField.stringValue.isEmpty {
                    self.serverHostTextField.stringValue = server.host
                }
                self.serverUserTextField.stringValue = server.user ?? ""
                self.serverPasswordTextField.stringValue = server.password ?? ""
            }
            
        } else {
            self.addServerButton.hidden = false
            self.statusContentView.hidden = true
        }
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
                
                if let config = self.serverConfig() {
                    self.storageManager.removeServer(config)
                }
                self.storageManager.addServerConfig(host: host, user: user, password: password)
            } else {
                UIUtils.showAlertWithText("Please add a host name or IP address of your Xcode Server")
                return false
            }
            
            return true
        }
        return false
    }
    
    override func removeCurrentConfig() {
        
        if let config = self.serverConfig() {
            self.storageManager.removeServer(config)
            self.storageManager.saveServers()
            self.editing = false
            self.serverHostTextField.stringValue = ""
            self.serverUserTextField.stringValue = ""
            self.serverPasswordTextField.stringValue = ""
        }
        self.reloadStatus()
    }
    
    override func checkAvailability(statusChanged: ((status: AvailabilityCheckState, done: Bool) -> ())?) {

        let statusChangedPersist: (status: AvailabilityCheckState, done: Bool) -> () = {
            (status: AvailabilityCheckState, done: Bool) -> () in
            self.lastAvailabilityCheckStatus = status
            statusChanged?(status: status, done: done)
        }

        if let config = self.serverConfig() {
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
        } else {
            statusChangedPersist(status: .Unchecked, done: true)
        }
    }
    
    @IBAction func addServerButtonTapped(sender: AnyObject) {
        
        self.editing = true
    }
}