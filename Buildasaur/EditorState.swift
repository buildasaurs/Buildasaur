//
//  EditorState.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/5/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation

enum EditorState: Int {
    
    case NoServer
    case EditingServer
    case VerifiedServer
    
    case NoProject
    case EditingProject
    case VerifiedProject
    
    case NoBuildTemplate
    case EditingBuildTemplate
    case VerifiedBuildTemplate
    
    case EditingSyncer
    case VerifiedSyncer
    
    case AllVerified
}

extension EditorState: Comparable { }

func <(lhs: EditorState, rhs: EditorState) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

