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

class SyncerEditViewController: PresentableViewController {
    
    var syncerManager: SyncerManager!
    var configTriplet: EditableConfigTriplet!
    
    //----------
    
    var factory: ViewControllerFactory!

//    var syncer: HDGitHubXCBotSyncer!

    weak var projectStatusViewController: StatusProjectViewController?
    weak var emptyProjectStatusViewController: StatusProjectEmptyViewController?
    
    weak var serverStatusViewController: XcodeServerViewController?
    weak var emptyServerStatusViewController: EmptyXcodeServerViewController?
    
    weak var syncerStatusViewController: StatusSyncerViewController?
    
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
        
        if let storableViewController = viewController as? StorableViewController {
            storableViewController.storageManager = self.syncerManager.storageManager
            
            if let emptyProjectStatusViewController = storableViewController as? StatusProjectEmptyViewController {
                self.emptyProjectStatusViewController = emptyProjectStatusViewController
                emptyProjectStatusViewController.emptyProjectDelegate = self
            }
            
            if let emptyXcodeServerViewController = storableViewController as? EmptyXcodeServerViewController {
                self.emptyServerStatusViewController = emptyXcodeServerViewController
                emptyXcodeServerViewController.emptyServerDelegate = self
            }
            
            if let statusViewController = storableViewController as? StatusViewController {
                statusViewController.delegate = self
                
                if let serverStatusViewController = statusViewController as? XcodeServerViewController {
                    self.serverStatusViewController = serverStatusViewController
                    serverStatusViewController.serverConfig.value = self.configTriplet.server!
                }
                
                if let projectStatusViewController = statusViewController as? StatusProjectViewController {
                    self.projectStatusViewController = projectStatusViewController
                    projectStatusViewController.projectConfig.value = self.configTriplet.project!
                }
                
                if let syncerStatusViewController = statusViewController as? StatusSyncerViewController {
                    self.syncerStatusViewController = syncerStatusViewController
                    syncerStatusViewController.syncerConfig.value = self.configTriplet.syncer
                }
            }
        }
        
        if let buildTemplateViewController = viewController as? BuildTemplateViewController {
            buildTemplateViewController.storageManager = self.syncerManager.storageManager
            buildTemplateViewController.buildTemplate = self.buildTemplateParams!.buildTemplate
            buildTemplateViewController.project = self.buildTemplateParams!.project
            if let sender = sender as? SetupViewControllerDelegate {
                buildTemplateViewController.delegate = sender
            }
            self.buildTemplateParams = nil
        }
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        
        let destinationController = segue.destinationController as! NSViewController
        self.configureViewController(destinationController, sender: sender)
        super.prepareForSegue(segue, sender: sender)
    }
}

extension SyncerEditViewController: StatusProjectEmptyViewControllerDelegate {
    
    func detectedProjectOrWorkspaceAtUrl(url: NSURL) {
        //cool, let's take the url and create a proper project status vc
        //and replace the empty with it
        self.swapInFullProjectViewController(url)
    }
    
    private func swapInFullProjectViewController(url: NSURL) {
        
        let projectViewController: StatusProjectViewController = self.prepareViewController(.ProjectViewController)
//        projectViewController.url = url TODO: use the url
        let old = self.emptyProjectStatusViewController!
        self.replaceViewController(old, new: projectViewController)
    }
}

extension XcodeServerConfig {
    
    //means whether we have sufficient data etc, *NOT* whether
    //the server is reachable etc.
    func isValid() -> Bool {
        guard self.host.characters.count > 0 else { return false }
        let someUsername = self.user != nil
        let somePassword = self.password != nil
        
        //we should either have both or none
        return someUsername == somePassword
    }
}

extension SyncerEditViewController: EmptyXcodeServerViewControllerDelegate {
    
    func ensureCorrectXcodeServerViewController() {
        
        let old = self.emptyServerStatusViewController ?? self.serverStatusViewController!
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

extension SyncerEditViewController {
    
    private func prepareViewController<T: NSViewController>(type: SyncerEditVCType) -> T {
        let viewController: T = self.factory.createViewController(type)
        self.configureViewController(viewController, sender: self)
        return viewController
    }

    private func replaceViewController(old: NSViewController, new: NSViewController) {
        self.addChildViewController(new)
        self.transitionFromViewController(old, toViewController: new, options: NSViewControllerTransitionOptions.None, completionHandler: nil)
    }
}

extension SyncerEditViewController: StatusSiblingsViewControllerDelegate {
    
    func getProjectStatusViewController() -> StatusProjectViewController {
        return self.projectStatusViewController!
    }
    
    func getServerStatusViewController() -> XcodeServerViewController {
        return self.serverStatusViewController!
    }
    
    func showBuildTemplateViewControllerForTemplate(template: BuildTemplate?, project: Project, sender: SetupViewControllerDelegate?) {
        
        self.buildTemplateParams = (buildTemplate: template, project: project)
        self.performSegueWithIdentifier("showBuildTemplate", sender: sender)
        
        //TODO: read about unwind: http://stackoverflow.com/questions/9732499/how-to-dismiss-a-modal-that-was-presented-in-a-uistoryboard-with-a-modal-segue
    }
}


