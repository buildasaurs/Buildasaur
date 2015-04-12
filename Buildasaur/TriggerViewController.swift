//
//  TriggerViewController.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 14/03/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import AppKit
import BuildaCIServer
import BuildaUtils

class TriggerViewController: SetupViewController, NSComboBoxDelegate {
    
    var inTrigger: Trigger?
    var outTrigger: Trigger?
    
    @IBOutlet weak var nameTextField: NSTextField!
    @IBOutlet weak var typeComboBox: NSComboBox!
    @IBOutlet weak var phaseComboBox: NSComboBox!
    @IBOutlet weak var bodyTextField: NSTextField!
    @IBOutlet weak var bodyDescriptionLabel: NSTextField!
    
    //conditions - enabled only for Postbuild
    @IBOutlet weak var conditionAnalyzerWarningsCheckbox: NSButton!
    @IBOutlet weak var conditionBuildErrorsCheckbox: NSButton!
    @IBOutlet weak var conditionFailingTestsCheckbox: NSButton!
    @IBOutlet weak var conditionInternalErrorCheckbox: NSButton!
    @IBOutlet weak var conditionSuccessCheckbox: NSButton!
    @IBOutlet weak var conditionWarningsCheckbox: NSButton!
    
    //email config - enabled only for Email
    @IBOutlet weak var emailEmailCommittersCheckbox: NSButton!
    @IBOutlet weak var emailIncludeCommitsCheckbox: NSButton!
    @IBOutlet weak var emailIncludeIssueDetailsCheckbox: NSButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.typeComboBox.removeAllItems()
        self.typeComboBox.addItemsWithObjectValues(self.allKinds().map({ $0.toString() }))
        self.typeComboBox.delegate = self
        self.phaseComboBox.removeAllItems()
        self.phaseComboBox.addItemsWithObjectValues(self.allPhases().map({ $0.toString() }))
        self.phaseComboBox.delegate = self

        if let trigger = self.inTrigger {
                        
            self.nameTextField.stringValue = trigger.name
            
            if let idx = self.allPhases().indexOfFirstObjectPassingTest({ $0 == trigger.phase }) {
                self.phaseComboBox.selectItemAtIndex(idx)
            }
            
            if let idx = self.allKinds().indexOfFirstObjectPassingTest({ $0 == trigger.kind }) {
                self.typeComboBox.selectItemAtIndex(idx)
            }
            
            if trigger.kind == Trigger.Kind.RunScript {
                self.bodyTextField.stringValue = trigger.scriptBody
            } else {
                self.bodyTextField.stringValue = ",".join(trigger.emailConfiguration!.additionalRecipients)
            }
            
            if let conditions = trigger.conditions {
                
                self.conditionAnalyzerWarningsCheckbox.state = conditions.onAnalyzerWarnings ? NSOnState : NSOffState
                self.conditionBuildErrorsCheckbox.state = conditions.onBuildErrors ? NSOnState : NSOffState
                self.conditionFailingTestsCheckbox.state = conditions.onFailingTests ? NSOnState : NSOffState
                self.conditionInternalErrorCheckbox.state = conditions.onInternalErrors ? NSOnState : NSOffState
                self.conditionSuccessCheckbox.state = conditions.onSuccess ? NSOnState : NSOffState
                self.conditionWarningsCheckbox.state = conditions.onWarnings ? NSOnState : NSOffState
            }
            
            if let emailConfig = trigger.emailConfiguration {
                
                self.emailEmailCommittersCheckbox.state = emailConfig.emailCommitters ? NSOnState : NSOffState
                self.emailIncludeCommitsCheckbox.state = emailConfig.includeCommitMessages ? NSOnState : NSOffState
                self.emailIncludeIssueDetailsCheckbox.state = emailConfig.includeIssueDetails ? NSOnState : NSOffState
            }
        }
    }
    
    func allPhases() -> [Trigger.Phase] {
        return [
            Trigger.Phase.Prebuild,
            Trigger.Phase.Postbuild
        ]
    }
    
    func allKinds() -> [Trigger.Kind] {
        return [
            Trigger.Kind.RunScript,
            Trigger.Kind.EmailNotification
        ]
    }
    
    func emailCheckboxes() -> [NSButton] {
        return [
            self.emailEmailCommittersCheckbox,
            self.emailIncludeCommitsCheckbox,
            self.emailIncludeIssueDetailsCheckbox
        ]
    }
    
    func conditionsCheckboxes() -> [NSButton] {
        return [
            self.conditionAnalyzerWarningsCheckbox,
            self.conditionBuildErrorsCheckbox,
            self.conditionFailingTestsCheckbox,
            self.conditionInternalErrorCheckbox,
            self.conditionSuccessCheckbox,
            self.conditionWarningsCheckbox
        ]
    }
    
    override func reloadUI() {
        
        let kindIndex = self.typeComboBox.indexOfSelectedItem
        if kindIndex > -1 {
            let triggerKind = self.allKinds()[kindIndex]
            let desc = (triggerKind == Trigger.Kind.RunScript) ? "Script body:" : "Additional Email recipients (comma separated)"
            self.bodyDescriptionLabel.stringValue = desc
            
            let isEmail = triggerKind == Trigger.Kind.EmailNotification
            self.emailCheckboxes().map { $0.enabled = isEmail }
        }
        
        let phaseIndex = self.phaseComboBox.indexOfSelectedItem
        if phaseIndex > -1 {
            let triggerPhase = self.allPhases()[phaseIndex]
            let isPostbuild = triggerPhase == Trigger.Phase.Postbuild
            self.conditionsCheckboxes().map { $0.enabled = isPostbuild }
        }
        
        super.reloadUI()
    }
    
    override func pullDataFromUI(interactive: Bool) -> Bool {
        
        if super.pullDataFromUI(interactive) {
            
            let name = self.nameTextField.stringValue
            if count(name) == 0 {
                if interactive {
                    UIUtils.showAlertWithText("Please provide a name")
                }
                return false
            }
            
            let kindIndex = self.typeComboBox.indexOfSelectedItem
            if kindIndex == -1 {
                if interactive {
                    UIUtils.showAlertWithText("Please provide a type of your trigger")
                }
                return false
            }
            
            let kind = self.allKinds()[kindIndex]
            
            let phaseIndex = self.phaseComboBox.indexOfSelectedItem
            if phaseIndex == -1 {
                if interactive {
                    UIUtils.showAlertWithText("Please provide a phase of your trigger")
                }
                return false
            }
            
            let phase = self.allPhases()[phaseIndex]
            
            let bodyString = self.bodyTextField.stringValue
            let body: String
            var emailConfig: EmailConfiguration?

            if kind == Trigger.Kind.RunScript {
                //must have a body
                
                body = bodyString
                if count(body) == 0 {
                    if interactive {
                        UIUtils.showAlertWithText("Please provide body of your script")
                    }
                    return false
                }
                
            } else {
                
                body = ""
                let trimmed = bodyString.stringByReplacingOccurrencesOfString(" ", withString: "", options: NSStringCompareOptions.allZeros, range: nil)
                let additionalRecipients = trimmed.componentsSeparatedByString(",")
                
                let emailCommitters = self.emailEmailCommittersCheckbox.state == NSOnState
                let includeCommitMessages = self.emailIncludeCommitsCheckbox.state == NSOnState
                let includeIssueDetails = self.emailIncludeIssueDetailsCheckbox.state == NSOnState
                emailConfig = EmailConfiguration(additionalRecipients: additionalRecipients, emailCommitters: emailCommitters, includeCommitMessages: includeCommitMessages, includeIssueDetails: includeIssueDetails)
            }
            
            var conditions: TriggerConditions?
            if phase == Trigger.Phase.Postbuild {
                
                let onAnalyzerWarnings = self.conditionAnalyzerWarningsCheckbox.state == NSOnState
                let onBuildErrors = self.conditionBuildErrorsCheckbox.state == NSOnState
                let onFailingTests = self.conditionFailingTestsCheckbox.state == NSOnState
                let onInternalErrors = self.conditionInternalErrorCheckbox.state == NSOnState
                let onSuccess = self.conditionSuccessCheckbox.state == NSOnState
                let onWarnings = self.conditionWarningsCheckbox.state == NSOnState
                
                conditions = TriggerConditions(onAnalyzerWarnings: onAnalyzerWarnings, onBuildErrors: onBuildErrors, onFailingTests: onFailingTests, onInternalErrors: onInternalErrors, onSuccess: onSuccess, onWarnings: onWarnings)
            }
            
            //if we've gotten all the way here, we can create a trigger
            self.outTrigger = Trigger(phase: phase, kind: kind, scriptBody: body, name: name, conditions: conditions, emailConfiguration: emailConfig)
            return true
        }
        return false
    }
    
    func comboBoxWillDismiss(notification: NSNotification) {
        self.reloadUI()
    }
    
}

