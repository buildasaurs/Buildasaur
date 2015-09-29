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

class DashboardViewController: NSViewController {

    @IBOutlet weak var syncersTableView: NSTableView!
    @IBOutlet weak var startAllButton: NSButton!
    @IBOutlet weak var stopAllButton: NSButton!
    
    //TODO: figure out a way to inject this instead
    let storageManager: StorageManager = StorageManager.sharedInstance
    
    private var syncerViewModels: MutableProperty<[SyncerViewModel]> = MutableProperty([])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configDataSource()
        self.configTableView()
        self.configHeaderView()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
    }
    
    func configHeaderView() {
        let syncerViewModelsProducer = self.syncerViewModels.producer
        let startAllEnabled = syncerViewModelsProducer.map { models in
            return models.filter { !$0.syncer.active }.count > 0
        }.map(fix)
        let stopAllEnabled = syncerViewModelsProducer.map { models in
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
        
        self.storageManager.syncers.producer.startWithNext { newSyncers in
            self.syncerViewModels.value = newSyncers.map { SyncerViewModel(syncer: $0) }
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
    
//    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
//        
//        let syncerViewModel = self.syncerViewModels[row]
//        guard let columnIdentifier = tableColumn?.identifier else { return nil }
//        let object = syncerViewModel.objectForColumnIdentifier(columnIdentifier)
//        return object
//    }
    
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
            let identifier = "buttonView"
            guard let view = tableView.makeViewWithIdentifier(identifier, owner: self) as? BuildaNSButton else { return nil }
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

