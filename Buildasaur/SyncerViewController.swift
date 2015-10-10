//
//  SyncerViewController.swift
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

protocol SyncerViewControllerDelegate: class {
    
    func didCancelEditingOfSyncerConfig(config: SyncerConfig)
    func didSaveSyncerConfig(config: SyncerConfig)
}

class SyncerViewController: ConfigEditViewController {

    let syncerConfig = MutableProperty<SyncerConfig!>(nil)
    weak var delegate: SyncerViewControllerDelegate?
    
    private let syncer = MutableProperty<HDGitHubXCBotSyncer?>(nil)
    
    @IBOutlet weak var editButton: NSButton!
    @IBOutlet weak var statusTextField: NSTextField!
    @IBOutlet weak var startStopButton: NSButton!
    @IBOutlet weak var statusActivityIndicator: NSProgressIndicator!

    @IBOutlet weak var syncIntervalStepper: NSStepper!
    @IBOutlet weak var syncIntervalTextField: NSTextField!
    @IBOutlet weak var lttmToggle: NSButton!
    @IBOutlet weak var postStatusCommentsToggle: NSButton!
    
    @IBOutlet weak var manualBotManagementButton: NSButton!
    @IBOutlet weak var branchWatchingButton: NSButton!
    
    private let isSyncing = MutableProperty<Bool>(false)
    
    private let syncInterval = MutableProperty<Double>(15)
    private let watchedBranches = MutableProperty<[String]>([])
    
    private let generatedConfig = MutableProperty<SyncerConfig!>(nil)
    
    //----
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupBindings()
    }
    
    func setupBindings() {
        
        let isSyncing = self.isSyncing.producer
        let editing = self.editing.producer

        self.editing <~ isSyncing.map { !$0 }
        
        //when a new syncer comes in, rebind the isSyncing property
        self.syncer.producer.startWithNext { [weak self] in
            guard let sself = self else { return }
            if let syncer = $0 {
                sself.isSyncing <~ syncer.activeSignalProducer
            } else {
                sself.isSyncing <~ ConstantProperty(false)
            }
        }
        
        self.startStopButton.rac_title <~ isSyncing.map { $0 ? "Stop" : "Start" }
        self.statusActivityIndicator.rac_animating <~ isSyncing
        self.manualBotManagementButton.rac_enabled <~ isSyncing
        self.branchWatchingButton.rac_enabled <~ isSyncing

        self.editButton.rac_enabled <~ editing
        self.syncIntervalStepper.rac_enabled <~ editing
        self.lttmToggle.rac_enabled <~ editing
        self.postStatusCommentsToggle.rac_enabled <~ editing
        
        //initial dump
        self.syncerConfig.producer.startWithNext { [weak self] config in
            guard let sself = self else { return }
            sself.syncIntervalStepper.doubleValue = config.syncInterval
            sself.syncInterval.value = config.syncInterval
            sself.lttmToggle.on = config.waitForLttm
            sself.postStatusCommentsToggle.on = config.postStatusComments
            sself.watchedBranches.value = config.watchedBranchNames
        }
        
        self.setupSyncInterval()
        self.setupDataSource()
        self.setupGeneratedConfig()
        self.setupSyncerReporting()
    }
    
    func setupDataSource() {
        
        precondition(self.syncerManager != nil)
        
        self.syncerConfig.producer.startWithNext { [weak self] in
            guard let sself = self else { return }
            sself.syncer <~ sself.syncerManager.syncerWithRef($0.id)
        }
    }
    
    func setupGeneratedConfig() {

        let original = self.syncerConfig.producer
        let waitForLttm = self.lttmToggle.rac_on
        let postStatusComments = self.postStatusCommentsToggle.rac_on
        let syncInterval = self.syncInterval.producer
        let watchedBranches = self.watchedBranches.producer
        
        let combined = combineLatest(
            original,
            waitForLttm,
            postStatusComments,
            syncInterval,
            watchedBranches
        )
        
        let generated = combined.map {
            (original, waitForLttm, postStatusComments, syncInterval, watchedBranches) -> SyncerConfig in
            
            var newConfig = original
            newConfig.waitForLttm = waitForLttm
            newConfig.postStatusComments = postStatusComments
            newConfig.syncInterval = syncInterval
            newConfig.watchedBranchNames = watchedBranches
            return newConfig
        }
        self.generatedConfig <~ generated.map { Optional($0) }
        
        self.generatedConfig.producer.startWithNext { [weak self] in
            
            //hmm... we technically aren't saving do disk yet
            //but at least if you edit sth else and come back you'll see
            //your latest setup.
            self?.delegate?.didSaveSyncerConfig($0)
        }
    }
    
    func setupSyncInterval() {
        
        self.syncIntervalTextField.rac_doubleValue <~ self.syncInterval
        
        //action
        let handler = SignalProducer<AnyObject, NoError> { [weak self] sink, _ in
            if let sself = self {
                let value = sself.syncIntervalStepper.doubleValue
                
                if value < 1 {
                    UIUtils.showAlertWithText("Sync interval cannot be less than 1 second.")
                    sself.syncIntervalStepper.doubleValue = 1
                } else {
                    sself.syncInterval.value = value
                }
            }
            sendCompleted(sink)
        }
        let action = Action { (_: AnyObject?) in handler }
        self.syncIntervalStepper.rac_command = toRACCommand(action)
    }
    
    @IBAction func startStopButtonTapped(sender: AnyObject) {
        self.toggleActive()
    }
    
    @IBAction func editButtonClicked(sender: AnyObject) {
    }
    
    private func toggleActive() {
        
        let isSyncing = self.isSyncing.value
        
        if isSyncing {
            
            let syncer = self.syncer.value!
            syncer.active = false
            
        } else {
            
            //not syncing
            
            //save config to disk, which will result in us having a proper
            //syncer coming from the SyncerManager
            let newConfig = self.generatedConfig.value
            self.storageManager.addSyncerConfig(newConfig)
            
            //TODO: verify syncer before starting
            
            //start syncing (now there must be a syncer)
            let syncer = self.syncer.value!
            syncer.active = true
        }
    }
}

extension SyncerViewController {
    
    //MARK: handling branch watching, manual bot management and link opening
    
    @IBAction func branchWatchingTapped(sender: AnyObject) {
        precondition(self.syncer.value != nil)
        self.performSegueWithIdentifier("showBranchWatching", sender: self)
    }
    
    @IBAction func manualBotManagementTapped(sender: AnyObject) {
        precondition(self.syncer.value != nil)
        self.performSegueWithIdentifier("showManual", sender: self)
    }
    
    private func openLink(link: String) {
        
        if let url = NSURL(string: link) {
            NSWorkspace.sharedWorkspace().openURL(url)
        }
    }
    
    @IBAction func helpLttmButtonTapped(sender: AnyObject) {
        self.openLink("https://github.com/czechboy0/Buildasaur/blob/master/README.md#unlock-the-lttm-barrier")
    }
    
    @IBAction func helpPostStatusCommentsButtonTapped(sender: AnyObject) {
        self.openLink("https://github.com/czechboy0/Buildasaur/blob/master/README.md#envelope-posting-status-comments")
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        
        if let manual = segue.destinationController as? ManualBotManagementViewController {
            manual.syncer = self.syncer.value
        }
        
        if let branchWatching = segue.destinationController as? BranchWatchingViewController {
            branchWatching.syncer = self.syncer.value
        }
    }
}

extension SyncerViewController {
    
    //MARK: status changes
    
    func setupSyncerReporting() {
        
        let producer = self.isSyncing
            .producer
            .map { (isSyncing: Bool) -> SignalProducer<String, NoError> in
                guard isSyncing else { return SignalProducer(value: "") }
                
                return SignalProducer(value: "HELLO")
        }
        producer.startWithNext { [weak self] in
            guard let sself = self else { return }
            sself.statusTextField.rac_stringValue <~ $0
        }
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
        
        if let lastStartedSync = self.syncer.value?.lastSyncStartDate {
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
        
        if let lastFinishedSync = self.syncer.value?.lastSuccessfulSyncFinishedDate {
            let lastSyncString = "Last successful sync at \(lastFinishedSync)"
            itemsToReport.append(lastSyncString)
        }
        
        strings.forEach { itemsToReport.append($0) }
        
        self.statusTextField.stringValue = itemsToReport.joinWithSeparator("\n")
    }
}
