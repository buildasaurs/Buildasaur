//
//  SyncPair.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 16/05/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

/*
*   this class describes the basic sync element: e.g. a PR + Bot, a branch + Bot, a branch + no bot, a bot + no PR
*   each sync pair has its own behaviors (a branch + no bot creates a bot, a bot + no PR deletes the bot,
*   a PR + Bot figures out what to do next, ...)
*   this is simpler than trying to catch all cases in one giant syncer class (at least I think)
*/
class SyncPair {
    
    var syncer: HDGitHubXCBotSyncer!
    
    init() {
        //
    }
    
    typealias Completion = (error: NSError?) -> ()
    
    /**
    *   Call to perform sync.
    */
    final func start(completion: Completion) {
        
        let start = NSDate()
        Log.verbose("SyncPair \(self.syncPairName()) started sync")
        
        self.sync { (error) -> () in
            
            let duration = start.timeIntervalSinceNow.clipTo(3)
            Log.verbose("SyncPair \(self.syncPairName()) finished sync after \(duration) seconds.")
            completion(error: error)
        }
    }
    
    /**
    *   To be overriden by subclasses.
    */
    func sync(completion: Completion) {
        assertionFailure("Must be overriden by subclasses")
    }
    
    /**
    *   To be overriden by subclasses.
    */
    func syncPairName() -> String {
        assertionFailure("Must be overriden by subclasses")
        return ""
    }
}
