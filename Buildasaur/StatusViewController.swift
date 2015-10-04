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
import ReactiveCocoa

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
    
    let availabilityCheckState = MutableProperty<AvailabilityCheckState>(.Unchecked)

    @IBOutlet weak var editButton: NSButton!
    @IBOutlet weak var deleteButton: NSButton!
    @IBOutlet weak var lastConnectionView: NSTextField?
    @IBOutlet weak var progressIndicator: NSProgressIndicator?

    let editing = MutableProperty<Bool>(true)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAvailability()
        
        self.editing.producer.startWithNext { [weak self] _ in self?.reloadStatus() }
//        self.editButton.rac_enabled <~
    }
    
    var editingAllowed: Bool = true {
        didSet {
            self.editButton.enabled = self.editingAllowed
        }
    }
    
    var lastAvailabilityCheckStatus: AvailabilityCheckState {
        return self.availabilityCheckState.value
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.reloadStatus()
    }
    
    @IBAction func editButtonTapped(sender: AnyObject) {
        
        if self.editing.value {
            //done'ing, time to save
            if self.didSave() {
                self.editing.value = false
            }
        } else {
            //toggle editing
            self.editing.value = true
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
    
    //do not call directly! just override
    func checkAvailability(statusChanged: ((status: AvailabilityCheckState, done: Bool) -> ())?) {
        assertionFailure("Must be overriden by subclasses")
    }
    
    final func recheckForAvailability(completion: ((state: AvailabilityCheckState) -> ())?) {
        self.checkAvailability { [weak self] (status, done) -> () in
            self?.availabilityCheckState.value = status
            if done {
                completion?(state: status)
            }
        }
    }
    
    func setupAvailability() {
        
        let state = self.availabilityCheckState.producer
        if let progress = self.progressIndicator {
            progress.rac_animating <~ state.map { $0 == .Checking }
        }
        if let lastConnection = self.lastConnectionView {
            lastConnection.rac_stringValue <~ state.map { StatusViewController.stringForState($0) }
        }
    }
    
    private static func stringForState(state: AvailabilityCheckState) -> String {
        
        //TODO: add some emoji!
        switch state {
        case .Checking:
            return "Checking access to server..."
        case .Failed(let error):
            let desc = error?.localizedDescription ?? "Unknown error"
            return "Failed to access server, error: \n\(desc)"
        case .Succeeded:
            return "Verified access, all is well!"
        case .Unchecked:
            return "-"
        }
    }
}
