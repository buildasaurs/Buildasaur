//
//  StatusSyncerViewController.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 08/03/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import AppKit
import BuildaUtils
import BuildaCIServer

class StatusSyncerViewController: StatusViewController, SyncerDelegate {
        
    @IBOutlet weak var statusTextField: NSTextField!
    @IBOutlet weak var startStopButton: NSButton!
    @IBOutlet weak var statusActivityIndicator: NSProgressIndicator!
    @IBOutlet weak var syncIntervalStepper: NSStepper!
    @IBOutlet weak var syncIntervalTextField: NSTextField!
    @IBOutlet weak var lttmToggle: NSButton!
    
    var isSyncing: Bool {
        set {
            if let syncer = self.syncer() {
                syncer.active = newValue
            }
            self.delegate.getProjectStatusViewController().editingAllowed = !newValue
            self.delegate.getServerStatusViewController().editingAllowed = !newValue
        }
        get {
            if let syncer = self.syncer() {
                return syncer.active
            }
            return false
        }
    }
    
    func syncer() -> HDGitHubXCBotSyncer? {
        if let syncer = self.storageManager.syncers.first {
            if syncer.delegate == nil {
                syncer.delegate = self
                if syncer.active {
                    self.syncerBecameActive(syncer)
                } else {
                    self.syncerStopped(syncer)
                }
            }
            return syncer
        }
        return nil
    }
    
    func syncerBecameActive(syncer: Syncer) {
        self.report("Syncer is now active...")
    }
    
    func syncerStopped(syncer: Syncer) {
        self.report("Syncer is stopped")
    }
    
    func syncerDidStartSyncing(syncer: Syncer) {
        
        var messages = [
            "Syncing in progress..."
        ]

        if let lastStartedSync = self.syncer()?.lastSyncStartDate {
            let lastSyncString = "Started sync at \(lastStartedSync)"
            messages.append(lastSyncString)
        }
        
        self.reportMultiple(messages)
    }
    
    func syncerDidFinishSyncing(syncer: Syncer) {
        
        var messages = [
            "Syncer is Idle... Waiting for the next sync...",
        ]
        
        if let ourSyncer = syncer as? HDGitHubXCBotSyncer {
            
            //error?
            if let error = ourSyncer.lastSyncError {
                messages.insert("Last sync failed with error \(error.localizedDescription)", atIndex: 0)
            }
            
            //info reports
            let reports = ourSyncer.reports
            let reportsArray = reports.keys.map({ "\($0): \(reports[$0]!)" })
            messages += reportsArray
        }
        
        self.reportMultiple(messages)
    }
    
    func syncerEncounteredError(syncer: Syncer, error: NSError) {
        self.report("Error: \(error.localizedDescription)")
    }
    
    func report(string: String) {
        self.reportMultiple([string])
    }
    
    func reportMultiple(strings: [String]) {
        
        var itemsToReport = [String]()
        
        if let lastFinishedSync = self.syncer()?.lastSuccessfulSyncFinishedDate {
            let lastSyncString = "Last successful sync at \(lastFinishedSync)"
            itemsToReport.append(lastSyncString)
        }
        
        strings.map { itemsToReport.append($0) }
        
        self.statusTextField.stringValue = "\n".join(itemsToReport)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.statusTextField.stringValue = "-"
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        if let syncer = self.syncer() {
            Log.info("We have a syncer \(syncer)")
        }
    }
    
    override func reloadStatus() {

        self.startStopButton.title = self.isSyncing ? "Stop" : "Start"
        self.syncIntervalStepper.enabled = !self.isSyncing
        self.lttmToggle.enabled = !self.isSyncing
        
        if self.isSyncing {
            self.statusActivityIndicator.startAnimation(nil)
        } else {
            self.statusActivityIndicator.stopAnimation(nil)
        }
        
        if let syncer = self.syncer() {
            
            self.updateIntervalFromUIToValue(syncer.syncInterval)
            self.lttmToggle.state = syncer.waitForLttm ? NSOnState : NSOffState
        } else {
            self.updateIntervalFromUIToValue(15) //default
            self.lttmToggle.state = NSOnState //default is true
        }
    }
    
    func updateIntervalFromUIToValue(value: NSTimeInterval) {
        
        self.syncIntervalTextField.doubleValue = value
        self.syncIntervalStepper.doubleValue = value
    }
    
    @IBAction func syncIntervalStepperValueChanged(sender: AnyObject) {
        
        if let stepper = sender as? NSStepper {
            let value = stepper.doubleValue
            self.updateIntervalFromUIToValue(value)
        }
    }
    
    @IBAction func startStopButtonTapped(sender: AnyObject) {
        
        self.toggleActiveWithCompletion { () -> () in
            //
        }
    }
    
    @IBAction func manualBotManagementTapped(sender: AnyObject) {
        
        if let syncer = self.syncer() {
            self.performSegueWithIdentifier("showManual", sender: self)
        } else {
            UIUtils.showAlertWithText("Syncer must be created first. Click 'Start' and try again.")
        }
    }
    
    @IBAction func helpLttmButtonTapped(sender: AnyObject) {
        
        let urlString = "https://github.com/czechboy0/Buildasaur/blob/master/README.md#the-lttm-barrier"
        if let url = NSURL(string: urlString) {
            NSWorkspace.sharedWorkspace().openURL(url)
        }
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        
        if let manual = segue.destinationController as? ManualBotManagementViewController {
            
            manual.syncer = self.syncer()!
        }
        
    }
    
    func startSyncing() {
        
        //create a syncer, delete the old one and kick it off
        if let syncer = self.syncer() {
            self.storageManager.removeSyncer(syncer)
        }
        
        let waitForLttm = self.lttmToggle.state == NSOnState
        let syncInterval = self.syncIntervalTextField.doubleValue
        let project = self.delegate.getProjectStatusViewController().project()!
        let serverConfig = self.delegate.getServerStatusViewController().serverConfig()!
        
        if let syncer = self.storageManager.addSyncer(syncInterval, waitForLttm: waitForLttm, project: project, serverConfig: serverConfig) {
            
            syncer.active = true
            
            self.isSyncing = true
            self.reloadStatus()
        } else {
            UIUtils.showAlertWithText("Couldn't start syncer, please make sure the sync interval is > 0 seconds.")
        }
        
        self.storageManager.saveSyncers()
    }
    
    func toggleActiveWithCompletion(completion: () -> ()) {
        
        if self.isSyncing {
            
            //stop syncing
            self.isSyncing = false
            self.reloadStatus()
            
        } else if self.delegate.getProjectStatusViewController().editing ||
        self.delegate.getServerStatusViewController().editing {
            
            UIUtils.showAlertWithText("Please save your configurations above by clicking Done")
            
        } else {
            
            let group = dispatch_group_create()
            
            //validate - check availability for both sources - github and xcodeserver - only kick off if both work
            //gather data from the UI + storageManager and try to create a syncer with it
            
            var projectReady: Bool = false
            dispatch_group_enter(group)
            self.delegate.getProjectStatusViewController().checkAvailability({ (status, done) -> () in
                if done {
                    switch status {
                    case .Succeeded:
                        projectReady = true
                    default:
                        projectReady = false
                    }
                    dispatch_group_leave(group)
                }
            })
            
            var serverReady: Bool = false
            dispatch_group_enter(group)
            self.delegate.getServerStatusViewController().checkAvailability({ (status, done) -> () in
                if done {
                    switch status {
                    case .Succeeded:
                        serverReady = true
                    default:
                        serverReady = false
                    }
                    dispatch_group_leave(group)
                }
            })
            
            dispatch_group_notify(group, dispatch_get_main_queue(), { () -> Void in
                
                let allReady = projectReady && serverReady
                if allReady {
                    
                    self.startSyncing()
                } else {
                    
                    let brokenPart = projectReady ? "Xcode Server" : "Xcode Project"
                    let message = "Couldn't start syncing, please fix your \(brokenPart) settings and try again."
                    UIUtils.showAlertWithText(message)
                }
            })
        }
    }
    
    
}
