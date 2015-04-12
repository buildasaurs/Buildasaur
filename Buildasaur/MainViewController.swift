//
//  ViewController.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 12/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Cocoa

//server trust - must be logged in in the browser first or have a server trust certificate.
//otherwise fails.

class MainViewController: NSViewController, NSTableViewDataSource, StatusSiblingsViewControllerDelegate {
    
    let storageManager: StorageManager
    
    var projectStatusViewController: StatusProjectViewController!
    var serverStatusViewController: StatusServerViewController!
    
    private var buildTemplateParams: (buildTemplate: BuildTemplate?, project: LocalSource)?
    
    required init?(coder: NSCoder) {
        
        self.storageManager = StorageManager.sharedInstance
        super.init(coder: coder)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        if let window = self.view.window {
            window.minSize = CGSizeMake(658, 486)
            window.title = "Buildasaur, at your service"
        }
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        
        let destinationController = segue.destinationController as! NSViewController
        let identifier = segue.identifier!
        
        if let statusViewController = destinationController as? StatusViewController {
            statusViewController.storageManager = self.storageManager
            statusViewController.delegate = self
            
            if let serverStatusViewController = statusViewController as? StatusServerViewController {
                self.serverStatusViewController = serverStatusViewController
            }
            
            if let projectStatusViewController = statusViewController as? StatusProjectViewController {
                self.projectStatusViewController = projectStatusViewController
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
    
    func showBuildTemplateViewControllerForTemplate(template: BuildTemplate?, project: LocalSource, sender: SetupViewControllerDelegate?) {

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
        var menu = NSMenu()
        menu.addItem(self.lastPollItem)
        menu.addItem(NSMenuItem.separatorItem())
        menu.addItemWithTitle("Open the App", action: "open", keyEquivalent: "")
        menu.addItemWithTitle("Quit Buildasaur", action: "terminate:", keyEquivalent: "")
        self.statusItem.menu = menu
    }

}



