//
//  BonjourUtils.swift
//  Buildasaur
//
//  Created by Seán Labastille on 17/08/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import BuildaUtils

public class BonjourUtilsTester {
    public class func dumpXcodeServers() {
        BonjourUtils.startDiscoveringXcodeServersAdvertisedOnBonjour()
    }
}

private protocol BonjourUtilsDelegate: class {
    func didDiscoverXcodeServer(service: NSNetService)
    func didRemoveXcodeServer(service: NSNetService)
}

/* Wraps NSNetService browsing to discover Xcode Server instances.
 * Service browsing needs to be started and stopped.
 * Once a service is found it needs to be resolved, at which point it can be used by clients.
 */
private class BonjourUtils {

    private static let browser = NSNetServiceBrowser()
    private static let browserDelegate = XcodeServerBrowserDelegate()
    private static weak var delegate: BonjourUtilsDelegate?

    private class func startDiscoveringXcodeServersAdvertisedOnBonjour() {
        browser.delegate = browserDelegate
        browser.searchForServicesOfType("_xcs2p._tcp.", inDomain: "local.")
    }

    private class func stopDiscoveringXcodeServersAdvertisedOnBonjour() {
        browser.stop()
    }

    private class XcodeServerBrowserDelegate: NSObject, NSNetServiceBrowserDelegate, NSNetServiceDelegate {
        private var services = [NSNetService]()

        @objc private func netServiceBrowserWillSearch(browser: NSNetServiceBrowser) { }

        @objc private func netServiceBrowserDidStopSearch(browser: NSNetServiceBrowser) { }

        @objc private func netServiceBrowser(browser: NSNetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) { }

        @objc private func netServiceBrowser(browser: NSNetServiceBrowser, didFindService service: NSNetService, moreComing: Bool) {
            service.resolveWithTimeout(10)
            service.delegate = self
            services.append(service)
            Log.info("Found Xcode Server Service: \(service)")
            if !moreComing {

            }
        }

        @objc private func netServiceBrowser(browser: NSNetServiceBrowser, didRemoveService service: NSNetService, moreComing: Bool) {
            if let index = services.indexOf(service) {
                Log.info("Removing Xcode Server Service: \(service)")
                delegate?.didRemoveXcodeServer(service)
                services.removeAtIndex(index)
            }

            if !moreComing {

            }
        }

        @objc private func netServiceWillResolve(sender: NSNetService) { }

        @objc private func netServiceDidResolveAddress(sender: NSNetService) {
            if sender.addresses?.count > 0 {
                sender.stop()
                Log.info("Resolved Xcode Server Service: \(sender.hostName ?? ""):\(sender.port)")
                delegate?.didDiscoverXcodeServer(sender)
            }
        }
        
        @objc private func netService(sender: NSNetService, didNotResolve errorDict: [String : NSNumber]) { }
    }
}
