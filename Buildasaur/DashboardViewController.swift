//
//  DashboardViewController.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 28/09/2015.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Cocoa
import BuildaKit
import ReactiveCocoa

//we have to cast swift objects back to AnyObject to be accepted by DynamicProperty. sigh.
func fix<T>(item: T) -> AnyObject? {
    return item as? AnyObject
}

class DashboardViewController: PresentableViewController {

    @IBOutlet weak var syncersTableView: NSTableView!
    @IBOutlet weak var startAllButton: NSButton!
    @IBOutlet weak var stopAllButton: NSButton!
    
    //injected before viewDidLoad
    var storageManager: StorageManager!
    
    private var syncerViewModels: MutableProperty<[SyncerViewModel]> = MutableProperty([])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configTitle()
        self.configDataSource()
        self.configTableView()
        self.configHeaderView()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
    }
    
    func configTitle() {
        let version = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String
        self.title = "Buildasaur \(version), at your service"
    }
    
    func configHeaderView() {
        
        let syncerViewModelsProducer = self.syncerViewModels.producer
        
        let activeProducers = syncerViewModelsProducer.map { syncerViewModels in
            return syncerViewModels.map { $0.syncer.activeSignalProducer.producer }
            }
        let flatProducers = activeProducers.map { (producers: [SignalProducer<Bool, NoError>]) in
            return SignalProducer<SignalProducer<Bool, NoError>, NoError> {
                sink, _ in
                producers.forEach { sendNext(sink, $0) }
                sendCompleted(sink)
            }
        }.flatten(.Merge)
        let flatterProducers = flatProducers.flatten(.Merge).map { _ in () }
        let initial = SignalProducer<Void, NoError>(value: ())
        
        let merged = SignalProducer<SignalProducer<Void, NoError>, NoError> {
            sink, _ in
            sendNext(sink, flatterProducers)
            sendNext(sink, initial)
            sendCompleted(sink)
        }.flatten(.Merge).on(next: {
            print("")
        })
        
        //NOT CLEAR why we don't get the initial call so that the state would be correct from the beginnign
        let syncerViewModelsOnAnyActiveChange = syncerViewModelsProducer.sampleOn(merged).on(next: { _ in
            print("")
        })
        
        let startAllEnabled = syncerViewModelsOnAnyActiveChange.map { models in
            return models.filter { !$0.syncer.active }.count > 0
        }.map(fix)
        let stopAllEnabled = syncerViewModelsOnAnyActiveChange.map { models in
            return models.filter { $0.syncer.active }.count > 0
        }.map(fix)
        
        DynamicProperty(object: self.startAllButton, keyPath: "enabled") <~ startAllEnabled
        DynamicProperty(object: self.stopAllButton, keyPath: "enabled") <~ stopAllEnabled
    }
    
    func configTableView() {
        
        let tableView = self.syncersTableView
        tableView.setDataSource(self)
        tableView.setDelegate(self)
        tableView.columnAutoresizingStyle = .UniformColumnAutoresizingStyle
    }
    
    func configDataSource() {
        
        let present: SyncerViewModel.PresentViewControllerType = {
            self.presentingDelegate?.presentViewControllerInUniqueWindow($0)
        }
        let create: SyncerViewModel.CreateViewControllerType = {
            self.storyboardLoader.presentableViewControllerWithStoryboardIdentifier($0, uniqueIdentifier: $1)
        }
        self.storageManager.syncers.producer.startWithNext { newSyncers in
            self.syncerViewModels.value = newSyncers.map {
                SyncerViewModel(syncer: $0, presentViewController: present, createViewController: create)
            }
            self.syncersTableView.reloadData()
        }
    }
    
    //MARK: Responding to button inside of cells
    
    private func syncerViewModelFromSender(sender: BuildaNSButton) -> SyncerViewModel {
        let selectedRow = sender.row!
        let syncerViewModel = self.syncerViewModels.value[selectedRow]
        return syncerViewModel
    }
    
    @IBAction func startAllButtonClicked(sender: AnyObject) {
        self.syncerViewModels.value.forEach { $0.startButtonClicked() }
    }
    
    @IBAction func stopAllButtonClicked(sender: AnyObject) {
        self.syncerViewModels.value.forEach { $0.stopButtonClicked() }
    }
    
    @IBAction func newSyncerButtonClicked(sender: AnyObject) {
        //TODO: configure an editing window with a brand new syncer
    }
    
    @IBAction func editButtonClicked(sender: BuildaNSButton) {
        self.syncerViewModelFromSender(sender).editButtonClicked()
    }
    
    @IBAction func controlButtonClicked(sender: BuildaNSButton) {
        self.syncerViewModelFromSender(sender).controlButtonClicked()
    }
}

extension DashboardViewController: NSTableViewDataSource {
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return self.syncerViewModels.value.count
    }
    
    enum Column: String {
        case Status = "status"
        case XCSHost = "xcs_host"
        case ProjectName = "project_name"
        case BuildTemplate = "build_template"
        case Control = "control"
        case Edit = "edit"
    }
    
    func bindTextView(view: NSTableCellView, column: Column, viewModel: SyncerViewModel) {
        
        let destination = DynamicProperty(object: view.textField!, keyPath: "stringValue")
        switch column {
        case .Status:
            destination <~ viewModel.status.map(fix)
        case .XCSHost:
            destination <~ viewModel.host.map(fix)
        case .ProjectName:
            destination <~ viewModel.projectName.map(fix)
        case .BuildTemplate:
            destination <~ viewModel.buildTemplateName.map(fix)
        default: break
        }
    }
    
    func bindButtonView(view: BuildaNSButton, column: Column, viewModel: SyncerViewModel) {
        
        let destination = DynamicProperty(object: view, keyPath: "title")
        let destinationEnabled = DynamicProperty(object: view, keyPath: "enabled")
        switch column {
        case .Edit:
            destination <~ viewModel.editButtonTitle.map(fix)
            destinationEnabled <~ viewModel.editButtonEnabled.map(fix)
        case .Control:
            destination <~ viewModel.controlButtonTitle.map(fix)
        default: break
        }
    }
    
    func getButtonView(tableView: NSTableView, column: Column) -> BuildaNSButton {
        
        let identifier: String
        switch column {
        case .Control:
            identifier = "controlButtonView"
        case .Edit:
            identifier = "editButtonView"
        default: fatalError("Unrecognized column")
        }
        
        guard let view = tableView.makeViewWithIdentifier(identifier, owner: self) as? BuildaNSButton else {
            fatalError("Couldn't get a button")
        }
        return view
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        guard let columnIdentifier = tableColumn?.identifier else { return nil }
        guard let column = Column(rawValue: columnIdentifier) else { return nil }
        let syncerViewModel = self.syncerViewModels.value[row]

        //based on the column decide which reuse identifier we'll use
        switch column {
        case .Status, .XCSHost, .ProjectName, .BuildTemplate:
            //basic text view
            let identifier = "textView"
            guard let view = tableView.makeViewWithIdentifier(identifier, owner: self) as? NSTableCellView else { return nil }
            self.bindTextView(view, column: column, viewModel: syncerViewModel)
            return view
            
        case .Control, .Edit:
            //push button
            let view = self.getButtonView(tableView, column: column)
            self.bindButtonView(view, column: column, viewModel: syncerViewModel)
            view.row = row
            return view
        }
    }
}

class BuildaNSButton: NSButton {
    var row: Int?
}

extension DashboardViewController: NSTableViewDelegate {
    
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 30
    }
}

