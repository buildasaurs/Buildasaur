//
//  AppDelegate.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 12/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Cocoa

/*
Please report any crashes on GitHub, I may optionally ask you to email them to me. Thanks!
You can find them at ~/Library/Logs/DiagnosticReports/Buildasaur-*
Also, you can find the log at ~/Library/Application Support/Buildasaur/Builda.log
*/

import BuildaUtils
import XcodeServerSDK
import BuildaKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var syncerManager: SyncerManager!
    
    let menuItemManager = MenuItemManager()

    var storyboardLoader: StoryboardLoader!
    
    var dashboardViewController: DashboardViewController?
    var dashboardWindow: NSWindow!
    var windows: Set<NSWindow> = []
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        Logging.setup(alsoIntoFile: true)
        
        let defs = NSUserDefaults.standardUserDefaults()
        defs.setBool(true, forKey: "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")
        defs.synchronize()
        
        self.setupPersistence()
        
        self.storyboardLoader = StoryboardLoader(storyboard: NSStoryboard.mainStoryboard)
        self.storyboardLoader.delegate = self

        self.menuItemManager.syncerManager = self.syncerManager
        self.menuItemManager.setupMenuBarItem()
        
        let dashboard = self.createInitialViewController()
        self.dashboardViewController = dashboard
        self.presentViewControllerInUniqueWindow(dashboard)
        self.dashboardWindow = self.windowForPresentableViewControllerWithIdentifier("dashboard")!.0
    }
    
    func setupPersistence() {
        let storageManager = StorageManager()
        let factory = SyncerFactory()
        let syncerManager = SyncerManager(storageManager: storageManager, factory: factory)
        self.syncerManager = syncerManager
    }

    func createInitialViewController() -> DashboardViewController {
        
        let dashboard: DashboardViewController = self.storyboardLoader
            .presentableViewControllerWithStoryboardIdentifier("dashboardViewController", uniqueIdentifier: "dashboard", delegate: self)
        dashboard.syncerManager = self.syncerManager
        return dashboard
    }
    
    func applicationShouldHandleReopen(sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        
        self.showMainWindow()
        return true
    }
    
    func applicationDidBecomeActive(notification: NSNotification) {
        
        self.showMainWindow()
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        
        //stop syncers properly
        self.syncerManager.stopSyncers()
    }
    
    //MARK: Showing Window on Reactivation
    
    func showMainWindow(){
        
        NSApp.activateIgnoringOtherApps(true)
        
        //first window. i wish there was a nicer way (please some tell me there is)
        if NSApp.windows.count < 3 {
            self.dashboardWindow.makeKeyAndOrderFront(self)
        }
    }
}

extension AppDelegate: PresentableViewControllerDelegate {
    
    func configureViewController(viewController: PresentableViewController) {
        
        //
    }
    
    func presentViewControllerInUniqueWindow(viewController: PresentableViewController) {
        
        //last chance to config
        self.configureViewController(viewController)
        
        //make sure we're the delegate
        viewController.presentingDelegate = self
        
        //check for an existing window
        let identifier = viewController.uniqueIdentifier
        var newWindow: NSWindow?
        
        if let existingPair = self.windowForPresentableViewControllerWithIdentifier(identifier) {
            newWindow = existingPair.0
        } else {
            newWindow = NSWindow(contentViewController: viewController)
            newWindow?.autorecalculatesKeyViewLoop = true
        }
        
        guard let window = newWindow else { fatalError("Unable to create window") }
        
        window.delegate = self
        self.windows.insert(window)
        window.makeKeyAndOrderFront(self)
    }
    
    func closeWindowWithViewController(viewController: PresentableViewController) {
        
        if let window = self.windowForPresentableViewControllerWithIdentifier(viewController.uniqueIdentifier)?.0 {
            
            if window.delegate?.windowShouldClose!(self) ?? true {
                window.close()
            }
        }
    }
}

extension AppDelegate: StoryboardLoaderDelegate {
    
    func windowForPresentableViewControllerWithIdentifier(identifier: String) -> (NSWindow, PresentableViewController)? {
        
        for window in self.windows {
            
            guard let viewController = window.contentViewController else { continue }
            guard let presentableViewController = viewController as? PresentableViewController else { continue }
            if presentableViewController.uniqueIdentifier == identifier {
                return (window, presentableViewController)
            }
        }
        return nil
    }
    
    func storyboardLoaderExistingViewControllerWithIdentifier(identifier: String) -> PresentableViewController? {
        //look through our windows and their view controllers to see if we can't find this view controller
        let pair = self.windowForPresentableViewControllerWithIdentifier(identifier)
        return pair?.1
    }
}

extension AppDelegate: NSWindowDelegate {
    
    func windowShouldClose(sender: AnyObject) -> Bool {
        
        if let window = sender as? NSWindow {
            self.windows.remove(window)
        }
        
        //TODO: based on the editing state, if editing VC (cancel/save)
        return true
    }
}

