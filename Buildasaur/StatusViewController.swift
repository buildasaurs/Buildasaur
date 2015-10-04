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
    
    func getProjectStatusViewController() -> ProjectViewController
    func getServerStatusViewController() -> XcodeServerViewController
    func showBuildTemplateViewControllerForTemplate(template: BuildTemplate?, project: Project, sender: SetupViewControllerDelegate?)
}

class StorableViewController: NSViewController {
    var storageManager: StorageManager!
}

class StatusViewController: StorableViewController {
    
    weak var delegate: StatusSiblingsViewControllerDelegate!
    
    let availabilityCheckState = MutableProperty<AvailabilityCheckState>(.Unchecked)

    @IBOutlet weak var trashButton: NSButton!
    @IBOutlet weak var gearButton: NSButton!
    
    @IBOutlet weak var nextButton: NSButton!
    @IBOutlet weak var previousButton: NSButton!

    @IBOutlet weak var lastConnectionView: NSTextField?
    @IBOutlet weak var progressIndicator: NSProgressIndicator?
    @IBOutlet weak var serverStatusImageView: NSImageView!

    let editing = MutableProperty<Bool>(true)
    var valid: SignalProducer<Bool, NoError>!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        self.setupAvailability()
    }
    
    private func setupUI() {
        
        //status image
        let statusImage = self
            .availabilityCheckState
            .producer
            .map { StatusViewController.imageNameForStatus($0) }
            .map { NSImage(named: $0) }
        self.serverStatusImageView.rac_image <~ statusImage
    }
    
    //do not call directly! just override
    func checkAvailability(statusChanged: ((status: AvailabilityCheckState, done: Bool) -> ())) {
        assertionFailure("Must be overriden by subclasses")
    }
    
    @IBAction final func gearButtonClicked(sender: AnyObject) {
        self.edit()
    }
    
    @IBAction final func trashButtonClicked(sender: AnyObject) {
        self.delete()
    }
    
    @IBAction final func previousButtonClicked(sender: AnyObject) {
        self.previous()
    }
    
    @IBAction final func nextButtonClicked(sender: AnyObject) {
        self.next()
    }
    
    func edit() {
        self.editing.value = true
    }
    
    func delete() {
        assertionFailure("Must be overriden by subclasses")
    }
    
    func previous() {
        assertionFailure("Must be overriden by subclasses")
    }

    func next() {
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
    
    private func setupAvailability() {
        
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
