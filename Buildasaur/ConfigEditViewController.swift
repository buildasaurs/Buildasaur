//
//  ConfigEditViewController.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 08/03/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Cocoa
import BuildaUtils
import XcodeServerSDK
import BuildaKit
import ReactiveCocoa

class ConfigEditViewController: EditableViewController {
    
    let availabilityCheckState = MutableProperty<AvailabilityCheckState>(.Unchecked)
    
    @IBOutlet weak var trashButton: NSButton!
    @IBOutlet weak var lastConnectionView: NSTextField?
    @IBOutlet weak var progressIndicator: NSProgressIndicator?
    @IBOutlet weak var serverStatusImageView: NSImageView!

    var valid: SignalProducer<Bool, NoError>!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupUI()
        self.setupAvailability()
    }
    
    private func setupUI() {
        
        if self.serverStatusImageView != nil {
            //status image
            let statusImage = self
                .availabilityCheckState
                .producer
                .map { ConfigEditViewController.imageNameForStatus($0) }
                .map { NSImage(named: $0) }
            self.serverStatusImageView.rac_image <~ statusImage
        }
        
        if self.trashButton != nil {
            //only enable the delete button in editing mode
            self.trashButton.rac_enabled <~ self.editing
        }
    }
    
    //do not call directly! just override
    func checkAvailability(statusChanged: ((status: AvailabilityCheckState) -> ())) {
        assertionFailure("Must be overriden by subclasses")
    }
        
    @IBAction final func trashButtonClicked(sender: AnyObject) {
        self.delete()
    }
    
    func edit() {
        self.editing.value = true
    }
    
    func delete() {
        assertionFailure("Must be overriden by subclasses")
    }
    
    final func recheckForAvailability(completion: ((state: AvailabilityCheckState) -> ())?) {
        self.editingAllowed.value = false
        self.checkAvailability { [weak self] (status) -> () in
            self?.availabilityCheckState.value = status
            if status.isDone() {
                completion?(state: status)
                self?.editingAllowed.value = true
            }
        }
    }
    
    private func setupAvailability() {
        
        let state = self.availabilityCheckState.producer
        if let progress = self.progressIndicator {
            progress.rac_animating <~ state.map { $0 == .Checking }
        }
        if let lastConnection = self.lastConnectionView {
            lastConnection.rac_stringValue <~ state.map { ConfigEditViewController.stringForState($0) }
        }
    }
    
    private static func stringForState(state: AvailabilityCheckState) -> String {
        
        //TODO: add some emoji!
        switch state {
        case .Checking:
            return "Checking access to server..."
        case .Failed(let error):
            let desc = (error as? NSError)?.localizedDescription ?? "\(error)"
            return "Failed to access server, error: \n\(desc)"
        case .Succeeded:
            return "Verified access, all is well!"
        case .Unchecked:
            return "-"
        }
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
}
