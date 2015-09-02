//
//  ViewController.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 12/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Cocoa
import BuildaKit

//server trust - must be logged in in the browser first or have a server trust certificate.
//otherwise fails.

class MainViewController: NSViewController, NSTableViewDataSource, StatusSiblingsViewControllerDelegate {
    
    let storageManager: StorageManager
    
    private var _dataSource: ProjectDataSource?
    
    var projectStatusViewController: StatusProjectViewController!
    var serverStatusViewController: StatusServerViewController!
    
    private var buildTemplateParams: (buildTemplate: BuildTemplate?, project: Project)?
    
    required init?(coder: NSCoder) {
        
        self.storageManager = StorageManager.sharedInstance
        super.init(coder: coder)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        if let window = self.view.window {
            window.minSize = CGSizeMake(658, 512)
            if let activeProject = self.dataSource?.project where activeProject.githubRepoName() != nil {
                window.title = activeProject.githubRepoName()!
            }
            else {
                
                window.title = "Create New Project"
            }
        }
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        
        let destinationController = segue.destinationController as! NSViewController
        
        if let statusViewController = destinationController as? StatusViewController {
            statusViewController.storageManager = self.storageManager
            statusViewController.delegate = self
            
            if let serverStatusViewController = statusViewController as? StatusServerViewController {
                self.serverStatusViewController = serverStatusViewController
            }
            
            if let projectStatusViewController = statusViewController as? StatusProjectViewController {
                self.projectStatusViewController = projectStatusViewController
                self.projectStatusViewController.dataSource = self.dataSource
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

extension MainViewController: ProjectDataSource {
    
    var dataSource : ProjectDataSource? {
        get {
            return self._dataSource
        }
        set {
            self._dataSource = newValue
        }
    }
}



