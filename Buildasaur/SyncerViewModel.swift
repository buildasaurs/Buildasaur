//
//  SyncerViewModel.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 28/09/2015.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaKit
import ReactiveCocoa

struct SyncerViewModel {
    
    let syncer: HDGitHubXCBotSyncer
    
    let status: SignalProducer<String, NoError>
    let host: SignalProducer<String, NoError>
    let projectName: SignalProducer<String, NoError>
    let buildTemplateName: SignalProducer<String, NoError>
    let editButtonTitle: SignalProducer<String, NoError>
    let editButtonEnabled: SignalProducer<Bool, NoError>
    let controlButtonTitle: SignalProducer<String, NoError>
    
    typealias PresentEditViewControllerType = (ConfigTriplet) -> ()
    let presentEditViewController: PresentEditViewControllerType
    
    init(syncer: HDGitHubXCBotSyncer, presentEditViewController: PresentEditViewControllerType) {
        self.syncer = syncer
        self.presentEditViewController = presentEditViewController
        
        let active = syncer.activeSignalProducer.producer
        
        self.status = active.map { SyncerViewModel.stringForState($0) }
        
        self.host = SignalProducer(value: syncer.xcodeServer)
            .map { $0.config.host ?? "[No Xcode Server]" }
        
        self.projectName = SignalProducer(value: syncer.project)
            .map { $0.workspaceMetadata?.projectName ?? "[No Project]" }
        
        self.buildTemplateName = SignalProducer(value: syncer.buildTemplate.name)
        self.editButtonTitle = SignalProducer(value: "Edit")
        self.editButtonEnabled = active.map { !$0 }
        self.controlButtonTitle = active.map { $0 ? "Stop" : "Start" }
    }
    
    func editButtonClicked() {
        
        //present the edit window
        let triplet = self.syncer.configTriplet
        self.presentEditViewController(triplet)
    }
    
    func showDetailButtonClicked(startEditing: Bool) {
        
    }
    
    func startButtonClicked() {
        //TODO: run through validation first?
        self.syncer.active = true
    }
    
    func stopButtonClicked() {
        self.syncer.active = false
    }
    
    func controlButtonClicked() {
        //TODO: run through validation first?
        self.syncer.active = !self.syncer.active
    }
    
    private static func stringForState(active: Bool) -> String {
        if active {
            return "✔️ syncing..."
        } else {
            return "✖️ stopped."
        }
    }
    
}

