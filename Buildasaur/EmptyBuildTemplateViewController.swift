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
    func didSelectBuildTemplate(buildTemplateRef: RefType)
}

class EmptyBuildTemplateViewController: EditableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
