//
//  SourceControlFileParser.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 29/09/2015.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation

protocol SourceControlFileParser {

    func supportedFileExtensions() -> [String]
    func parseFileAtUrl(url: NSURL) throws -> WorkspaceMetadata
}

