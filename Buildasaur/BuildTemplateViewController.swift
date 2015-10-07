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

class BuildTemplateViewController: EditableViewController, NSComboBoxDelegate, NSTableViewDataSource, NSTableViewDelegate, SetupViewControllerDelegate, NSComboBoxDataSource {
    
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
    
    private var triggerToEdit: TriggerConfig? //?
    
    private let isFetchingDevices = MutableProperty<Bool>(false)
    private let testingDevices = MutableProperty<[Device]>([])
    private let schemes = MutableProperty<[XcodeScheme]>([])
    private let schedules = MutableProperty<[BotSchedule.Schedule]>([])
    private let cleaningPolicies = MutableProperty<[BotConfiguration.CleaningPolicy]>([])
    private var deviceFilters = MutableProperty<[DeviceFilter.FilterType]>([])
    
    private var selectedScheme: MutableProperty<String>!
    private var platformType: SignalProducer<DevicePlatform.PlatformType, NoError>!
    private var cleaningPolicy = MutableProperty<BotConfiguration.CleaningPolicy>(.Never)
    private var deviceFilter = MutableProperty<DeviceFilter.FilterType>(.AllAvailableDevicesAndSimulators)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupBindings()
    }
    
    func setupBindings() {
        
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
        self.testingDevices.producer.startWithNext { [weak self] _ -> () in
            self?.devicesTableView.reloadData()
        }
        
        let buildTemplate = self.buildTemplate.value
        self.selectedScheme = MutableProperty<String>(buildTemplate.scheme)
        self.platformType = self.selectedScheme
            .producer
            .observeOn(QueueScheduler())
            .flatMap(.Latest) { [weak self] schemeName in
                return self!.devicePlatformFromScheme(schemeName)
            }.observeOn(UIScheduler())
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
        
        //more ui
        self.devicesTableView.rac_enabled <~ self.deviceFilter.producer.map {
            filter in
            return filter == .SelectedDevicesAndSimulators
        }
        
        //initial dump
        self.buildTemplate.producer.startWithNext {
            [weak self] (buildTemplate: BuildTemplate) -> () in
            
            guard let sself = self else { return }
            sself.nameTextField.stringValue = buildTemplate.name
            sself.selectedScheme.value = buildTemplate.scheme
            sself.schemesPopup.selectItemWithTitle(buildTemplate.scheme)
            sself.analyzeButton.on = buildTemplate.shouldAnalyze
            sself.testButton.on = buildTemplate.shouldTest
            sself.archiveButton.on = buildTemplate.shouldArchive
            
            if let schedule = buildTemplate.schedule?.schedule {
                let scheduleIndex = sself.schedules.value.indexOf(schedule)
                sself.schedulePopup.selectItemAtIndex(scheduleIndex ?? 0)
            }
            
            let cleaningPolicyIndex = sself.cleaningPolicies.value.indexOf(buildTemplate.cleaningPolicy)
            sself.cleaningPolicyPopup.selectItemAtIndex(cleaningPolicyIndex ?? 0)
            sself.deviceFilter.value = buildTemplate.deviceFilter
        }
    }
    
    private func devicePlatformFromScheme(schemeName: String) -> SignalProducer<DevicePlatform.PlatformType, NoError> {
        return SignalProducer { sink, _ in
            guard let scheme = self.schemes.value.filter({ $0.name == schemeName }).first else {
                UIUtils.showAlertWithError(Error.withInfo("No scheme named \(schemeName)"))
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
    
    func setupSchemes() {
        
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
    
    func setupSchedules() {
        
        self.schedules.value = self.allSchedules()
        let scheduleNames = self.schedules
            .producer
            .map { $0.map { $0.toString() } }
        scheduleNames.startWithNext { [weak self] in
            self?.schedulePopup.replaceItems($0)
        }
    }
    
    func setupCleaningPolicies() {
        
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
    
    func setupDeviceFilter() {
        
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
    
    func fetchDevices(platform: DevicePlatform.PlatformType, completion: () -> ()) {
        
        SignalProducer<[Device], NSError> { sink, _ in
            
            self.xcodeServer.value.getDevices { (devices, error) -> () in
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
                completed: completion,
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
    
    func pullDataFromUI(interactive: Bool) -> Bool {
        
        let scheme = !self.pullSchemeFromUI(interactive).isEmpty
        let name = self.pullNameFromUI()
        let stages = self.pullStagesFromUI(interactive)
        let schedule = self.pullScheduleFromUI(interactive)
        let cleaning = self.pullCleaningPolicyFromUI(interactive)
        let filter = self.pullFilterFromUI(interactive)
        
        return scheme && name && stages && schedule && cleaning && filter
    }
    
    func pullCleaningPolicyFromUI(interactive: Bool) -> Bool {
        
//        let index = self.cleaninPolicyComboBox.indexOfSelectedItem
//        if index > -1 {
//            let policy = self.allCleaningPolicies()[index]
//            self.buildTemplate.value.cleaningPolicy = policy
//            return true
//        }
//        if interactive {
//            UIUtils.showAlertWithText("Please choose a cleaning policy")
//        }
        return false
    }

    func pullScheduleFromUI(interactive: Bool) -> Bool {
        
//        let index = self.scheduleComboBox.indexOfSelectedItem
//        if index > -1 {
//            let scheduleType = self.allSchedules()[index]
//            let schedule: BotSchedule
//            switch scheduleType {
//            case .Commit:
//                schedule = BotSchedule.commitBotSchedule()
//            case .Manual:
//                schedule = BotSchedule.manualBotSchedule()
//            default:
//                assertionFailure("Other schedules not yet supported")
//                schedule = BotSchedule(json: NSDictionary())
//            }
//            self.buildTemplate.value.schedule = schedule
//            return true
//        }
//        if interactive {
//            UIUtils.showAlertWithText("Please choose a bot schedule (choose 'Manual' for Syncer-controller bots)")
//        }
        return false
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
    
    func pullSchemeFromUI(interactive: Bool) -> String {
        
        //validate that the selection is valid
//                //found it, good, use it
//                self.buildTemplate.value.scheme = selectedScheme
//                
//                //also refresh devices for testing based on the scheme type
//                do {
//                    let platformType = try XcodeDeviceParser.parseDeviceTypeFromProjectUrlAndScheme(self.project.url, scheme: scheme).toPlatformType()
//                    self.buildTemplate.value.platformType = platformType
//                    self.reloadUI()
//                    self.fetchDevices({ () -> () in
//                        //
//                    })
//                    return true
//                } catch {
//                    print("\(error)")
//                    return false
//                }
        return ""
    }
    
    func pullFilterFromUI(interactive: Bool) -> Bool {
        
//        let index = self.testDeviceFilterComboBox.indexOfSelectedItem
//        if index > -1 {
//            let filter = self.allFilters()[index]
//            self.buildTemplate.value.deviceFilter = filter
//            return true
//        }
//        if interactive && self.testDeviceFilterComboBox.numberOfItems > 0 {
//            UIUtils.showAlertWithText("Please select a device filter to test on")
//        }
        return false
    }

    private func cleanTestingDeviceIds() {
        //don't call this during initial loading calls (this is a hack, don't try this at home kids)
        self.buildTemplate.value.testingDeviceIds = []
    }
    
    func comboBoxSelectionDidChange(notification: NSNotification) {
        
//        if let comboBox = notification.object as? NSComboBox {
//            
//            if comboBox == self.testDeviceFilterComboBox {
//                
//                self.pullFilterFromUI(true)
//                self.reloadUI()
//                self.cleanTestingDeviceIds()
//                
//                //filter changed, refetch
//                self.fetchDevices({ () -> () in
//                    //
//                })
//            } else if comboBox == self.schemesComboBox {
//                
//                if self.testDeviceFilterComboBox.numberOfItems > 0 {
//                    self.testDeviceFilterComboBox.selectItemAtIndex(0)
//                }
//                self.pullSchemeFromUI(true)
//                self.cleanTestingDeviceIds()
//            }
//        }
    }
    
    func willSave() {
        
//        self.storageManager.addBuildTemplate(self.buildTemplate)
//        super.willSave()
    }
    
    @IBAction func addTriggerButtonTapped(sender: AnyObject) {
        self.editTrigger(nil)
    }
    
    @IBAction func deleteButtonTapped(sender: AnyObject) {
        
        UIUtils.showAlertAskingForRemoval("Are you sure you want to delete this build template?", completion: { (remove) -> () in
            if remove {
//                self.storageManager.removeBuildTemplate(self.buildTemplate)
//                self.buildTemplate = nil
//                self.cancel()
            }
        })
    }
    
    //MARK: filter combo box
    func numberOfItemsInComboBox(aComboBox: NSComboBox) -> Int {
//        if (aComboBox == self.testDeviceFilterComboBox) {
//            return self.allFilters().count
//        }
        return 0
    }
    
    func comboBox(aComboBox: NSComboBox, objectValueForItemAtIndex index: Int) -> AnyObject {
//        if (aComboBox == self.testDeviceFilterComboBox) {
//            if index >= 0 {
//                return self.allFilters()[index].toString()
//            }
//        }
        return ""
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
                let devices = self.buildTemplate.value.testingDeviceIds ?? []
                let index = devices.indexOfFirstObjectPassingTest({ $0 == device.id })
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
        let foundIndex = self.buildTemplate.value.testingDeviceIds.indexOfFirstObjectPassingTest({ $0 == device.id })
        
        if let foundIndex = foundIndex {
            //found, remove it
            self.buildTemplate.value.testingDeviceIds.removeAtIndex(foundIndex)
        } else {
            //not found, add it
            self.buildTemplate.value.testingDeviceIds.append(device.id)
        }
        
        self.devicesTableView.reloadData()
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
