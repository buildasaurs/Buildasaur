//
//  ViewController.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 12/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Cocoa
import BuildaKit

class SyncerEditViewController: PresentableViewController, NSTableViewDataSource, StatusSiblingsViewControllerDelegate {
    
    var syncer: HDGitHubXCBotSyncer!
    var storageManager: StorageManager! //TODO: this should be removed for a less capable, read-only version
    
    var projectStatusViewController: StatusProjectViewController!
    var serverStatusViewController: StatusServerViewController!
    var syncerStatusViewController: StatusSyncerViewController!
    
    private var buildTemplateParams: (buildTemplate: BuildTemplate?, project: Project)?
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.title = self.syncer.project.workspaceMetadata?.projectName
        
        if let window = self.view.window {
            window.minSize = CGSizeMake(658, 512)
        }
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        
        let destinationController = segue.destinationController as! NSViewController
        
        if let statusViewController = destinationController as? StatusViewController {
            statusViewController.storageManager = self.storageManager
            statusViewController.delegate = self
            
            if let serverStatusViewController = statusViewController as? StatusServerViewController {
                self.serverStatusViewController = serverStatusViewController
                serverStatusViewController.serverConfig = self.syncer.xcodeServer.config
            }
            
            if let projectStatusViewController = statusViewController as? StatusProjectViewController {
                self.projectStatusViewController = projectStatusViewController
                projectStatusViewController.project = self.syncer.project
            }
            
            if let syncerStatusViewController = statusViewController as? StatusSyncerViewController {
                self.syncerStatusViewController = syncerStatusViewController
                syncerStatusViewController.syncer = self.syncer
            }
        }
        
        if let buildTemplateViewController = destinationController as? BuildTemplateViewController {
            buildTemplateViewController.storageManager = self.storageManager
            buildTemplateViewController.buildTemplate = self.buildTemplateParams!.buildTemplate
            buildTemplateViewController.project = self.buildTemplateParams!.project
            if let sender = sender as? SetupViewControllerDelegate {
                buildTemplateViewController.delegate = sender
            }
            self.buildTemplateParams = nil
        }
        
        super.prepareForSegue(segue, sender: sender)
    }
    
    func getProjectStatusViewController() -> StatusProjectViewController {
        return self.projectStatusViewController
    }
    
    func getServerStatusViewController() -> StatusServerViewController {
        return self.serverStatusViewController
    }
    
    func showBuildTemplateViewControllerForTemplate(template: BuildTemplate?, project: Project, sender: SetupViewControllerDelegate?) {

        self.buildTemplateParams = (buildTemplate: template, project: project)
        self.performSegueWithIdentifier("showBuildTemplate", sender: sender)
        
        //TODO: read about unwind: http://stackoverflow.com/questions/9732499/how-to-dismiss-a-modal-that-was-presented-in-a-uistoryboard-with-a-modal-segue
    }
    
    func open() {
        NSApp.activateIgnoringOtherApps(true)
        self.view.window!.makeKeyAndOrderFront(self)
    }
    
    var statusItem: NSStatusItem!
    var lastPollItem: NSMenuItem!
    
    func setupMenuBarIcon() {
        self.lastPollItem = NSMenuItem()
        self.lastPollItem.title = "-"
        self.statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
        self.statusItem.title = ""
        let image = NSImage(named: "icon")
        self.statusItem.image = image
        self.statusItem.highlightMode = true
        let menu = NSMenu()
        menu.addItem(self.lastPollItem)
        menu.addItem(NSMenuItem.separatorItem())
        menu.addItemWithTitle("Open the App", action: "open", keyEquivalent: "")
        menu.addItemWithTitle("Quit Buildasaur", action: "terminate:", keyEquivalent: "")
        self.statusItem.menu = menu
    }

}


