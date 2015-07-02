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

class BuildTemplateViewController: SetupViewController, NSComboBoxDelegate, NSTableViewDataSource, NSTableViewDelegate, SetupViewControllerDelegate {
    
    var storageManager: StorageManager!
    var project: LocalSource!
    var buildTemplate: BuildTemplate!
    var xcodeServer: XcodeServer?
    
    @IBOutlet weak var nameTextField: NSTextField!
    @IBOutlet weak var schemesComboBox: NSComboBox!

    @IBOutlet weak var archiveButton: NSButton!
    @IBOutlet weak var testButton: NSButton!
    @IBOutlet weak var analyzeButton: NSButton!
    @IBOutlet weak var saveButton: NSButton!
    @IBOutlet weak var triggersTableView: NSTableView!
    
    @IBOutlet weak var scheduleComboBox: NSComboBox!
    @IBOutlet weak var cleaninPolicyComboBox: NSComboBox!
    @IBOutlet weak var testDeviceFilterComboBox: NSComboBox!
    @IBOutlet weak var testDevicesTableView: NSTableView!
    @IBOutlet weak var testDevicesActivityIndicator: NSProgressIndicator!
    
    private var triggerToEdit: Trigger?
    private var allAvailableTestingDevices: [Device] = []
    
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
        let currentPlatformType = self.buildTemplate.platformType ?? .Unknown
        let allFilters = DeviceFilter.FilterType.availableFiltersForPlatform(currentPlatformType)
        return allFilters
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let xcodeServerConfig = self.storageManager.servers.first {
            let xcodeServer = XcodeServerFactory.server(xcodeServerConfig)
            self.xcodeServer = xcodeServer
        }
        
        let schemes = self.project.schemeNames()
        self.schemesComboBox.removeAllItems()
        self.schemesComboBox.addItemsWithObjectValues(schemes)
        
        let temp = self.buildTemplate
        
        //name
        self.nameTextField.stringValue = temp.name ?? ""
        
        //schemes
        if let preferredScheme = temp.scheme {
            self.schemesComboBox.selectItemWithObjectValue(preferredScheme)
        }
        
        //stages
        self.analyzeButton.state = (temp.shouldAnalyze ?? false) ? NSOnState : NSOffState
        self.testButton.state = (temp.shouldTest ?? false) ? NSOnState : NSOffState
        self.archiveButton.state = (temp.shouldArchive ?? false) ? NSOnState : NSOffState
        
        //cleaning policy and schedule
        self.scheduleComboBox.removeAllItems()
        self.scheduleComboBox.addItemsWithObjectValues(self.allSchedules().map({ $0.toString() }))
        if let schedule = self.buildTemplate.schedule {
            let index = self.allSchedules().indexOfFirstObjectPassingTest({ $0 == schedule.schedule })!
            self.scheduleComboBox.selectItemAtIndex(index)
        }
        self.scheduleComboBox.delegate = self
        
        self.cleaninPolicyComboBox.removeAllItems()
        self.cleaninPolicyComboBox.addItemsWithObjectValues(self.allCleaningPolicies().map({ $0.toString() }))
        let cleaningPolicy = self.buildTemplate.cleaningPolicy
        let cleaningIndex = self.allCleaningPolicies().indexOfFirstObjectPassingTest({ $0 == cleaningPolicy })!
        self.cleaninPolicyComboBox.selectItemAtIndex(cleaningIndex)
        
        self.cleaninPolicyComboBox.delegate = self
        
        self.refreshDataInDeviceFilterComboBox()
        
        self.triggersTableView.reloadData()
    }
    
    func refreshDataInDeviceFilterComboBox() {
        
        self.testDeviceFilterComboBox.removeAllItems()
        
        let allFilterNames = self.allFilters().map({ (item) -> String in return item.toString() })
        self.testDeviceFilterComboBox.addItemsWithObjectValues(allFilterNames)
        
        let filter = self.buildTemplate.deviceFilter ?? .AllAvailableDevicesAndSimulators
        if let destinationIndex = self.allFilters().indexOfFirstObjectPassingTest({ $0 == filter }) {
            self.testDeviceFilterComboBox.selectItemAtIndex(destinationIndex)
        }
        
        self.testDeviceFilterComboBox.delegate = self
    }
    
    func fetchDevices(completion: () -> ()) {
        
        self.testDevicesActivityIndicator.startAnimation(nil)
        self.allAvailableTestingDevices.removeAll(keepCapacity: true)
        self.testDevicesTableView.reloadData()
        
        if let xcodeServer = self.xcodeServer {
            
            xcodeServer.getDevices({ (devices, error) -> () in
                
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    
                    if let error = error {
                        UIUtils.showAlertWithError(error)
                        return
                    }
            
                    self.allAvailableTestingDevices = self.processReceivedDevices(devices!)
                    self.testDevicesTableView.reloadData()
                    self.testDevicesActivityIndicator.stopAnimation(nil)
                })
            })
            
        } else {
            UIUtils.showAlertWithText("Please setup Xcode Server first, so that we can fetch testing devices")
            completion()
        }
    }
    
    func processReceivedDevices(devices: [Device]) -> [Device] {
        
        //TODO: migrate this over
        //pull filter from testing destination
//        var filter = BotConfiguration.TestingDestinationIdentifier.AllCompatible
//        let index = self.testDestinationComboBox.indexOfSelectedItem
//        if index > -1 {
//            filter = self.allDestinations()[index]
//        }
//        
//        let allowedDeviceTypes = Set(filter.allowedDeviceTypes())
//        
//        //filter first
//        let filtered = devices.filter { (device: Device) -> Bool in
//            if let type = BotConfiguration.DeviceType(rawValue: device.deviceType) {
//                return allowedDeviceTypes.contains(type)
//            }
//            return false
//        }
//        
//        let sortDevices = {
//            (a: Device, b: Device) -> (equal: Bool, shouldGoBefore: Bool) in
//            
//            if a.simulator == b.simulator {
//                return (equal: true, shouldGoBefore: true)
//            }
//            return (equal: false, shouldGoBefore: !a.simulator)
//        }
//        
//        let sortConnected = {
//            (a: Device, b: Device) -> (equal: Bool, shouldGoBefore: Bool) in
//            
//            if a.connected == b.connected {
//                return (equal: true, shouldGoBefore: false)
//            }
//            return (equal: false, shouldGoBefore: a.connected)
//        }
//        
//        //then sort, devices first and if match, connected first
//        let sortedDevices = sorted(filtered, { (a, b) -> Bool in
//            
//            let (equalDevices, goBeforeDevices) = sortDevices(a, b)
//            if !equalDevices {
//                return goBeforeDevices
//            }
//            
//            let (equalConnected, goBeforeConnected) = sortConnected(a, b)
//            if !equalConnected {
//                return goBeforeConnected
//            }
//            return true
//        })
        
        return []
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
        
        self.schemesComboBox.delegate = self
        
        self.fetchDevices { () -> () in
            Log.verbose("Finished fetching devices")
        }
    }
    
    override func reloadUI() {
        
        super.reloadUI()
        
        self.triggersTableView.reloadData()
        
        //enable devices table view only if selected devices is chosen
        let filter = self.buildTemplate.deviceFilter ?? .AllAvailableDevicesAndSimulators
        let selectable = filter == .SelectedDevicesAndSimulators
        self.testDevicesTableView.enabled = selectable
        
        //also change the device filter picker based on the platform
        self.refreshDataInDeviceFilterComboBox()
    }
    
    func pullStagesFromUI() -> Bool {
        
        self.buildTemplate.shouldAnalyze = (self.analyzeButton.state == NSOnState)
        self.buildTemplate.shouldTest = (self.testButton.state == NSOnState)
        self.buildTemplate.shouldArchive = (self.archiveButton.state == NSOnState)
        
        return true
    }
    
    override func pullDataFromUI(interactive: Bool) -> Bool {
    
        if super.pullDataFromUI(interactive) {
            let scheme = self.pullSchemeFromUI(interactive)
            let name = self.pullNameFromUI()
            let stages = self.pullStagesFromUI()
            let schedule = self.pullScheduleFromUI(interactive)
            let cleaning = self.pullCleaningPolicyFromUI(interactive)
            let filter = self.pullFilterFromUI(interactive)
            
            return scheme && name && stages && schedule && cleaning && filter
        }
        return false
    }
    
    func pullCleaningPolicyFromUI(interactive: Bool) -> Bool {
        
        let index = self.cleaninPolicyComboBox.indexOfSelectedItem
        if index > -1 {
            let policy = self.allCleaningPolicies()[index]
            self.buildTemplate.cleaningPolicy = policy
            return true
        }
        if interactive {
            UIUtils.showAlertWithText("Please choose a cleaning policy")
        }
        return false
    }

    func pullScheduleFromUI(interactive: Bool) -> Bool {
        
        let index = self.scheduleComboBox.indexOfSelectedItem
        if index > -1 {
            let scheduleType = self.allSchedules()[index]
            let schedule: BotSchedule
            switch scheduleType {
            case .Commit:
                schedule = BotSchedule.commitBotSchedule()
            case .Manual:
                schedule = BotSchedule.manualBotSchedule()
            default:
                assertionFailure("Other schedules not yet supported")
                schedule = BotSchedule(json: NSDictionary())
            }
            self.buildTemplate.schedule = schedule
            return true
        }
        if interactive {
            UIUtils.showAlertWithText("Please choose a bot schedule (choose 'Manual' for Syncer-controller bots)")
        }
        return false
    }

    func pullNameFromUI() -> Bool {
        
        let name = self.nameTextField.stringValue
        if !name.isEmpty {
            self.buildTemplate.name = name
            return true
        } else {
            self.buildTemplate.name = nil
            return false
        }
    }
    
    func pullSchemeFromUI(interactive: Bool) -> Bool {
        
        //validate that the selection is valid
        if let selectedScheme = self.schemesComboBox.objectValueOfSelectedItem as? String
        {
            let schemes = self.project.schemeNames()
            if schemes.indexOf(selectedScheme) != nil {
                //found it, good, use it
                self.buildTemplate.scheme = selectedScheme
                
                //also refresh devices for testing based on the scheme type
                do {
                    let platformType = try XcodeDeviceParser.parseDeviceTypeFromProjectUrlAndScheme(self.project.url, scheme: selectedScheme).toPlatformType()
                    self.buildTemplate.platformType = platformType
                    self.reloadUI()
                    return true
                } catch {
                    print("\(error)")
                    return false
                }
            }
        }
        
        if interactive {
            UIUtils.showAlertWithText("Please select a scheme to build with")
        }
        return false
    }
    
    func pullFilterFromUI(interactive: Bool) -> Bool {
        
        let index = self.testDeviceFilterComboBox.indexOfSelectedItem
        if index > -1 {
            let filter = self.allFilters()[index]
            self.buildTemplate.deviceFilter = filter
            return true
        }
        if interactive && self.testDeviceFilterComboBox.numberOfItems > 0 {
            UIUtils.showAlertWithText("Please select a destination to build with")
        }
        return false
    }

    func comboBoxSelectionDidChange(notification: NSNotification) {
        
        if let comboBox = notification.object as? NSComboBox {
            
            if comboBox == self.testDeviceFilterComboBox {
                
                self.pullFilterFromUI(true)
                self.reloadUI()
                
                //filter changed, refetch
                self.fetchDevices({ () -> () in
                    //
                })
            } else if comboBox == self.schemesComboBox {
                
                self.pullSchemeFromUI(true)
            }
        }
    }
    
    override func willSave() {
        
        self.storageManager.saveBuildTemplate(self.buildTemplate)
        super.willSave()
    }
    
    @IBAction func addTriggerButtonTapped(sender: AnyObject) {
        self.editTrigger(nil)
    }
    
    @IBAction func deleteButtonTapped(sender: AnyObject) {
        
        UIUtils.showAlertAskingForRemoval("Are you sure you want to delete this build template?", completion: { (remove) -> () in
            if remove {
                self.storageManager.removeBuildTemplate(self.buildTemplate)
                self.buildTemplate = nil
                self.cancel()
            }
        })
    }
    
    //MARK: triggers table view
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        
        if tableView == self.triggersTableView {
            return self.buildTemplate.triggers.count
        } else if tableView == self.testDevicesTableView {
            return self.allAvailableTestingDevices.count
        }
        return 0
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        if self.buildTemplate != nil {
            if tableView == self.triggersTableView {
                let triggers = self.buildTemplate.triggers
                if tableColumn!.identifier == "names" {
                    
                    let trigger = triggers[row]
                    return trigger.name
                }
            } else if tableView == self.testDevicesTableView {
                
                let device = self.allAvailableTestingDevices[row]
                
                switch tableColumn!.identifier {
                case "name":
                    let simString = device.simulator ? "Simulator " : ""
                    let connString = device.connected ? "" : "[disconnected]"
                    let string = "\(simString)\(device.name) (\(device.osVersion)) \(connString)"
                    return string
                case "enabled":
                    break
//                    let devices = self.buildTemplate.testingDeviceIds ?? []
//                    let index = devices.indexOfFirstObjectPassingTest({ $0 == device.id })
//                    let enabled = index > -1
//                    return enabled
                default:
                    return nil
                }
            }
        }
        return nil
    }
    
    func setupViewControllerDidSave(viewController: SetupViewController) {
        
        if let triggerViewController = viewController as? TriggerViewController {
            
            if let outTrigger = triggerViewController.outTrigger {
                
                if let inTrigger = triggerViewController.inTrigger {
                    //was an existing trigger, just replace in place
                    let index = self.buildTemplate.triggers.indexOfFirstObjectPassingTest { $0.uniqueId == inTrigger.uniqueId }!
                    self.buildTemplate.triggers[index] = outTrigger
                    
                } else {
                    //new trigger, just add
                    self.buildTemplate.triggers.append(outTrigger)
                }
            }
        }
        
        self.reloadUI()
    }
    
    func setupViewControllerDidCancel(viewController: SetupViewController) {
        //
    }
    
    func editTrigger(trigger: Trigger?) {
        self.triggerToEdit = trigger
        self.performSegueWithIdentifier("showTrigger", sender: self)
    }
    
    @IBAction func triggerTableViewEditTapped(sender: AnyObject) {
        let index = self.triggersTableView.selectedRow
        let trigger = self.buildTemplate.triggers[index]
        self.editTrigger(trigger)
    }
    
    @IBAction func triggerTableViewDeleteTapped(sender: AnyObject) {
        let index = self.triggersTableView.selectedRow
        self.buildTemplate.triggers.removeAtIndex(index)
        self.reloadUI()
    }
    
    @IBAction func testDevicesTableViewRowCheckboxTapped(sender: AnyObject) {
        
        //toggle selection in model and reload data
        
        //get device at index first
//        let device = self.allAvailableTestingDevices[self.testDevicesTableView.selectedRow]
        
        //see if we are checking or unchecking
//        let foundIndex = self.buildTemplate.testingDeviceIds.indexOfFirstObjectPassingTest({ $0 == device.id })
//        
//        if let foundIndex = foundIndex {
//            //found, remove it
//            self.buildTemplate.testingDeviceIds.removeAtIndex(foundIndex)
//        } else {
//            //not found, add it
//            self.buildTemplate.testingDeviceIds.append(device.id)
//        }
//        
//        self.testDevicesTableView.reloadData()
    }
}
