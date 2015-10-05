//
//  ViewController.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 12/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Cocoa
import BuildaKit
import XcodeServerSDK
import ReactiveCocoa

class SyncerEditViewController: PresentableViewController {
    
    var syncerManager: SyncerManager!
    var configTriplet: EditableConfigTriplet!
    
    //----------
    
    var factory: ViewControllerFactory!

//    var syncer: HDGitHubXCBotSyncer!

    weak var projectViewController: ProjectViewController?
    weak var emptyProjectViewController: EmptyProjectViewController?
    
    weak var serverViewController: XcodeServerViewController?
    weak var emptyServerViewController: EmptyXcodeServerViewController?
    
    weak var syncerViewController: StatusSyncerViewController?
    
    let currentStage = MutableProperty<EditorState>(.NoServer)
    
    private var buildTemplateParams: (buildTemplate: BuildTemplate?, project: Project)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.factory = ViewControllerFactory(storyboardLoader: self.storyboardLoader)
        
        //TODO: move to a better place
//        if self.syncer != nil {
//            if let project = self.syncer.project.value {
//                self.swapInFullProjectViewController(project.url)
//            }
//        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
//        self.title = self.syncer.project.value?.workspaceMetadata?.projectName
        
        if let window = self.view.window {
            window.minSize = CGSizeMake(658, 512)
        }
    }
    
    func configureViewController(viewController: NSViewController, sender: AnyObject?) {
        
//        if let editableViewController = viewController as? EditableViewController {
//            editableViewController.storageManager = self.syncerManager.storageManager
//            
//            let stage = self.currentStage.producer
//            let serverEditable = stage.map { $0 != .AllVerified }
//            let projectEditable = stage.map { $0 >= .EditingProject }
//            let syncerEditable = stage.map { $0 >= .EditingSyncer }
//            
//            if let emptyServerViewController = storableViewController as? EmptyXcodeServerViewController {
//                self.emptyServerViewController = emptyServerViewController
//                emptyServerViewController.emptyServerDelegate = self
//                emptyServerViewController.editingAllowed <~ serverEditable
//                
//                self.currentStage.value = .NoServer
//            }
//
//            if let emptyProjectViewController = storableViewController as? EmptyProjectViewController {
//                self.emptyProjectViewController = emptyProjectViewController
//                emptyProjectViewController.emptyProjectDelegate = self
//                emptyProjectViewController.editingAllowed <~ projectEditable
//            }
//            
//            if let statusViewController = storableViewController as? StatusViewController {
//                
//                if let serverViewController = statusViewController as? XcodeServerViewController {
//                    self.serverViewController = serverViewController
//                    serverViewController.serverConfig.value = self.configTriplet.server!
//                    serverViewController.cancelDelegate = self
//                    serverViewController.editingAllowed <~ serverEditable
//                    
//                    self.currentStage.value = .EditingServer
//                }
//                
//                if let projectViewController = statusViewController as? ProjectViewController {
//                    self.projectViewController = projectViewController
//                    projectViewController.projectConfig.value = self.configTriplet.project!
//                    projectViewController.cancelDelegate = self
//                    projectViewController.editingAllowed <~ projectEditable
//                    
//                    self.currentStage.value = .EditingProject
//                }
//                
//                if let syncerViewController = statusViewController as? StatusSyncerViewController {
//                    self.syncerViewController = syncerViewController
//                    syncerViewController.syncerConfig.value = self.configTriplet.syncer
//                    syncerViewController.editingAllowed <~ syncerEditable
//                }
//            }
//        }
//        
//        if let buildTemplateViewController = viewController as? BuildTemplateViewController {
//            buildTemplateViewController.storageManager = self.syncerManager.storageManager
//            buildTemplateViewController.buildTemplate = self.buildTemplateParams!.buildTemplate
//            buildTemplateViewController.project = self.buildTemplateParams!.project
//            if let sender = sender as? SetupViewControllerDelegate {
//                buildTemplateViewController.delegate = sender
//            }
//            self.buildTemplateParams = nil
//        }
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        
        let destinationController = segue.destinationController as! NSViewController
        self.configureViewController(destinationController, sender: sender)
        super.prepareForSegue(segue, sender: sender)
    }
}

extension SyncerEditViewController: EmptyProjectViewControllerDelegate {
    
    func ensureCorrectProjectViewController() {
        
        let old = self.emptyProjectViewController ?? self.projectViewController!
        var new: NSViewController!
        if let _ = self.configTriplet.project {
            //present the editing vc
            let viewController: ProjectViewController = self.prepareViewController(SyncerEditVCType.ProjectVC)
            new = viewController
        } else {
            //present choice - use existing or new
            let viewController: EmptyProjectViewController = self.prepareViewController(SyncerEditVCType.EmptyProjectVC)
            new = viewController
        }
        self.replaceViewController(old, new: new)
    }
        
    func didSelectProjectConfig(config: ProjectConfig) {
        self.configTriplet.project = config
        self.ensureCorrectProjectViewController()
    }
}

extension SyncerEditViewController: EmptyXcodeServerViewControllerDelegate {
    
    func ensureCorrectXcodeServerViewController() {
        
        let old = self.emptyServerViewController ?? self.serverViewController!
        var new: NSViewController!
        if let _ = self.configTriplet.server {
            //present the editing vc
            let viewController: XcodeServerViewController = self.prepareViewController(SyncerEditVCType.XcodeServerVC)
            new = viewController
        } else {
            //present choice - use existing or new
            let viewController: EmptyXcodeServerViewController = self.prepareViewController(SyncerEditVCType.EmptyXcodeServerVC)
            new = viewController
        }
        self.replaceViewController(old, new: new)
    }
    
    func didSelectXcodeServerConfig(config: XcodeServerConfig) {
        self.configTriplet.server = config
        self.ensureCorrectXcodeServerViewController()
    }
}

extension SyncerEditViewController: XcodeServerViewControllerDelegate {
    
    func didCancelEditingOfXcodeServerConfig(config: XcodeServerConfig) {
        self.configTriplet.server = nil
        self.ensureCorrectXcodeServerViewController()
    }
}

extension SyncerEditViewController: ProjectViewControllerDelegate {
    
    func didCancelEditingOfProjectConfig(config: ProjectConfig) {
        self.configTriplet.project = nil
        self.ensureCorrectProjectViewController()
    }
}

extension SyncerEditViewController {
    
    private func prepareViewController<T: NSViewController>(type: SyncerEditVCType) -> T {
        let viewController: T = self.factory.createViewController(type)
        self.configureViewController(viewController, sender: self)
        return viewController
    }

    private func replaceViewController(old: NSViewController, new: NSViewController) {
        self.addChildViewController(new)
        self.transitionFromViewController(old, toViewController: new, options: NSViewControllerTransitionOptions.None, completionHandler: {
            [weak old] in
            old?.removeFromParentViewController()
        })
    }
}

//    func showBuildTemplateViewControllerForTemplate(template: BuildTemplate?, project: Project, sender: SetupViewControllerDelegate?) {
//        
//        self.buildTemplateParams = (buildTemplate: template, project: project)
//        self.performSegueWithIdentifier("showBuildTemplate", sender: sender)
//        
//        //TODO: read about unwind: http://stackoverflow.com/questions/9732499/how-to-dismiss-a-modal-that-was-presented-in-a-uistoryboard-with-a-modal-segue
//    }



