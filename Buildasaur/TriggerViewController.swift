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
import Result

protocol TriggerViewControllerDelegate: class {
    func triggerViewControllerDidCancelEditingTrigger(trigger: TriggerConfig)
    func triggerViewControllerDidSaveTrigger(trigger: TriggerConfig)
}

class TriggerViewController: NSViewController {
    
    let triggerConfig = MutableProperty<TriggerConfig!>(nil)
    var storageManager: StorageManager!
    
    weak var delegate: TriggerViewControllerDelegate?
    
    @IBOutlet weak var saveButton: NSButton!
    @IBOutlet weak var nameTextField: NSTextField!
    @IBOutlet weak var kindPopup: NSPopUpButton!
    @IBOutlet weak var phasePopup: NSPopUpButton!
    @IBOutlet weak var emailConfigStackItem: NSStackView!
    @IBOutlet weak var postbuildConfigStackItem: NSStackView!
    
    @IBOutlet weak var bodyTextField: NSTextField!
    @IBOutlet weak var bodyDescriptionLabel: NSTextField!
    
    //conditions - enabled only for Postbuild
    @IBOutlet weak var conditionSuccessCheckbox: NSButton!
    @IBOutlet weak var conditionWarningsCheckbox: NSButton!
    @IBOutlet weak var conditionAnalyzerWarningsCheckbox: NSButton!
    @IBOutlet weak var conditionFailingTestsCheckbox: NSButton!
    @IBOutlet weak var conditionBuildErrorsCheckbox: NSButton!
    @IBOutlet weak var conditionInternalErrorCheckbox: NSButton!
    
    //email config - enabled only for Email
    @IBOutlet weak var emailEmailCommittersCheckbox: NSButton!
    @IBOutlet weak var emailIncludeCommitsCheckbox: NSButton!
    @IBOutlet weak var emailIncludeIssueDetailsCheckbox: NSButton!
    
    //state
    private let phases = MutableProperty<[TriggerConfig.Phase]>(TriggerViewController.allPhases())
    private let kinds = MutableProperty<[TriggerConfig.Kind]>([])
    
    private let selectedKind = MutableProperty<TriggerConfig.Kind>(.RunScript)
    private let selectedPhase = MutableProperty<TriggerConfig.Phase>(.Prebuild)
    private let emailConfiguration = MutableProperty<EmailConfiguration?>(nil)
    private let conditions = MutableProperty<TriggerConditions?>(nil)
    private let isValid = MutableProperty<Bool>(false)
    private let generatedTrigger = MutableProperty<TriggerConfig?>(nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.bodyTextField.delegate = self
        self.setupKinds()
        self.setupPhases()
        self.setupLabels()
        self.setupConditions()
        self.setupEmailConfiguration()

        //initial dump
        
        self.triggerConfig.producer.startWithNext { [weak self] config in
            guard let sself = self else { return }
            
            sself.nameTextField.stringValue = config.name
            
            sself.selectedPhase.value = config.phase
            let phaseIndex = sself.phases.value.indexOf(config.phase) ?? 0
            sself.phasePopup.selectItemAtIndex(phaseIndex)
            
            sself.selectedKind.value = config.kind
            let kindIndex = sself.kinds.value.indexOf(config.kind) ?? 0
            sself.kindPopup.selectItemAtIndex(kindIndex)
            
            //kinds?
            if config.kind == .EmailNotification {
                let emailConfig = config.emailConfiguration!
                
                let body = emailConfig.additionalRecipients.joinWithSeparator(", ")
                sself.bodyTextField.stringValue = body
                sself.emailEmailCommittersCheckbox.on = emailConfig.emailCommitters
                sself.emailIncludeCommitsCheckbox.on = emailConfig.includeCommitMessages
                sself.emailIncludeIssueDetailsCheckbox.on = emailConfig.includeIssueDetails
            } else {
                sself.bodyTextField.stringValue = config.scriptBody
            }
            
            //phases?
            if config.phase == .Postbuild {
                
                let con = config.conditions!
                sself.conditionAnalyzerWarningsCheckbox.on = con.onAnalyzerWarnings
                sself.conditionBuildErrorsCheckbox.on = con.onBuildErrors
                sself.conditionFailingTestsCheckbox.on = con.onFailingTests
                sself.conditionInternalErrorCheckbox.on = con.onInternalErrors
                sself.conditionSuccessCheckbox.on = con.onSuccess
                sself.conditionWarningsCheckbox.on = con.onWarnings
            }
        }

        //again, needs to be setup AFTER the initial dump
        self.setupGeneratedTrigger()

        self.postbuildConfigStackItem
            .rac_hidden <~ self.selectedPhase.producer.map { $0 != .Postbuild }
        self.emailConfigStackItem
            .rac_hidden <~ self.selectedKind.producer.map { $0 != .EmailNotification }
        self.saveButton.rac_enabled <~ self.isValid
    }
    
    //MARK: RAC setup
    
    private func setupKinds() {
        
        //bind the available kinds for a selected phase
        let availableKinds = self.selectedPhase.producer.map { TriggerViewController.allKinds($0) }
        self.kinds <~ availableKinds
        
        //validate that the selected kind is still available
        combineLatest(availableKinds, self.selectedKind.producer).startWithNext {
            [weak self] availableKinds, selectedKind in
            if availableKinds.indexOf(selectedKind) == nil {
                //unfortunately SignalProducer doesn't like itself
                //changing its property value from its own call stack :/
                //deadlocks. so we gotta skip one runloop. :'-(
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    self?.selectedKind.value = availableKinds.first!
                    self?.kindPopup.selectItemAtIndex(0)
                })
            }
        }
        
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
            sink.sendCompleted()
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
            sink.sendCompleted()
        }
        let action = Action { (_: AnyObject?) in handler }
        self.phasePopup.rac_command = toRACCommand(action)
    }
    
    private func setupConditions() {
        
        let success = self.conditionSuccessCheckbox.rac_on
        let warnings = self.conditionWarningsCheckbox.rac_on
        let analyzerWarnings = self.conditionAnalyzerWarningsCheckbox.rac_on
        let testFailures = self.conditionFailingTestsCheckbox.rac_on
        let buildErrors = self.conditionBuildErrorsCheckbox.rac_on
        let internalErrors = self.conditionInternalErrorCheckbox.rac_on
        
        let conditions = combineLatest(
            success,
            warnings,
            analyzerWarnings,
            testFailures,
            buildErrors,
            internalErrors
        )
        
        let shouldCreateConditions = self.selectedPhase.producer.map { $0 == .Postbuild }
        let generated = conditions.map {
            success, warnings, analyzerWarnings, testFailures, buildErrors, internalErrors -> TriggerConditions in
            
            return TriggerConditions(onAnalyzerWarnings: analyzerWarnings, onBuildErrors: buildErrors, onFailingTests: testFailures, onInternalErrors: internalErrors, onSuccess: success, onWarnings: warnings)
        }
        let conditionsOrNil = combineLatest(generated, shouldCreateConditions).map {
            conditions, shouldCreate -> TriggerConditions? in
            shouldCreate ? conditions : nil
        }
        self.conditions <~ conditionsOrNil
    }
    
    private func setupEmailConfiguration() {
        
        let includeCommitters = self.emailEmailCommittersCheckbox.rac_on
        let includeCommits = self.emailIncludeCommitsCheckbox.rac_on
        let includeIssues = self.emailIncludeIssueDetailsCheckbox.rac_on
        let additionalEmails = self.bodyTextField.rac_text.map {
            additionalEmailsString -> [String] in
            
            //get rid of whitespace
            let splittable = additionalEmailsString
                .componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                .filter { !$0.isEmpty }
                .joinWithSeparator("")
            let all = splittable.componentsSeparatedByString(",")
            return all.filter { !$0.isEmpty }
        }
        
        let config = combineLatest(
            includeCommitters,
            includeCommits,
            includeIssues,
            additionalEmails
        )
        
        let generated = config.map {
            includeCommitters, includeCommits, includeIssues, additionalEmails -> EmailConfiguration in
            
            return EmailConfiguration(additionalRecipients: additionalEmails, emailCommitters: includeCommitters, includeCommitMessages: includeCommits, includeIssueDetails: includeIssues)
        }
        let shouldCreateConfig = self.selectedKind.producer.map { $0 == .EmailNotification }
        let configOrNil = combineLatest(generated, shouldCreateConfig)
            .map { config, shouldCreate -> EmailConfiguration? in shouldCreate ? config : nil }
        self.emailConfiguration <~ configOrNil
    }
    
    private func setupGeneratedTrigger() {
        
        let name = self.nameTextField.rac_text.skipRepeats()
        let kind = self.selectedKind.producer
        let phase = self.selectedPhase.producer
        let body = self.bodyTextField.rac_text
        let conditions = self.conditions.producer
        let emailConfiguration = self.emailConfiguration.producer
        let original = self.triggerConfig.producer
        
        let combined = combineLatest(original, name, kind, phase, body, conditions, emailConfiguration)
        let isValid = combined.map {
            _, name, kind, phase, body, conditions, emailConfig -> Bool in
            
            if name.isEmpty {
                return false
            }
            
            //if the type is script, the script body cannot be empty
            if kind == .RunScript && body.isEmpty {
                return false
            }
            
            return true
        }
        self.isValid <~ isValid
        
        let generated = combined.map {
            original, name, kind, phase, body, conditions, emailConfig -> TriggerConfig in
            
            var newTrigger = original
            newTrigger.phase = phase
            newTrigger.kind = kind
            let scriptBody = (kind == .RunScript) ? body : ""
            newTrigger.scriptBody = scriptBody
            newTrigger.name = name
            newTrigger.conditions = conditions
            newTrigger.emailConfiguration = emailConfig
            return newTrigger
        }
        self.generatedTrigger <~ generated.map { Optional($0) }
    }
    
    private func setupLabels() {
        
        let bodyLabel = self.selectedKind.producer.map { kind -> String in
            if kind == .RunScript {
                return "Script Body"
            } else {
                return "Additional Email Recipients (Comma separated)"
            }
        }
        self.bodyTextField.rac_placeholderString <~ bodyLabel.map { Optional($0) }
        self.bodyDescriptionLabel.rac_stringValue <~ bodyLabel
    }
    
    //MARK: actions
    
    @IBAction func saveButtonClicked(sender: NSButton) {
        
        let currentTrigger = self.generatedTrigger.value!
        
        //save current trigger
        self.storageManager.addTriggerConfig(currentTrigger)
        
        //notify delegate
        self.delegate?.triggerViewControllerDidSaveTrigger(currentTrigger)
        
        //dismiss
        self.dismissController(nil)
    }
    
    @IBAction func cancelButtonClicked(sender: NSButton) {
        
        //in case of cancel we could never have had a valid trigger, so just
        //use the original trigger in that case. we only care about the id anyway.
        let currentTrigger = self.generatedTrigger.value ?? self.triggerConfig.value!
        self.delegate?.triggerViewControllerDidCancelEditingTrigger(currentTrigger)
        self.dismissController(nil)
    }
    
    //MARK: consts
    
    static func allPhases() -> [TriggerConfig.Phase] {
        return [
            TriggerConfig.Phase.Prebuild,
            TriggerConfig.Phase.Postbuild
        ]
    }
    
    static func allKinds(phase: TriggerConfig.Phase) -> [TriggerConfig.Kind] {
        
        var kinds = [TriggerConfig.Kind.RunScript]
        if phase == .Postbuild {
            kinds.append(TriggerConfig.Kind.EmailNotification)
        }
        return kinds
    }
}

extension TriggerViewController: NSTextFieldDelegate {
    
    //Taken from https://developer.apple.com/library/mac/qa/qa1454/_index.html
    func control(control: NSControl, textView: NSTextView, doCommandBySelector commandSelector: Selector) -> Bool {
        
        let result: Bool
        switch commandSelector {
            
        case #selector(insertNewline(_:)):
            // new line action:
            // always insert a line-break character and don’t cause the receiver to end editing
            textView.insertNewlineIgnoringFieldEditor(self)
            result = true
            
        case #selector(insertTab(_:)):
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

