//
//  MenuItemManager.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 15/05/15.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Cocoa

class MenuItemManager : NSObject, NSMenuDelegate {
    
    private var statusItem: NSStatusItem?
    private var firstIndexLastSyncedMenuItem: Int!
    
    func setupMenuBarItem() {
        
        let statusBar = NSStatusBar.systemStatusBar()
        
        let statusItem = statusBar.statusItemWithLength(32)
        statusItem.title = ""
        statusItem.image = NSImage(named: "icon")
        statusItem.highlightMode = true
        
        var menu = NSMenu()
        menu.addItemWithTitle("Open Buildasaur", action: "showMainWindow", keyEquivalent: "")
        menu.addItemWithTitle("Quit Buildasaur", action: "terminate:", keyEquivalent: "")
        menu.addItem(NSMenuItem.separatorItem())
        self.firstIndexLastSyncedMenuItem = menu.numberOfItems
        
        statusItem.menu = menu
        menu.delegate = self
        self.statusItem = statusItem
    }
    
    func menuWillOpen(menu: NSMenu) {
        
        //update with last sync/statuses
        let syncers = StorageManager.sharedInstance.syncers
        
        //remove items for existing syncers
        let itemsForSyncers = menu.numberOfItems - self.firstIndexLastSyncedMenuItem
        let diffItems = syncers.count - itemsForSyncers
        
        //this many items need to be created or destroyed
        if diffItems > 0 {
            for i in 0..<diffItems {
                menu.addItemWithTitle("", action: "", keyEquivalent: "")
            }
        } else if diffItems < 0 {
            for i in 0..<abs(diffItems) {
                menu.removeItemAtIndex(menu.numberOfItems-1)
            }
        }
        
        //now we have the right number, update the data
        let texts = syncers.map({ (syncer: HDGitHubXCBotSyncer) -> String in
            
            let statusEmoji: String
            if syncer.active {
                statusEmoji = "✔️"
            } else {
                statusEmoji = "✖️"
            }
            
            let repo: String
            if let repoName = syncer.localSource.githubRepoName() {
                repo = repoName
            } else {
                repo = "???"
            }
            
            let time: String
            if let lastSuccess = syncer.lastSuccessfulSyncFinishedDate where syncer.active {
                time = "last synced \(lastSuccess.nicelyFormattedRelativeTimeToNow())"
            } else {
                time = "is not active"
            }
            
            let report = "\(statusEmoji) \(repo) \(time)"
            return report
        })
        
        //fill into items
        for (let i, let text) in enumerate(texts) {
            let idx = self.firstIndexLastSyncedMenuItem + i
            let item = menu.itemAtIndex(idx)
            item?.title = text
        }
    }

}
