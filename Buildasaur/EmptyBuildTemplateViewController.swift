//
//  EmptyBuildTemplateViewController.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/6/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Cocoa
import BuildaKit
import BuildaUtils
import XcodeServerSDK
import ReactiveCocoa
import Result

protocol EmptyBuildTemplateViewControllerDelegate: class {
    func didSelectBuildTemplate(buildTemplate: BuildTemplate)
}

class EmptyBuildTemplateViewController: EditableViewController {

    //for cases when we're editing an existing syncer - show the
    //right preference.
    var existingTemplateId: RefType?
    
    //for requesting just the right build templates
    var projectName: String!

    weak var emptyTemplateDelegate: EmptyBuildTemplateViewControllerDelegate?
    
    @IBOutlet weak var existingBuildTemplatesPopup: NSPopUpButton!
    
    private var buildTemplates: [BuildTemplate] = []
    private var selectedTemplate = MutableProperty<BuildTemplate?>(nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        precondition(self.projectName != nil)
        
        self.setupDataSource()
        self.setupPopupAction()
        self.setupEditableStates()
        
        //select if existing template is being edited
        //TODO: also the actual index in the popup must be selected!
        let index: Int
        if let configId = self.existingTemplateId {
            let ids = self.buildTemplates.map { $0.id }
            index = ids.indexOf(configId) ?? 0
        } else {
            index = 0
        }
        self.selectItemAtIndex(index)
        self.existingBuildTemplatesPopup.selectItemAtIndex(index)
    }

    func addNewString() -> String {
        return "Add new build template..."
    }
    
    func newTemplate() -> BuildTemplate {
        return BuildTemplate() //TODO: pass the project name!
    }
    
    override func shouldGoNext() -> Bool {
        self.didSelectBuildTemplate(self.selectedTemplate.value!)
        return super.shouldGoNext()
    }
    
    private func setupEditableStates() {
        
        self.nextAllowed <~ self.selectedTemplate.producer.map { $0 != nil }
    }
    
    private func selectItemAtIndex(index: Int) {
        
        let templates = self.buildTemplates
        
        //                                      last item is "add new"
        let template = (index == templates.count) ? self.newTemplate() : templates[index]
        self.selectedTemplate.value = template
    }
    
    private func setupPopupAction() {
        
        let handler = SignalProducer<AnyObject, NoError> { [weak self] sink, _ in
            if let sself = self {
                let index = sself.existingBuildTemplatesPopup.indexOfSelectedItem
                sself.selectItemAtIndex(index)
            }
            sink.sendCompleted()
        }
        let action = Action { (_: AnyObject?) in handler }
        self.existingBuildTemplatesPopup.rac_command = toRACCommand(action)
    }
    
    private func setupDataSource() {
        
        let templatesProducer = self.storageManager
            .buildTemplatesForProjectName(self.projectName)
        let allTemplatesProducer = templatesProducer
            .map { templates in templates.sort { $0.name < $1.name } }
        allTemplatesProducer.startWithNext { [weak self] newTemplates in
            guard let sself = self else { return }
            
            sself.buildTemplates = newTemplates
            let popup = sself.existingBuildTemplatesPopup
            popup.removeAllItems()
            let unnamed = "Untitled template"
            var configDisplayNames = newTemplates.map { template -> String in
                let project = template.projectName ?? ""
                return "\(template.name ?? unnamed) (\(project))"
            }
            configDisplayNames.append(self?.addNewString() ?? ":(")
            popup.addItemsWithTitles(configDisplayNames)
        }
    }
    
    private func didSelectBuildTemplate(template: BuildTemplate) {
        Log.verbose("Selected \(template.name)")
        self.emptyTemplateDelegate?.didSelectBuildTemplate(template)
    }
}
