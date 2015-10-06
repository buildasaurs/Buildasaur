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

protocol EmptyBuildTemplateViewControllerDelegate: class {
    func didSelectBuildTemplate(buildTemplate: BuildTemplate)
}

class EmptyBuildTemplateViewController: EditableViewController {

    //for cases when we're editing an existing syncer - show the
    //right preference.
    var existingTemplateId: RefType?

    weak var emptyTemplateDelegate: EmptyBuildTemplateViewControllerDelegate?
    
    @IBOutlet weak var existingBuildTemplatesPopup: NSPopUpButton!
    
    private var buildTemplates: [BuildTemplate] = []
    private var selectedTemplate = MutableProperty<BuildTemplate?>(nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupDataSource()
        self.setupPopupAction()
        self.setupEditableStates()
        
        //select if existing template is being edited
        let index: Int
        if let configId = self.existingTemplateId {
            let ids = self.buildTemplates.map { $0.id }
            index = ids.indexOf(configId) ?? 0
        } else {
            index = 0
        }
        self.selectItemAtIndex(index)
    }

    
}
