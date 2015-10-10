//
//  MainEditor_EditeeDelegate.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/5/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaKit
import XcodeServerSDK

//here conform to all the delegates of the view controllers and
//figure out what the required actions are.

extension MainEditorViewController: EditeeDelegate { }

extension MainEditorViewController: EmptyXcodeServerViewControllerDelegate {
    
    func didSelectXcodeServerConfig(config: XcodeServerConfig) {
        self.context.value.configTriplet.server = config
    }
}

extension MainEditorViewController: XcodeServerViewControllerDelegate {
    
    func didCancelEditingOfXcodeServerConfig(config: XcodeServerConfig) {
        self.context.value.configTriplet.server = nil
        self.previous(animated: false)
    }
}

extension MainEditorViewController: EmptyProjectViewControllerDelegate {
    
    func didSelectProjectConfig(config: ProjectConfig) {
        self.context.value.configTriplet.project = config
    }
}

extension MainEditorViewController: ProjectViewControllerDelegate {
    
    func didCancelEditingOfProjectConfig(config: ProjectConfig) {
        self.context.value.configTriplet.project = nil
        self.previous(animated: false)
    }
}

extension MainEditorViewController: EmptyBuildTemplateViewControllerDelegate {
    
    func didSelectBuildTemplate(buildTemplate: BuildTemplate) {
        self.context.value.configTriplet.buildTemplate = buildTemplate
    }
}

extension MainEditorViewController: BuildTemplateViewControllerDelegate {
    
    func didCancelEditingOfBuildTemplate(template: BuildTemplate) {
        self.context.value.configTriplet.buildTemplate = nil
        self.previous(animated: false)
    }
}

extension MainEditorViewController: SyncerViewControllerDelegate {
    
    func didCancelEditingOfSyncerConfig(config: SyncerConfig) {
        //no-op
    }
    
    func didSaveSyncerConfig(config: SyncerConfig) {
        self.context.value.configTriplet.syncer = config
    }
}

