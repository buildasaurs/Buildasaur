//
//  BuildTemplateViewController.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 09/03/15.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import AppKit
import BuildaUtils
import XcodeServerSDK
import BuildaKit
import ReactiveCocoa

protocol BuildTemplateViewControllerDelegate: class {
    func didCancelEditingOfBuildTemplate(template: BuildTemplate)
}

class BuildTemplateViewController: ConfigEditViewController, NSTableViewDataSource, NSTableViewDelegate, SetupViewControllerDelegate {
    
    let buildTemplate = MutableProperty<BuildTemplate>(BuildTemplate())
    weak var cancelDelegate: BuildTemplateViewControllerDelegate?
    var projectRef: RefType!
    var xcodeServerRef: RefType!
    
    // ---
    
    private var project = MutableProperty<Project!>(nil)
    private var xcodeServer = MutableProperty<XcodeServer!>(nil)
    
    @IBOutlet weak var nameTextField: NSTextField!
    @IBOutlet weak var testDevicesActivityIndicator: NSProgressIndicator!
    @IBOutlet weak var schemesPopup: NSPopUpButton!
    @IBOutlet weak var analyzeButton: NSButton!
    @IBOutlet weak var testButton: NSButton!
    @IBOutlet weak var archiveButton: NSButton!
    @IBOutlet weak var schedulePopup: NSPopUpButton!
    @IBOutlet weak var cleaningPolicyPopup: NSPopUpButton!
    @IBOutlet weak var triggersTableView: NSTableView!
    @IBOutlet weak var deviceFilterPopup: NSPopUpButton!
    @IBOutlet weak var devicesTableView: NSTableView!
    @IBOutlet weak var deviceFilterStackItem: NSStackView!
    @IBOutlet weak var testDevicesStackItem: NSStackView!
    
    private var triggerToEdit: TriggerConfig? //?
    
    private let isFetchingDevices = MutableProperty<Bool>(false)
    private let isParsingPlatforms = MutableProperty<Bool>(false)
    
    private let testingDevices = MutableProperty<[Device]>([])
    private let schemes = MutableProperty<[XcodeScheme]>([])
    private let schedules = MutableProperty<[BotSchedule.Schedule]>([])
    private let cleaningPolicies = MutableProperty<[BotConfiguration.CleaningPolicy]>([])
    private var deviceFilters = MutableProperty<[DeviceFilter.FilterType]>([])
    
    private var selectedScheme: MutableProperty<String>!
    private var platformType: SignalProducer<DevicePlatform.PlatformType, NoError>!
    private let cleaningPolicy = MutableProperty<BotConfiguration.CleaningPolicy>(.Never)
    private let deviceFilter = MutableProperty<DeviceFilter.FilterType>(.AllAvailableDevicesAndSimulators)
    private let selectedSchedule = MutableProperty<BotSchedule>(BotSchedule.manualBotSchedule())
    private let selectedDeviceIds = MutableProperty<[String]>([])
    
    private let isValid = MutableProperty<Bool>(false)
    private var generatedTemplate: MutableProperty<BuildTemplate>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupBindings()
    }
    
    private func setupBindings() {
        
        //request project and server for specific refs from the syncer manager
        self.syncerManager
            .projectWithRef(self.projectRef)
            .startWithNext { [weak self] in
                self?.project.value = $0
        }
        self.syncerManager
            .xcodeServerWithRef(self.xcodeServerRef)
            .startWithNext { [weak self] in
                self?.xcodeServer.value = $0
        }
        
        self.project.producer.startWithNext { [weak self] in
            self?.schemes.value = $0.schemes()
        }
        
        //ui
        self.testDevicesActivityIndicator.rac_animating <~ self.isFetchingDevices
        let devicesTableViewChangeSources = combineLatest(self.testingDevices.producer, self.selectedDeviceIds.producer)
        devicesTableViewChangeSources.startWithNext { [weak self] _ -> () in
            self?.devicesTableView.reloadData()
        }
        
        let buildTemplate = self.buildTemplate.value
        self.selectedScheme = MutableProperty<String>(buildTemplate.scheme)
        self.platformType = self.selectedScheme
            .producer
            .on(next: { [weak self] _ in self?.isParsingPlatforms.value = true })
            .observeOn(QueueScheduler())
            .flatMap(.Latest) { [weak self] schemeName in
                return self?.devicePlatformFromScheme(schemeName) ?? SignalProducer<DevicePlatform.PlatformType, NoError>.never
            }.observeOn(UIScheduler())
            .on(next: { [weak self] _ in self?.isParsingPlatforms.value = false })

        self.platformType.startWithNext { [weak self] platform in
            //refetch/refilter devices
            self?.fetchDevices(platform) { () -> () in
                Log.verbose("Finished fetching devices")
            }
        }
        
        self.setupSchemes()
        self.setupSchedules()
        self.setupCleaningPolicies()
        self.setupDeviceFilter()
        
        let nextAllowed = combineLatest(
            self.isValid.producer,
            self.isFetchingDevices.producer,
            self.isParsingPlatforms.producer
        ).map {
            $0 && !$1 && !$2
        }
        self.nextAllowed <~ nextAllowed
        
        self.devicesTableView.rac_enabled <~ self.deviceFilter.producer.map {
            filter in
            return filter == .SelectedDevicesAndSimulators
        }
        
        //initial dump
        self.buildTemplate
            .producer
            .startWithNext {
            [weak self] (buildTemplate: BuildTemplate) -> () in
            
            guard let sself = self else { return }
            sself.nameTextField.stringValue = buildTemplate.name
            
            sself.selectedScheme.value = buildTemplate.scheme
            sself.schemesPopup.selectItemWithTitle(buildTemplate.scheme)
            
            sself.analyzeButton.on = buildTemplate.shouldAnalyze
            sself.testButton.on = buildTemplate.shouldTest
            sself.archiveButton.on = buildTemplate.shouldArchive
            
            let schedule = buildTemplate.schedule
            let scheduleIndex = sself.schedules.value.indexOf(schedule.schedule)
            sself.schedulePopup.selectItemAtIndex(scheduleIndex ?? 0)
            sself.selectedSchedule.value = schedule
            
            let cleaningPolicyIndex = sself.cleaningPolicies.value.indexOf(buildTemplate.cleaningPolicy)
            sself.cleaningPolicyPopup.selectItemAtIndex(cleaningPolicyIndex ?? 0)
            sself.deviceFilter.value = buildTemplate.deviceFilter
            sself.selectedDeviceIds.value = buildTemplate.testingDeviceIds
        }
        
        let notTesting = self.testButton.rac_on.map { !$0 }
        self.deviceFilterStackItem.rac_hidden <~ notTesting
        self.testDevicesStackItem.rac_hidden <~ notTesting
        
        //when we switch to not-testing, clean up the device filter and testing device ids
        notTesting.startWithNext { [weak self] in
            if $0 {
                self?.selectedDeviceIds.value = []
                self?.deviceFilter.value = .AllAvailableDevicesAndSimulators
                self?.deviceFilterPopup.selectItemAtIndex(0)
            }
        }
        
        //this must be ran AFTER the initial dump (runs synchronously), othwerise
        //the callback for name text field doesn't contain the right value.
        //the RAC text signal doesn't fire on code-trigger text changes :(
        self.setupGeneratedTemplate()
    }
    
    private func devicePlatformFromScheme(schemeName: String) -> SignalProducer<DevicePlatform.PlatformType, NoError> {
        return SignalProducer { sink, _ in
            guard let scheme = self.schemes.value.filter({ $0.name == schemeName }).first else {
                return
            }
            
            do {
                let platformType = try XcodeDeviceParser.parseDeviceTypeFromProjectUrlAndScheme(self.project.value.url, scheme: scheme).toPlatformType()
                sendNext(sink, platformType)
                sendCompleted(sink)
            } catch {
                UIUtils.showAlertWithError(error)
            }
        }
    }
    
    private func setupSchemes() {
        
        //data source
        let schemeNames = self.schemes.producer
            .map { templates in templates.sort { $0.name < $1.name } }
            .map { $0.map { $0.name } }
        schemeNames.startWithNext { [weak self] in
            self?.schemesPopup.replaceItems($0)
        }
        
        //action
        let handler = SignalProducer<AnyObject, NoError> { [weak self] sink, _ in
            if let sself = self {
                let index = sself.schemesPopup.indexOfSelectedItem
                let schemes = sself.schemes.value
                let scheme = schemes[index]
                sself.selectedScheme.value = scheme.name
            }
            sendCompleted(sink)
        }
        let action = Action { (_: AnyObject?) in handler }
        self.schemesPopup.rac_command = toRACCommand(action)
    }
    
    private func setupSchedules() {
        
        self.schedules.value = self.allSchedules()
        let scheduleNames = self.schedules
            .producer
            .map { $0.map { $0.toString() } }
        scheduleNames.startWithNext { [weak self] in
            self?.schedulePopup.replaceItems($0)
        }
        
        //action
        let handler = SignalProducer<AnyObject, NoError> { [weak self] sink, _ in
            if let sself = self {
                let index = sself.schedulePopup.indexOfSelectedItem
                let schedules = sself.schedules.value
                let scheduleType = schedules[index]
                var schedule: BotSchedule!
                
                switch scheduleType {
                case .Commit:
                    schedule = BotSchedule.commitBotSchedule()
                case .Manual:
                    schedule = BotSchedule.manualBotSchedule()
                default:
                    assertionFailure("Other schedules not yet supported")
                }
                
                sself.selectedSchedule.value = schedule
            }
            sendCompleted(sink)
        }
        let action = Action { (_: AnyObject?) in handler }
        self.schedulePopup.rac_command = toRACCommand(action)
    }
    
    private func setupCleaningPolicies() {
        
        //data source
        self.cleaningPolicies.value = self.allCleaningPolicies()
        let cleaningPolicyNames = self.cleaningPolicies
            .producer
            .map { $0.map { $0.toString() } }
        cleaningPolicyNames.startWithNext { [weak self] in
            self?.cleaningPolicyPopup.replaceItems($0)
        }
        
        //action
        let handler = SignalProducer<AnyObject, NoError> { [weak self] sink, _ in
            if let sself = self {
                let index = sself.cleaningPolicyPopup.indexOfSelectedItem
                let policies = sself.cleaningPolicies.value
                let policy = policies[index]
                sself.cleaningPolicy.value = policy
            }
            sendCompleted(sink)
        }
        let action = Action { (_: AnyObject?) in handler }
        self.cleaningPolicyPopup.rac_command = toRACCommand(action)
    }
    
    private func setupDeviceFilter() {
        
        //data source
        self.deviceFilters <~ self.platformType.map {
            BuildTemplateViewController.allDeviceFilters($0)
        }
        let filterNames = self.deviceFilters
            .producer
            .map { $0.map { $0.toString() } }
        filterNames.startWithNext { [weak self] in
            self?.deviceFilterPopup.replaceItems($0)
        }
        
        self.deviceFilters.producer.startWithNext { [weak self] in
            //ensure that when the device filters change that we
            //make sure our selected one is still valid
            guard let sself = self else { return }
            if $0.indexOf(sself.deviceFilter.value) == nil {
                sself.deviceFilter.value = .AllAvailableDevicesAndSimulators
            }
            
            //also ensure that the selected filter is in fact visually selected
            let deviceFilterIndex = $0.indexOf(sself.deviceFilter.value)
            sself.deviceFilterPopup.selectItemAtIndex(deviceFilterIndex ?? 0)
        }
        
        self.deviceFilter.producer.startWithNext { [weak self] in
            if $0 != .SelectedDevicesAndSimulators {
                self?.selectedDeviceIds.value = []
            }
        }
        
        //action
        let handler = SignalProducer<AnyObject, NoError> { [weak self] sink, _ in
            if let sself = self {
                let index = sself.deviceFilterPopup.indexOfSelectedItem
                let filters = sself.deviceFilters.value
                let filter = filters[index]
                sself.deviceFilter.value = filter
            }
            sendCompleted(sink)
        }
        let action = Action { (_: AnyObject?) in handler }
        self.deviceFilterPopup.rac_command = toRACCommand(action)
    }
    
    private var mySignal: RACSignal!
    
    private func setupGeneratedTemplate() {
        
        //sources
        let name = self.nameTextField.rac_text
        let scheme = self.selectedScheme.producer
        let analyze = self.analyzeButton.rac_on
        let test = self.testButton.rac_on
        let archive = self.archiveButton.rac_on
        let schedule = self.selectedSchedule.producer
        let cleaningPolicy = self.cleaningPolicy.producer
        //triggers
        let deviceFilter = self.deviceFilter.producer
        let deviceIds = self.selectedDeviceIds.producer
        
        let original = self.buildTemplate.producer
        let combined = combineLatest(original, name, scheme, analyze, test, archive, schedule, cleaningPolicy, deviceFilter, deviceIds)
        
        let validated = combined.map { [weak self]
            original, name, scheme, analyze, test, archive, schedule, cleaningPolicy, deviceFilter, deviceIds -> Bool in
            
            guard let sself = self else { return false }
            
            //make sure the name isn't empty
            if name.isEmpty {
                return false
            }
            
            //make sure the selected scheme is valid
            if sself.schemes.value.filter({ $0.name == scheme }).count == 0 {
                return false
            }
            
            //at least one of the three actions has to be selected
            if !analyze && !test && !archive {
                return false
            }
            
            return true
        }
        
        self.isValid <~ validated
        
        let generated = combined.forwardIf(validated).map { [weak self]
            original, name, scheme, analyze, test, archive, schedule, cleaningPolicy, deviceFilter, deviceIds -> BuildTemplate in
            
            var mod = original
            mod.projectName = self?.project.value.config.name
            mod.name = name
            mod.scheme = scheme
            mod.shouldAnalyze = analyze
            mod.shouldTest = test
            mod.shouldArchive = archive
            mod.schedule = schedule
            mod.cleaningPolicy = cleaningPolicy
            mod.deviceFilter = deviceFilter
            mod.testingDeviceIds = deviceIds
            
            return mod
        }
        
        self.generatedTemplate = MutableProperty<BuildTemplate>(self.buildTemplate.value)
        self.generatedTemplate <~ generated
    }
    
    func fetchDevices(platform: DevicePlatform.PlatformType, completion: () -> ()) {
        
        SignalProducer<[Device], NSError> { [weak self] sink, _ in
            guard let sself = self else { return }
            
            sself.isFetchingDevices.value = true
            sself.xcodeServer.value.getDevices { (devices, error) -> () in
                if let error = error {
                    sendError(sink, error)
                } else {
                    sendNext(sink, devices!)
                }
                sendCompleted(sink)
            }
            }
            .observeOn(UIScheduler())
            .start(Event.sink(
                error: { UIUtils.showAlertWithError($0) },
                completed: { [weak self] in
                    self?.isFetchingDevices.value = false
                    completion()
                },
                next: { [weak self] (devices) -> () in
                    let processed = BuildTemplateViewController
                        .processReceivedDevices(devices, platform: platform)
                    self?.testingDevices.value = processed
                }))
    }
    
    private static func processReceivedDevices(devices: [Device], platform: DevicePlatform.PlatformType) -> [Device] {
        
        let allowedPlatforms: Set<DevicePlatform.PlatformType>
        switch platform {
        case .iOS, .iOS_Simulator:
            allowedPlatforms = Set([.iOS, .iOS_Simulator])
        default:
            allowedPlatforms = Set([platform])
        }
        
        //filter first
        let filtered = devices.filter { allowedPlatforms.contains($0.platform) }
        
        let sortDevices = {
            (a: Device, b: Device) -> (equal: Bool, shouldGoBefore: Bool) in
            
            if a.simulator == b.simulator {
                return (equal: true, shouldGoBefore: true)
            }
            return (equal: false, shouldGoBefore: !a.simulator)
        }
        
        let sortConnected = {
            (a: Device, b: Device) -> (equal: Bool, shouldGoBefore: Bool) in
            
            if a.connected == b.connected {
                return (equal: true, shouldGoBefore: false)
            }
            return (equal: false, shouldGoBefore: a.connected)
        }
        
        //then sort, devices first and if match, connected first
        let sortedDevices = filtered.sort { (a, b) -> Bool in
            
            let (equalDevices, goBeforeDevices) = sortDevices(a, b)
            if !equalDevices {
                return goBeforeDevices
            }
            
            let (equalConnected, goBeforeConnected) = sortConnected(a, b)
            if !equalConnected {
                return goBeforeConnected
            }
            return true
        }
        
        return sortedDevices
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        let destinationController = segue.destinationController as! NSViewController
        
        if let triggerViewController = destinationController as? TriggerViewController {
            
            triggerViewController.inTrigger = self.triggerToEdit
            
            if let sender = sender as? SetupViewControllerDelegate {
                triggerViewController.delegate = sender
            }
        }
        
        super.prepareForSegue(segue, sender: sender)
    }

    func pullStagesFromUI(interactive: Bool) -> Bool {
        
        let analyze = (self.analyzeButton.state == NSOnState)
        self.buildTemplate.value.shouldAnalyze = analyze
        let test = (self.testButton.state == NSOnState)
        self.buildTemplate.value.shouldTest = test
        let archive = (self.archiveButton.state == NSOnState)
        self.buildTemplate.value.shouldArchive = archive
        
        let passed = analyze || test || archive
        
        if !passed && interactive {
            UIUtils.showAlertWithText("Please select at least one action (analyze/test/archive)")
        }

        //at least one action has to be enabled
        return passed
    }
    
    func pullNameFromUI() -> Bool {
        
        let name = self.nameTextField.stringValue
        if !name.isEmpty {
            self.buildTemplate.value.name = name
            return true
        } else {
            return false
        }
    }
    
    @IBAction func addTriggerButtonClicked(sender: AnyObject) {
        self.editTrigger(nil)
    }
    
    override func shouldGoNext() -> Bool {
        
        guard self.isValid.value else { return false }
        
        let newBuildTemplate = self.generatedTemplate.value
        self.buildTemplate.value = newBuildTemplate
        self.storageManager.addBuildTemplate(newBuildTemplate)
        
        return true
    }
    
    override func delete() {
        
        UIUtils.showAlertAskingForRemoval("Are you sure you want to delete this Build Template?", completion: { (remove) -> () in
            if remove {
                let template = self.buildTemplate.value
                self.storageManager.removeBuildTemplate(template)
                self.cancelDelegate?.didCancelEditingOfBuildTemplate(template)
            }
        })
    }
    
    //MARK: triggers table view
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        
        if tableView == self.triggersTableView {
            return self.buildTemplate.value.triggers.count
        } else if tableView == self.devicesTableView {
            return self.testingDevices.value.count
        }
        return 0
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        if tableView == self.triggersTableView {
            return "NOT IMPLEMENTED ATM"
            //                let triggers = self.buildTemplate.triggers
            //                if tableColumn!.identifier == "names" {
            //
            //                    let trigger = triggers[row]
            //                    return trigger.name
            //                }
        } else if tableView == self.devicesTableView {
            
            let device = self.testingDevices.value[row]
            
            switch tableColumn!.identifier {
            case "name":
                let simString = device.simulator ? "Simulator " : ""
                let connString = device.connected ? "" : "[disconnected]"
                let string = "\(simString)\(device.name) (\(device.osVersion)) \(connString)"
                return string
            case "enabled":
                let index = self.selectedDeviceIds.value
                    .indexOfFirstObjectPassingTest { $0 == device.id }
                let enabled = index > -1
                return enabled
            default:
                return nil
            }
        }
        return nil
    }
    
    func setupViewControllerDidSave(viewController: SetupViewController) {
        
        //TODO: reinstate saving
//        if let triggerViewController = viewController as? TriggerViewController {
//            
//            if let outTrigger = triggerViewController.outTrigger {
//                
//                if let inTrigger = triggerViewController.inTrigger {
//                    //was an existing trigger, just replace in place
//                    let index = self.buildTemplate.triggers.indexOfFirstObjectPassingTest { $0.id == inTrigger.id }!
//                    self.buildTemplate.triggers[index] = outTrigger
//                    
//                } else {
//                    //new trigger, just add
//                    self.buildTemplate.triggers.append(outTrigger)
//                }
//            }
//        }
        
//        self.reloadUI()
    }
    
    func setupViewControllerDidCancel(viewController: SetupViewController) {
        //
    }
    
    func editTrigger(trigger: TriggerConfig?) {
        self.triggerToEdit = trigger
        self.performSegueWithIdentifier("showTrigger", sender: self)
    }
    
    @IBAction func triggerTableViewEditTapped(sender: AnyObject) {
//        let index = self.triggersTableView.selectedRow
//        let trigger = self.buildTemplate.triggers[index]
        //TODO: pull the right config
//        self.editTrigger(trigger)
    }
    
    @IBAction func triggerTableViewDeleteTapped(sender: AnyObject) {
        let index = self.triggersTableView.selectedRow
        self.buildTemplate.value.triggers.removeAtIndex(index)
//        self.reloadUI()
    }
    
    @IBAction func testDevicesTableViewRowCheckboxTapped(sender: AnyObject) {
        
        //toggle selection in model and reload data
        
        //get device at index first
        let device = self.testingDevices.value[self.devicesTableView.selectedRow]
        
        //see if we are checking or unchecking
        let foundIndex = self.selectedDeviceIds.value.indexOfFirstObjectPassingTest({ $0 == device.id })
        
        if let foundIndex = foundIndex {
            //found, remove it
            self.selectedDeviceIds.value.removeAtIndex(foundIndex)
        } else {
            //not found, add it
            self.selectedDeviceIds.value.append(device.id)
        }
    }
}

extension BuildTemplateViewController {
    
    private func allSchedules() -> [BotSchedule.Schedule] {
        //scheduled not yet supported, just manual vs commit
        return [
            BotSchedule.Schedule.Manual,
            BotSchedule.Schedule.Commit
            //TODO: add UI support for proper schedule - hourly/daily/weekly
        ]
    }
    
    private func allCleaningPolicies() -> [BotConfiguration.CleaningPolicy] {
        return [
            BotConfiguration.CleaningPolicy.Never,
            BotConfiguration.CleaningPolicy.Always,
            BotConfiguration.CleaningPolicy.Once_a_Day,
            BotConfiguration.CleaningPolicy.Once_a_Week
        ]
    }
    
    private static func allDeviceFilters(platform: DevicePlatform.PlatformType) -> [DeviceFilter.FilterType] {
        let allFilters = DeviceFilter.FilterType.availableFiltersForPlatform(platform)
        return allFilters
    }
}
