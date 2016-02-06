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
import Result

protocol SyncerViewControllerDelegate: class {
    
    func didCancelEditingOfSyncerConfig(config: SyncerConfig)
    func didSaveSyncerConfig(config: SyncerConfig)
    func didRequestEditing()
}

class SyncerViewController: ConfigEditViewController {

    let syncerConfig = MutableProperty<SyncerConfig!>(nil)
    
    let xcodeServerConfig = MutableProperty<XcodeServerConfig!>(nil)
    let projectConfig = MutableProperty<ProjectConfig!>(nil)
    let buildTemplate = MutableProperty<BuildTemplate!>(nil)
    
    weak var delegate: SyncerViewControllerDelegate?
    
    private let syncer = MutableProperty<StandardSyncer?>(nil)
    
    @IBOutlet weak var editButton: NSButton!
    @IBOutlet weak var statusTextField: NSTextField!
    @IBOutlet weak var startStopButton: NSButton!
    @IBOutlet weak var statusActivityIndicator: NSProgressIndicator!
    @IBOutlet weak var stateLabel: NSTextField!

    @IBOutlet weak var xcodeServerNameLabel: NSTextField!
    @IBOutlet weak var projectNameLabel: NSTextField!
    @IBOutlet weak var buildTemplateNameLabel: NSTextField!
    
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
        
        //when a new syncer comes in, rebind appropriate properties
        self.syncer.producer.startWithNext { [weak self] in
            guard let sself = self else { return }
            if let syncer = $0 {
                sself.isSyncing <~ syncer.activeSignalProducer
                
                let stateString = combineLatest(
                    syncer.state.producer,
                    syncer.activeSignalProducer.producer
                    ).map { SyncerStatePresenter.stringForState($0.0, active: $0.1) }
                sself.stateLabel.rac_stringValue <~ stateString

            } else {
                sself.isSyncing <~ ConstantProperty(false)
            }
        }
        
        //TODO: actually look into whether we've errored on the last sync
        //etc. to be more informative with this status (green should
        //only mean "Everything is OK, AFAIK", not "We're syncing")
        self.availabilityCheckState <~ self.isSyncing.producer.map { $0 ? .Succeeded : .Unchecked }
        
        self.nextTitle <~ ConstantProperty("Done")
        self.previousAllowed <~ self.isSyncing.producer.map { !$0 }
        
        self.startStopButton.rac_title <~ isSyncing.map { $0 ? "Stop" : "Start" }
        self.statusActivityIndicator.rac_animating <~ isSyncing
        self.manualBotManagementButton.rac_enabled <~ isSyncing
        self.branchWatchingButton.rac_enabled <~ isSyncing
        
        self.xcodeServerNameLabel.rac_stringValue <~ self.xcodeServerConfig.producer.map { $0.host }
        self.projectNameLabel.rac_stringValue <~ self.projectConfig.producer.map { $0.name }
        self.buildTemplateNameLabel.rac_stringValue <~ self.buildTemplate.producer.map { $0.name }

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
            sink.sendCompleted()
        }
        let action = Action { (_: AnyObject?) in handler }
        self.syncIntervalStepper.rac_command = toRACCommand(action)
    }
    
    override func delete() {
        
        //ask if user really wants to delete
        UIUtils.showAlertAskingForRemoval("Do you really want to remove this Syncer? This cannot be undone.", completion: { (remove) -> () in
            
            if remove {
                let currentConfig = self.generatedConfig.value
                self.storageManager.removeSyncer(currentConfig)
                self.delegate?.didCancelEditingOfSyncerConfig(currentConfig)
            }
        })
    }
    
    @IBAction func startStopButtonTapped(sender: AnyObject) {
        self.toggleActive()
    }
    
    @IBAction func editButtonClicked(sender: AnyObject) {
        self.editClicked()
    }
    
    private func editClicked() {
        self.delegate?.didRequestEditing()
    }
    
    override func shouldGoNext() -> Bool {
        self.save()
        return true
    }
    
    private func toggleActive() {
        
        let isSyncing = self.isSyncing.value
        
        if isSyncing {
            
            //syncing, just stop
            
            let syncer = self.syncer.value!
            syncer.active = false
            
        } else {
            
            //not syncing
            
            //save config to disk, which will result in us having a proper
            //syncer coming from the SyncerManager
            self.save()
            
            //TODO: verify syncer before starting
            
            //start syncing (now there must be a syncer)
            let syncer = self.syncer.value!
            syncer.active = true
        }
    }
    
    private func save() {
        let newConfig = self.generatedConfig.value
        self.storageManager.addSyncerConfig(newConfig)
        self.delegate?.didSaveSyncerConfig(newConfig)
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
    
    @IBAction func helpLttmButtonTapped(sender: AnyObject) {
        openLink("https://github.com/czechboy0/Buildasaur/blob/master/README.md#unlock-the-lttm-barrier")
    }
    
    @IBAction func helpPostStatusCommentsButtonTapped(sender: AnyObject) {
        openLink("https://github.com/czechboy0/Buildasaur/blob/master/README.md#envelope-posting-status-comments")
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        
        if let manual = segue.destinationController as? ManualBotManagementViewController {
            manual.syncer = self.syncer.value
            manual.storageManager = self.storageManager
        }
        
        if let branchWatching = segue.destinationController as? BranchWatchingViewController {
            branchWatching.syncer = self.syncer.value
            branchWatching.delegate = self
        }
    }
}

extension SyncerViewController: BranchWatchingViewControllerDelegate {
    
    func didUpdateWatchedBranches(branches: [String]) {
        self.watchedBranches.value = branches
        self.save()
    }
}

extension SyncerViewController {
    
    //MARK: status changes
    
    func setupSyncerReporting() {
        
        let producer = self.syncer
            .producer
            .map { (maybeSyncer: StandardSyncer?) -> SignalProducer<String, NoError> in
                guard let syncer = maybeSyncer else { return SignalProducer(value: "") }
                
                return syncer.state.producer.map {
                    return SyncerViewController.stringForEvent($0, syncer: syncer)
                }
        }
        producer.startWithNext { [weak self] in
            guard let sself = self else { return }
            sself.statusTextField.rac_stringValue <~ $0.observeOn(UIScheduler())
        }
    }
    
    static func stringForEvent(event: SyncerEventType, syncer: Syncer) -> String {
        
        switch event {
        case .DidBecomeActive:
            return self.syncerBecameActive(syncer)
        case .DidEncounterError(let error):
            return self.syncerEncounteredError(syncer, error: error)
        case .DidFinishSyncing:
            return self.syncerDidFinishSyncing(syncer)
        case .DidStartSyncing:
            return self.syncerDidStartSyncing(syncer)
        case .DidStop:
            return self.syncerStopped(syncer)
        case .Initial:
            return "Click Start to start syncing your project..."
        }
    }
    
    static func syncerBecameActive(syncer: Syncer) -> String {
        return self.report("Syncer is now active...", syncer: syncer)
    }
    
    static func syncerStopped(syncer: Syncer) -> String {
        return self.report("Syncer is stopped", syncer: syncer)
    }
    
    static func syncerDidStartSyncing(syncer: Syncer) -> String {
        
        var messages = [
            "Syncing in progress..."
        ]
        
        if let lastStartedSync = syncer.lastSyncStartDate {
            let lastSyncString = "Started sync at \(lastStartedSync)"
            messages.append(lastSyncString)
        }
        
        return self.reportMultiple(messages, syncer: syncer)
    }
    
    static func syncerDidFinishSyncing(syncer: Syncer) -> String {
        
        var messages = [
            "Syncer is Idle... Waiting for the next sync...",
        ]
        
        if let ourSyncer = syncer as? StandardSyncer {
            
            //error?
            if let error = ourSyncer.lastSyncError {
                messages.insert("Last sync failed with error \(error.localizedDescription)", atIndex: 0)
            }
            
            //info reports
            let reports = ourSyncer.reports
            let reportsArray = reports.keys.map({ "\($0): \(reports[$0]!)" })
            messages += reportsArray
        }
        
        return self.reportMultiple(messages, syncer: syncer)
    }
    
    static func syncerEncounteredError(syncer: Syncer, error: ErrorType) -> String {
        return self.report("Error: \((error as NSError).localizedDescription)", syncer: syncer)
    }
    
    static func report(string: String, syncer: Syncer) -> String {
        return self.reportMultiple([string], syncer: syncer)
    }
    
    static func reportMultiple(strings: [String], syncer: Syncer) -> String {
        
        var itemsToReport = [String]()
        
        if let lastFinishedSync = syncer.lastSuccessfulSyncFinishedDate {
            let lastSyncString = "Last successful sync at \(lastFinishedSync)"
            itemsToReport.append(lastSyncString)
        }
        
        strings.forEach { itemsToReport.append($0) }
        return itemsToReport.joinWithSeparator("\n")
    }
}
