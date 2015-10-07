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
    
    private var project: Project!
    private var xcodeServer: XcodeServer!
    
    @IBOutlet weak var nameTextField: NSTextField!
    @IBOutlet weak var testDevicesActivityIndicator: NSProgressIndicator!
    @IBOutlet weak var schemesPopup: NSPopUpButton!
    @IBOutlet weak var analyzeButton: NSButton!
    @IBOutlet weak var testButton: NSButton!
    @IBOutlet weak var archiveButton: NSButton!
    @IBOutlet weak var schedulePopup: NSPopUpButton!
    @IBOutlet weak var cleaninPolicyPopup: NSPopUpButton!
    @IBOutlet weak var triggersTableView: NSTableView!
    @IBOutlet weak var testDeviceFilterPopup: NSPopUpButton!
    @IBOutlet weak var testDevicesTableView: NSTableView!
    
    private var triggerToEdit: TriggerConfig? //?
    
    private let isFetchingDevices = MutableProperty<Bool>(false)
    private var testingDevices = MutableProperty<[Device]>([])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupBindings()
    }
    
    func setupBindings() {
        
        //request project and server for specific refs from the syncer manager
        self.syncerManager
            .projectWithRef(self.projectRef)
            .startWithNext { [weak self] in
                self?.project = $0
        }
        self.syncerManager
            .xcodeServerWithRef(self.xcodeServerRef)
            .startWithNext { [weak self] in
            self?.xcodeServer = $0
        }
        
        //ui
        self.testDevicesActivityIndicator.rac_animating <~ self.isFetchingDevices
        self.testingDevices.producer.startWithNext { [weak self] _ -> () in
            self?.testDevicesTableView.reloadData()
        }
    }
    
    
    
    
    
    
    
    
    func allSchedules() -> [BotSchedule.Schedule] {
        //scheduled not yet supported, just manual vs commit
        return [
            BotSchedule.Schedule.Manual,
            BotSchedule.Schedule.Commit
            //TODO: add UI support for proper schedule - hourly/daily/weekly
        ]
    }
    
    func allCleaningPolicies() -> [BotConfiguration.CleaningPolicy] {
        return [
            BotConfiguration.CleaningPolicy.Never,
            BotConfiguration.CleaningPolicy.Always,
            BotConfiguration.CleaningPolicy.Once_a_Day,
            BotConfiguration.CleaningPolicy.Once_a_Week
        ]
    }
    
    func allFilters() -> [DeviceFilter.FilterType] {
        let currentPlatformType = self.buildTemplate.value.platformType ?? .Unknown
        let allFilters = DeviceFilter.FilterType.availableFiltersForPlatform(currentPlatformType)
        return allFilters
    }
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
    
//        if let xcodeServerConfig = self.storageManager.serverConfigs.value.values.first {
//            let xcodeServer = XcodeServerFactory.server(xcodeServerConfig)
//            self.xcodeServer = xcodeServer
//        }
//        
//        self.testDeviceFilterComboBox.delegate = self
//        self.testDeviceFilterComboBox.usesDataSource = true
//        self.testDeviceFilterComboBox.dataSource = self
//        
//        let schemeNames = self.project.schemes().map { $0.name }
//        self.schemesComboBox.removeAllItems()
//        self.schemesComboBox.addItemsWithObjectValues(schemeNames)
//        
//        let temp = self.buildTemplate
//
//        let projectName = self.project.workspaceMetadata!.projectName
//        self.buildTemplate.value.projectName = projectName
//
//        //name
//        self.nameTextField.stringValue = temp.name ?? ""
//        
//        //schemes
//        if let preferredScheme = temp.scheme {
//            self.schemesComboBox.selectItemWithObjectValue(preferredScheme)
//        }
//        
//        //stages
//        self.analyzeButton.state = (temp.shouldAnalyze ?? false) ? NSOnState : NSOffState
//        self.testButton.state = (temp.shouldTest ?? false) ? NSOnState : NSOffState
//        self.archiveButton.state = (temp.shouldArchive ?? false) ? NSOnState : NSOffState
//        
//        //cleaning policy and schedule
//        self.scheduleComboBox.removeAllItems()
//        self.scheduleComboBox.addItemsWithObjectValues(self.allSchedules().map({ $0.toString() }))
//        if let schedule = self.buildTemplate.schedule {
//            let index = self.allSchedules().indexOfFirstObjectPassingTest({ $0 == schedule.schedule })!
//            self.scheduleComboBox.selectItemAtIndex(index)
//        }
//        self.scheduleComboBox.delegate = self
//        
//        self.cleaninPolicyComboBox.removeAllItems()
//        self.cleaninPolicyComboBox.addItemsWithObjectValues(self.allCleaningPolicies().map({ $0.toString() }))
//        let cleaningPolicy = self.buildTemplate.cleaningPolicy
//        let cleaningIndex = self.allCleaningPolicies().indexOfFirstObjectPassingTest({ $0 == cleaningPolicy })!
//        self.cleaninPolicyComboBox.selectItemAtIndex(cleaningIndex)
//        
//        self.cleaninPolicyComboBox.delegate = self
//        
//        self.refreshDataInDeviceFilterComboBox()
//        
//        self.triggersTableView.reloadData()
//        self.testDeviceFilterComboBox.reloadData()
//    }
    
    func refreshDataInDeviceFilterComboBox() {
        
//        self.testDeviceFilterComboBox.reloadData()
//        
//        let filters = self.allFilters()
//        
//        let filter = self.buildTemplate.deviceFilter ?? .AllAvailableDevicesAndSimulators
        //        if let destinationIndex = filters.indexOfFirstObjectPassingTest({ $0 == filter }) {
        //            self.testDeviceFilterComboBox.selectItemAtIndex(destinationIndex)
        //        }
    }
    
    func fetchDevices(completion: () -> ()) {
        
        SignalProducer<[Device], NSError> { sink, _ in
            
            self.xcodeServer.getDevices { (devices, error) -> () in
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
                    if let sself = self {
                        let processed = sself.processReceivedDevices(devices)
                        sself.testingDevices.value = processed
                    }
                }))
    }
    
    private func processReceivedDevices(devices: [Device]) -> [Device] {
        
        //pull filter from platform type
        guard let platform = self.buildTemplate.value.platformType else {
            return []
        }
        
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

    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.fetchDevices { () -> () in
            Log.verbose("Finished fetching devices")
        }
    }
    
    func reloadUI() {
        
        self.triggersTableView.reloadData()
        
        //enable devices table view only if selected devices is chosen
        let filter = self.buildTemplate.value.deviceFilter ?? .AllAvailableDevicesAndSimulators
        let selectable = filter == .SelectedDevicesAndSimulators
        self.testDevicesTableView.enabled = selectable
        
        //also change the device filter picker based on the platform
        self.refreshDataInDeviceFilterComboBox()
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
        
        let scheme = self.pullSchemeFromUI(interactive)
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
            self.buildTemplate.value.name = nil
            return false
        }
    }
    
    func pullSchemeFromUI(interactive: Bool) -> Bool {
        
        //validate that the selection is valid
//        if let selectedScheme = self.schemesComboBox.objectValueOfSelectedItem as? String
//        {
//            let schemes = self.project.schemes()
//            let schemeNames = schemes.map { $0.name }
//            let index = schemeNames.indexOf(selectedScheme)
//            if let index = index {
//                
//                let scheme = schemes[index]
//                
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
//            }
//        }
//        
//        if interactive {
//            UIUtils.showAlertWithText("Please select a scheme to build with")
//        }
        return false
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
        } else if tableView == self.testDevicesTableView {
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
        } else if tableView == self.testDevicesTableView {
            
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
        self.reloadUI()
    }
    
    @IBAction func testDevicesTableViewRowCheckboxTapped(sender: AnyObject) {
        
        //toggle selection in model and reload data
        
        //get device at index first
        let device = self.testingDevices.value[self.testDevicesTableView.selectedRow]
        
        //see if we are checking or unchecking
        let foundIndex = self.buildTemplate.value.testingDeviceIds.indexOfFirstObjectPassingTest({ $0 == device.id })
        
        if let foundIndex = foundIndex {
            //found, remove it
            self.buildTemplate.value.testingDeviceIds.removeAtIndex(foundIndex)
        } else {
            //not found, add it
            self.buildTemplate.value.testingDeviceIds.append(device.id)
        }
        
        self.testDevicesTableView.reloadData()
    }
}
