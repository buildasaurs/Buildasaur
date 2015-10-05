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

protocol EditeeDelegate: class, EmptyXcodeServerViewControllerDelegate, XcodeServerViewControllerDelegate, EmptyProjectViewControllerDelegate, ProjectViewControllerDelegate { }

class DashboardViewController: PresentableViewController {

    @IBOutlet weak var syncersTableView: NSTableView!
    @IBOutlet weak var startAllButton: NSButton!
    @IBOutlet weak var stopAllButton: NSButton!
    
    //injected before viewDidLoad
    var syncerManager: SyncerManager!
    
    private var syncerViewModels: MutableProperty<[SyncerViewModel]> = MutableProperty([])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configTitle()
        self.configDataSource()
        self.configTableView()
        self.configHeaderView()
    }
    
    func configTitle() {
        let version = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String
        self.title = "Buildasaur \(version), at your service!"
    }
    
    func configHeaderView() {
        
        //TODO: once the crashing of Xcode editor is fixed and we can use all of 
        //RAC, bring back the signals that update the Start/Stop All buttons
    }
    
    func configTableView() {
        
        let tableView = self.syncersTableView
        tableView.setDataSource(self)
        tableView.setDelegate(self)
        tableView.columnAutoresizingStyle = .UniformColumnAutoresizingStyle
    }
    
    func configDataSource() {
        
        let present: SyncerViewModel.PresentEditViewControllerType = {
            self.showSyncerEditViewControllerWithTriplet($0.toEditable())
        }
        self.syncerManager.syncersProducer.startWithNext { newSyncers in
            self.syncerViewModels.value = newSyncers.map {
                SyncerViewModel(syncer: $0, presentEditViewController: present)
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
        self.showNewSyncerViewController()
    }
    
    @IBAction func editButtonClicked(sender: BuildaNSButton) {
        self.syncerViewModelFromSender(sender).editButtonClicked()
    }
    
    @IBAction func controlButtonClicked(sender: BuildaNSButton) {
        self.syncerViewModelFromSender(sender).controlButtonClicked()
    }
}

extension DashboardViewController {
    
    func showNewSyncerViewController() {
        
        //configure an editing window with a brand new syncer
        let triplet = self.syncerManager.factory.newEditableTriplet()
        self.showSyncerEditViewControllerWithTriplet(triplet)
    }
    
    func showSyncerEditViewControllerWithTriplet(triplet: EditableConfigTriplet) {
        
        let uniqueIdentifier = triplet.syncer.id
        let viewController: MainEditorViewController = self.storyboardLoader.presentableViewControllerWithStoryboardIdentifier("editorViewController", uniqueIdentifier: uniqueIdentifier, delegate: self.presentingDelegate)
        
        var context = EditorContext()
        context.configTriplet = triplet
        context.syncerManager = self.syncerManager
        viewController.factory = EditorViewControllerFactory(storyboardLoader: self.storyboardLoader)
        context.editeeDelegate = viewController
        viewController.context = context

        self.presentingDelegate?.presentViewControllerInUniqueWindow(viewController)
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
    
    func getTypeOfReusableView<T: NSView>(column: Column) -> T {
        guard let view = self.syncersTableView.makeViewWithIdentifier(column.rawValue, owner: self) else {
            fatalError("Couldn't get a reusable view for column \(column)")
        }
        guard let typedView = view as? T else {
            fatalError("Couldn't type view \(view) into type \(T.className())")
        }
        return typedView
    }
    
    func bindTextView(view: NSTableCellView, column: Column, viewModel: SyncerViewModel) {
        
        let destination = view.textField!.rac_stringValue
        switch column {
        case .Status:
            destination <~ viewModel.status
        case .XCSHost:
            destination <~ viewModel.host
        case .ProjectName:
            destination <~ viewModel.projectName
        case .BuildTemplate:
            destination <~ viewModel.buildTemplateName
        default: break
        }
    }
    
    func bindButtonView(view: BuildaNSButton, column: Column, viewModel: SyncerViewModel) {
        
        let destinationTitle = view.rac_title
        let destinationEnabled = view.rac_enabled
        switch column {
        case .Edit:
            destinationTitle <~ viewModel.editButtonTitle
            destinationEnabled <~ viewModel.editButtonEnabled
        case .Control:
            destinationTitle <~ viewModel.controlButtonTitle
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
            let view: NSTableCellView = self.getTypeOfReusableView(column)
            self.bindTextView(view, column: column, viewModel: syncerViewModel)
            return view
            
        case .Control, .Edit:
            //push button
            let view: BuildaNSButton = self.getTypeOfReusableView(column)
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

