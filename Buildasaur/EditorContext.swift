//
//  EditorContext.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/5/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaKit

struct EditorContext {
    var configTriplet: EditableConfigTriplet!
    var syncerManager: SyncerManager!
    weak var editeeDelegate: EditeeDelegate?
}
