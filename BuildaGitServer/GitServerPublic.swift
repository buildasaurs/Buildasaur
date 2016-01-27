//
//  GitSourcePublic.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 12/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

public enum GitService: String {
    case GitHub = "github"
    case BitBucket = "bitbucket"
//    case GitLab = "gitlab"
    
    public func prettyName() -> String {
        switch self {
        case .GitHub: return "GitHub"
        case .BitBucket: return "BitBucket"
        }
    }
    
    public func logoName() -> String {
        switch self {
        case .GitHub: return "github"
        case .BitBucket: return "bitbucket"
        }
    }
}

public class GitServer : HTTPServer {
    let service: GitService
    
    init(service: GitService, http: HTTP? = nil) {
        self.service = service
        super.init(http: http)
    }
}

