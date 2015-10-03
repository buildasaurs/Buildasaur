//
//  StatusViewController.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 08/03/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import AppKit
import BuildaUtils
import XcodeServerSDK
import BuildaKit

protocol StatusSiblingsViewControllerDelegate: class {
    
    func getProjectStatusViewController() -> StatusProjectViewController
    func getServerStatusViewController() -> XcodeServerViewController
    func showBuildTemplateViewControllerForTemplate(template: BuildTemplate?, project: Project, sender: SetupViewControllerDelegate?)
}

class StorableViewController: NSViewController {
    var storageManager: StorageManager!
}

class StatusViewController: StorableViewController {
    
    weak var delegate: StatusSiblingsViewControllerDelegate!

    @IBOutlet weak var editButton: NSButton!
    @IBOutlet weak var deleteButton: NSButton!
    @IBOutlet weak var lastConnectionView: NSTextField!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.editing = true
    }
    
    var editingAllowed: Bool = true {
        didSet {
            self.editButton.enabled = self.editingAllowed
        }
    }
    
    var lastAvailabilityCheckStatus: AvailabilityCheckState = .Unchecked {
        didSet {
            self.availabilityChanged(self.lastAvailabilityCheckStatus)
        }
    }
    
    var editing: Bool = false {
        didSet {
            self.reloadStatus()
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.reloadStatus()
    }
    
    @IBAction func editButtonTapped(sender: AnyObject) {
        
        if self.editing {
            //done'ing, time to save
            if self.didSave() {
                self.editing = false
            }
        } else {
            //toggle editing
            self.editing = true
        }
    }
    
    @IBAction func deleteButtonTapped(sender: AnyObject) {
        
        //ask if user really wants to delete
        UIUtils.showAlertAskingForRemoval("Do you really want to remove this config?", completion: { (remove) -> () in
            
            if remove {
                self.removeCurrentConfig()
            }
        })
    }
    
    func removeCurrentConfig() {
        assertionFailure("Must be overriden by subclasses")
    }
    
    func didSave() -> Bool {
        
        let success: Bool
        if self.pullDataFromUI() {
            self.storageManager.saveAll()
            self.checkAvailability(nil)
            self.reloadStatus()
            success = true
        } else {
            success = false
        }
        self.reloadStatus()
        return success
    }
    
    //returns whether all data is inserted, otherwise false - will show a popup explaining what's wrong
    func pullDataFromUI() -> Bool {
        //gets overriden in subclasses and called super
        return true
    }
    
    func reloadStatus() {
        assertionFailure("Must be overriden by subclasses")
    }
    
    func checkAvailability(statusChanged: ((status: AvailabilityCheckState, done: Bool) -> ())?) {
        assertionFailure("Must be overriden by subclasses")
    }
    
    func availabilityChanged(state: AvailabilityCheckState) {
        
        switch state {
            
        case .Checking:
            self.progressIndicator.startAnimation(nil)
            self.lastConnectionView.stringValue = "Checking access to server..."
        case .Failed(let error):
            self.progressIndicator.stopAnimation(nil)
            let desc = error?.localizedDescription ?? "Unknown error"
            self.lastConnectionView.stringValue = "Failed to access server, error: \n\(desc)"
        case .Succeeded:
            self.progressIndicator.stopAnimation(nil)
            self.lastConnectionView.stringValue = "Verified access, all is well!"
        case .Unchecked:
            self.progressIndicator.stopAnimation(nil)
            self.lastConnectionView.stringValue = "-"
        }
    }
}
