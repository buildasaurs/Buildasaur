//
//  TriggerViewController.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 14/03/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Cocoa
import XcodeServerSDK
import BuildaUtils
import BuildaKit
import ReactiveCocoa

class TriggerViewController: SetupViewController, NSComboBoxDelegate {
    
    var inTrigger: TriggerConfig!
    var outTrigger: TriggerConfig?
    
    @IBOutlet weak var saveButton: NSButton!
    @IBOutlet weak var nameTextField: NSTextField!
    @IBOutlet weak var kindPopup: NSPopUpButton!
    @IBOutlet weak var phasePopup: NSPopUpButton!
    @IBOutlet weak var emailConfigStackItem: NSStackView!
    @IBOutlet weak var postbuildConfigStackItem: NSStackView!
    
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
    
    //state
    private let kinds = MutableProperty<[TriggerConfig.Kind]>(TriggerViewController.allKinds())
    private let phases = MutableProperty<[TriggerConfig.Phase]>(TriggerViewController.allPhases())
    
    private let selectedKind = MutableProperty<TriggerConfig.Kind>(.RunScript)
    private let selectedPhase = MutableProperty<TriggerConfig.Phase>(.Prebuild)
    private let isValid = MutableProperty<Bool>(false)
    private let generatedTrigger = MutableProperty<TriggerConfig?>(nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.bodyTextField.delegate = self
        self.setupKinds()
        self.setupPhases()
        self.setupGeneratedTrigger()
        
        self.postbuildConfigStackItem
            .rac_hidden <~ self.selectedPhase.producer.map { $0 != .Postbuild }
        self.emailConfigStackItem
            .rac_hidden <~ self.selectedKind.producer.map { $0 != .EmailNotification }
        self.saveButton.rac_enabled <~ self.isValid
        
        
//        if let trigger = self.inTrigger {
//            
            //            self.nameTextField.stringValue = trigger.name
            //
            //            if let idx = self.allPhases().indexOfFirstObjectPassingTest({ $0 == trigger.phase }) {
            //                self.phaseComboBox.selectItemAtIndex(idx)
            //            }
            //
            //            if let idx = self.allKinds().indexOfFirstObjectPassingTest({ $0 == trigger.kind }) {
            //                self.typeComboBox.selectItemAtIndex(idx)
            //            }
            //
            //            if trigger.kind == TriggerConfig.Kind.RunScript {
            //                self.bodyTextField.stringValue = trigger.scriptBody
            //            } else {
            //                self.bodyTextField.stringValue = trigger.emailConfiguration!.additionalRecipients.joinWithSeparator(",")
            //            }
            //
            //            if let conditions = trigger.conditions {
            //
            //                self.conditionAnalyzerWarningsCheckbox.state = conditions.onAnalyzerWarnings ? NSOnState : NSOffState
            //                self.conditionBuildErrorsCheckbox.state = conditions.onBuildErrors ? NSOnState : NSOffState
            //                self.conditionFailingTestsCheckbox.state = conditions.onFailingTests ? NSOnState : NSOffState
            //                self.conditionInternalErrorCheckbox.state = conditions.onInternalErrors ? NSOnState : NSOffState
            //                self.conditionSuccessCheckbox.state = conditions.onSuccess ? NSOnState : NSOffState
            //                self.conditionWarningsCheckbox.state = conditions.onWarnings ? NSOnState : NSOffState
            //            }
            //
            //            if let emailConfig = trigger.emailConfiguration {
            //
            //                self.emailEmailCommittersCheckbox.state = emailConfig.emailCommitters ? NSOnState : NSOffState
            //                self.emailIncludeCommitsCheckbox.state = emailConfig.includeCommitMessages ? NSOnState : NSOffState
            //                self.emailIncludeIssueDetailsCheckbox.state = emailConfig.includeIssueDetails ? NSOnState : NSOffState
            //            }
//        }
    }
    
    private func setupKinds() {
        
        //data source
        let producer = self.kinds.producer
        producer.startWithNext { [weak self] new in
            guard let sself = self else { return }
            
            let popup = sself.kindPopup
            popup.removeAllItems()
            let displayNames = new.map { "\($0.toString())" }
            popup.addItemsWithTitles(displayNames)
        }
        
        //action
        let handler = SignalProducer<AnyObject, NoError> { [weak self] sink, _ in
            if let sself = self {
                let index = sself.kindPopup.indexOfSelectedItem
                let all = sself.kinds.value
                sself.selectedKind.value = all[index]
            }
            sendCompleted(sink)
        }
        let action = Action { (_: AnyObject?) in handler }
        self.kindPopup.rac_command = toRACCommand(action)
    }
    
    private func setupPhases() {
        
        //data source
        let producer = self.phases.producer
        producer.startWithNext { [weak self] new in
            guard let sself = self else { return }
            
            let popup = sself.phasePopup
            popup.removeAllItems()
            let displayNames = new.map { "\($0.toString())" }
            popup.addItemsWithTitles(displayNames)
        }
        
        //action
        let handler = SignalProducer<AnyObject, NoError> { [weak self] sink, _ in
            if let sself = self {
                let index = sself.phasePopup.indexOfSelectedItem
                let all = sself.phases.value
                sself.selectedPhase.value = all[index]
            }
            sendCompleted(sink)
        }
        let action = Action { (_: AnyObject?) in handler }
        self.phasePopup.rac_command = toRACCommand(action)
    }
    
    private func setupGeneratedTrigger() {
        
        let name = self.nameTextField.rac_text
        let kind = self.selectedKind.producer
        let phase = self.selectedPhase.producer
        //TODO: add the rest
        
        let combined = combineLatest(name, kind, phase)
        let isValid = combined.map {
            name, kind, phase -> Bool in
            
            if name.isEmpty {
                return false
            }
            
            //TODO: validate
            
            return true
        }
        self.isValid <~ isValid
    }
    
    static func allPhases() -> [TriggerConfig.Phase] {
        return [
            TriggerConfig.Phase.Prebuild,
            TriggerConfig.Phase.Postbuild
        ]
    }
    
    static func allKinds() -> [TriggerConfig.Kind] {
        return [
            TriggerConfig.Kind.RunScript,
            TriggerConfig.Kind.EmailNotification
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
        
        //        let kindIndex = self.typeComboBox.indexOfSelectedItem
        //        if kindIndex > -1 {
        //            let triggerKind = self.allKinds()[kindIndex]
        //            let desc = (triggerKind == TriggerConfig.Kind.RunScript) ? "Script body:" : "Additional Email recipients (comma separated)"
        //            self.bodyDescriptionLabel.stringValue = desc
        //
        //            let isEmail = triggerKind == TriggerConfig.Kind.EmailNotification
        //            self.emailCheckboxes().forEach { $0.enabled = isEmail }
        //        }
        //
        //        let phaseIndex = self.phaseComboBox.indexOfSelectedItem
        //        if phaseIndex > -1 {
        //            let triggerPhase = self.allPhases()[phaseIndex]
        //            let isPostbuild = triggerPhase == TriggerConfig.Phase.Postbuild
        //            self.conditionsCheckboxes().forEach { $0.enabled = isPostbuild }
        //        }
        //
        //        super.reloadUI()
    }
    
    override func pullDataFromUI(interactive: Bool) -> Bool {
        
        //        if super.pullDataFromUI(interactive) {
        //
        //            let name = self.nameTextField.stringValue
        //            if name.isEmpty {
        //                if interactive {
        //                    UIUtils.showAlertWithText("Please provide a name")
        //                }
        //                return false
        //            }
        //
        //            let kindIndex = self.typeComboBox.indexOfSelectedItem
        //            if kindIndex == -1 {
        //                if interactive {
        //                    UIUtils.showAlertWithText("Please provide a type of your trigger")
        //                }
        //                return false
        //            }
        //
        //            let kind = self.allKinds()[kindIndex]
        //
        //            let phaseIndex = self.phaseComboBox.indexOfSelectedItem
        //            if phaseIndex == -1 {
        //                if interactive {
        //                    UIUtils.showAlertWithText("Please provide a phase of your trigger")
        //                }
        //                return false
        //            }
        //
        //            let phase = self.allPhases()[phaseIndex]
        //
        //            let bodyString = self.bodyTextField.stringValue
        //            let body: String
        //            var emailConfig: EmailConfiguration?
        //
        //            if kind == TriggerConfig.Kind.RunScript {
        //                //must have a body
        //
        //                body = bodyString
        //                if body.isEmpty {
        //                    if interactive {
        //                        UIUtils.showAlertWithText("Please provide body of your script")
        //                    }
        //                    return false
        //                }
        //
        //            } else {
        //
        //                body = ""
        //                let trimmed = bodyString.stringByReplacingOccurrencesOfString(" ", withString: "", options: NSStringCompareOptions(), range: nil)
        //                let additionalRecipients = trimmed.componentsSeparatedByString(",")
        //
        //                let emailCommitters = self.emailEmailCommittersCheckbox.state == NSOnState
        //                let includeCommitMessages = self.emailIncludeCommitsCheckbox.state == NSOnState
        //                let includeIssueDetails = self.emailIncludeIssueDetailsCheckbox.state == NSOnState
        //                emailConfig = EmailConfiguration(additionalRecipients: additionalRecipients, emailCommitters: emailCommitters, includeCommitMessages: includeCommitMessages, includeIssueDetails: includeIssueDetails)
        //            }
        //
        //            var conditions: TriggerConditions?
        //            if phase == TriggerConfig.Phase.Postbuild {
        //
        //                let onAnalyzerWarnings = self.conditionAnalyzerWarningsCheckbox.state == NSOnState
        //                let onBuildErrors = self.conditionBuildErrorsCheckbox.state == NSOnState
        //                let onFailingTests = self.conditionFailingTestsCheckbox.state == NSOnState
        //                let onInternalErrors = self.conditionInternalErrorCheckbox.state == NSOnState
        //                let onSuccess = self.conditionSuccessCheckbox.state == NSOnState
        //                let onWarnings = self.conditionWarningsCheckbox.state == NSOnState
        //
        //                conditions = TriggerConditions(onAnalyzerWarnings: onAnalyzerWarnings, onBuildErrors: onBuildErrors, onFailingTests: onFailingTests, onInternalErrors: onInternalErrors, onSuccess: onSuccess, onWarnings: onWarnings)
        //            }
        //
        //            //if we've gotten all the way here, we can create a trigger
        //            var trigger = self.inTrigger
        //            trigger.phase = phase
        //            trigger.kind = kind
        //            trigger.scriptBody = body
        //            trigger.name = name
        //            trigger.conditions = conditions
        //            trigger.emailConfiguration = emailConfig
        //            self.outTrigger = trigger
        //
        //            return true
        return false
    }
}



extension TriggerViewController: NSTextFieldDelegate {
    
    //Taken from https://developer.apple.com/library/mac/qa/qa1454/_index.html
    func control(control: NSControl, textView: NSTextView, doCommandBySelector commandSelector: Selector) -> Bool {
        
        let result: Bool
        switch commandSelector {
            
        case Selector("insertNewline:"):
            // new line action:
            // always insert a line-break character and don’t cause the receiver to end editing
            textView.insertNewlineIgnoringFieldEditor(self)
            result = true
            
        case Selector("insertTab:"):
            // tab action:
            // always insert a tab character and don’t cause the receiver to end editing
            textView.insertTabIgnoringFieldEditor(self)
            result = true
            
        default:
            result = false
        }
        
        return result
    }
}

