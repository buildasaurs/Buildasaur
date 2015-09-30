//
//  StorageManager+RAC.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 30/09/2015.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import ReactiveCocoa
import XcodeServerSDK

extension StorageManager {
    
    public func serverConfigForHost(host: String) -> SignalProducer<XcodeServerConfig, NoError> {
        let xcodeConfigs = flattenArray(self.servers.producer.map { Array($0.values) })
        return xcodeConfigs.filter { $0.host == host }
    }
}
