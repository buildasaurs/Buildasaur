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
    
    //for creating presentable VCs, not sure it should live here though.
    typealias PresentViewControllerType = (viewController: PresentableViewController) -> ()
    let presentViewController: PresentViewControllerType
    typealias CreateViewControllerType = (storyboardIdentifier: String, uniqueIdentifier: String) -> SyncerEditViewController
    let createViewController: CreateViewControllerType
    
    init(syncer: HDGitHubXCBotSyncer, presentViewController: PresentViewControllerType, createViewController: CreateViewControllerType) {
        self.syncer = syncer
        self.presentViewController = presentViewController
        self.createViewController = createViewController
        
        let active = syncer.activeSignalProducer.producer
        
        self.status = active.map { SyncerViewModel.stringForState($0) }
        
        self.host = syncer.xcodeServer
            .producer
            .map { $0?.config.host ?? "[No Xcode Server]" }
        
        self.projectName = syncer.project.producer
            .map { $0?.workspaceMetadata?.projectName ?? "[No Project]" }
        
        self.buildTemplateName = SignalProducer(value: syncer.currentBuildTemplate().name!)
        self.editButtonTitle = SignalProducer(value: "Edit")
        self.editButtonEnabled = active.map { !$0 }
        self.controlButtonTitle = active.map { $0 ? "Stop" : "Start" }
    }
    
    func editButtonClicked() {
        
        //present the edit window
        let syncerEditViewController: SyncerEditViewController = self.createViewController(storyboardIdentifier: "syncerEditViewController", uniqueIdentifier: "Syncer_\(syncer.hash)")
        syncerEditViewController.syncer = self.syncer
        self.presentViewController(viewController: syncerEditViewController)
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

