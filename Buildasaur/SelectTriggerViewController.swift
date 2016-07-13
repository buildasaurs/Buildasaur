//
//  SelectTriggerViewController.swift
//  Buildasaur
//
//  Created by Anton Domashnev on 23/06/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation
import AppKit
import XcodeServerSDK
import ReactiveCocoa
import BuildaKit


protocol SelectTriggerViewControllerDelegate: class {
    func selectTriggerViewController(viewController: SelectTriggerViewController, didSelectTriggers selectedTriggers: [TriggerConfig])
}

class SelectTriggerViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    weak var delegate: SelectTriggerViewControllerDelegate?
    
    @IBOutlet weak var triggersListContainerViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var triggersListContainerView: NSView!
    @IBOutlet weak var triggersTableView: NSTableView!
    @IBOutlet weak var doneButton: NSButton!
    @IBOutlet weak var cancelButton: NSButton!
    
    var storageManager: StorageManager!
    
    private let triggers = MutableProperty<[TriggerConfig]>([])
    private let selectedTriggerIDs = MutableProperty<[String]>([])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupBindings()
        self.fetchTriggers()
        self.selectedTriggerIDs.value = []
        
    }
    
    private func setupBindings() {
        self.triggers.producer.startWithNext { [weak self] _ in
            self?.triggersTableView.reloadData()
        }
        self.selectedTriggerIDs.producer.startWithNext { [weak self] _ in
            self?.doneButton.enabled = self?.selectedTriggerIDs.value.count > 0
        }
    }
    
    //MARK: triggers table view
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return self.triggers.value.count
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        let triggers = self.triggers.value
        let trigger = triggers[row]
        switch tableColumn!.identifier {
        case "name":
            return trigger.name
        case "selected":
            let index = self.selectedTriggerIDs.value
                .indexOfFirstObjectPassingTest { $0 == trigger.id }
            let enabled = index > -1
            return enabled
        default:
            return nil
        }
    }
    
    func tableView(tableView: NSTableView, shouldSelectTableColumn tableColumn: NSTableColumn?) -> Bool {
        return false
    }
    
    @IBAction func triggersTableViewRowCheckboxTapped(sender: AnyObject) {
        let trigger = self.triggers.value[self.triggersTableView.selectedRow]
        let foundIndex = self.selectedTriggerIDs.value.indexOfFirstObjectPassingTest({ $0 == trigger.id })
        
        if let foundIndex = foundIndex {
            self.selectedTriggerIDs.value.removeAtIndex(foundIndex)
        } else {
            self.selectedTriggerIDs.value.append(trigger.id)
        }
    }
    
    @IBAction func triggerTableViewEditTapped(sender: AnyObject) {
        let index = self.triggersTableView.selectedRow
        let trigger = self.triggers.value[index]
        self.editTrigger(trigger)
    }
    
    @IBAction func triggerTableViewDeleteTapped(sender: AnyObject) {
        let index = self.triggersTableView.selectedRow
        let trigger = self.triggers.value[index]
        self.storageManager.removeTriggerConfig(trigger)
        self.triggers.value.removeAtIndex(index)
    }
 
    //MARK: helpers
    
    func editTrigger(trigger: TriggerConfig?) {
        let triggerViewController = NSStoryboard.mainStoryboard.instantiateControllerWithIdentifier(TriggerViewController.storyboardID) as! TriggerViewController
        triggerViewController.triggerConfig.value = trigger
        triggerViewController.storageManager = self.storageManager
        triggerViewController.delegate = self
        self.pushTriggerViewController(triggerViewController)
    }
    
    func fetchTriggers() {
        self.triggers.value = self.storageManager.triggerConfigs.value.map { $0.1 }
    }
    
    func pushTriggerViewController(viewController: TriggerViewController) {
        self.addChildViewController(viewController)
        self.view.addSubview(viewController.view)
        
        let pushingView = viewController.view
        let mainLeadingConstraint = self.triggersListContainerViewLeadingConstraint
        let endPushingViewFrame = pushingView.frame
        pushingView.frame = CGRectOffset(pushingView.frame, CGRectGetWidth(pushingView.frame), 0)
        
        NSAnimationContext.runAnimationGroup({ (context: NSAnimationContext) -> Void in
            
            context.duration = 0.3
            pushingView.animator().frame = endPushingViewFrame
            mainLeadingConstraint.animator().constant = -CGRectGetWidth(pushingView.frame)
            
        }) { /* do nothing */ }
    }
    
    func popTriggerViewController(viewController: TriggerViewController) {
        let poppingView = viewController.view
        let mainLeadingConstraint = self.triggersListContainerViewLeadingConstraint
        let endPoppingViewFrame = CGRectOffset(poppingView.frame, CGRectGetWidth(poppingView.frame), 0)
        
        NSAnimationContext.runAnimationGroup({ (context: NSAnimationContext) -> Void in
            
            context.duration = 0.3
            poppingView.animator().frame = endPoppingViewFrame
            mainLeadingConstraint.animator().constant = 0
            
        }) {
            
            poppingView.removeFromSuperview()
            viewController.removeFromParentViewController()
        }
    }
    
    //MARK: actions
    
    @IBAction func doneButtonClicked(sender: NSButton) {
        
        let dictionarifyAvailableTriggers: [String: TriggerConfig] = self.triggers.value.dictionarifyWithKey {$0.id}
        let selectedTriggers: [TriggerConfig] = self.selectedTriggerIDs.value.map { dictionarifyAvailableTriggers[$0]! }
        self.delegate?.selectTriggerViewController(self, didSelectTriggers: selectedTriggers)
        self.dismissController(nil)
    }
    
    @IBAction func cancelButtonClicked(sender: NSButton) {
        
        self.dismissController(nil)
    }
    
}

extension SelectTriggerViewController: TriggerViewControllerDelegate {
    
    func triggerViewController(triggerViewController: NSViewController, didCancelEditingTrigger trigger: TriggerConfig) {
        self.popTriggerViewController(triggerViewController as! TriggerViewController)
    }
    
    func triggerViewController(triggerViewController: NSViewController, didSaveTrigger trigger: TriggerConfig) {
        var mapped = self.triggers.value.dictionarifyWithKey { $0.id }
        mapped[trigger.id] = trigger
        self.triggers.value = Array(mapped.values)
        self.popTriggerViewController(triggerViewController as! TriggerViewController)
    }

}
