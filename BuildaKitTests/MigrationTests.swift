//
//  MigrationTests.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/12/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import XCTest
import Nimble
@testable import BuildaKit

class MigrationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        Ref.reset()
    }
    
    func testBundle() -> NSBundle {
        
        let bundle = NSBundle(forClass: MigrationTests.classForCoder())
        return bundle
    }
    
    func resourceURLFromTestBundle(name: String) -> NSURL {
        return self.testBundle().URLForResource(name, withExtension: nil)!
    }
    
    func writingURL(name: String) -> NSURL {
        let dir = NSTemporaryDirectory()
//        let dir = "/Users/honzadvorsky/Desktop/TestLocation/"
        let path = (dir as NSString).stringByAppendingPathComponent(name)
        let writingURL = NSURL(fileURLWithPath: path, isDirectory: true)
        
        //delete the folder first
        _ = try? NSFileManager.defaultManager().removeItemAtURL(writingURL)
        
        return writingURL
    }
    
    enum HierarchyError: ErrorType {
        case DifferentFileNames(real: String?, expected: String?)
        case DifferentFileContents(file: String?)
        case DifferentFolderContents(real: [String], expected: [String])
    }
    
    func ensureEqualHierarchies(persistence: Persistence, urlExpected: NSURL, urlReal: NSURL) throws {
        
        if !urlReal.hasDirectoryPath {
            
            let exp = urlExpected.lastPathComponent
            let real = urlReal.lastPathComponent
            
            if exp != real {
                throw HierarchyError.DifferentFileNames(real: real, expected: exp)
            }
            
            let expData = NSData(contentsOfURL: urlExpected)
            let realData = NSData(contentsOfURL: urlReal)
            if expData != realData {
                throw HierarchyError.DifferentFileContents(file: real)
            }
            return
        }
        
        //recursively walk both trees and make sure everything is the same
        let filesReal = persistence.filesInFolder(urlReal) ?? []
        let filesExp = persistence.filesInFolder(urlExpected) ?? []
        
        let fileNamesReal = filesReal.map { $0.lastPathComponent! }
        let fileNamesExp = filesExp.map { $0.lastPathComponent! }
        
        if fileNamesReal != fileNamesExp {
            throw HierarchyError.DifferentFolderContents(real: fileNamesReal, expected: fileNamesExp)
        }
        
        for idx in 0..<filesExp.count {
            try self.ensureEqualHierarchies(persistence, urlExpected: filesExp[idx], urlReal: filesReal[idx])
        }
    }
    
    func testMigration_v0_v1() {
        
        let readingURL = self.resourceURLFromTestBundle("Buildasaur-format-0-example1")
        let writingURL = self.writingURL("v0-v1")
        let expectedURL = self.resourceURLFromTestBundle("Buildasaur-format-1-example1")
        
        let fileManager = NSFileManager.defaultManager()
        
        let persistence = Persistence(readingFolder: readingURL, writingFolder: writingURL, fileManager: fileManager)
        let migrator = Migrator_v0_v1(persistence: persistence)
        
        do {
            try migrator.attemptMigration()
            try self.ensureEqualHierarchies(persistence, urlExpected: expectedURL, urlReal: writingURL)
        } catch {
            fail("\(error)")
        }
    }
    
    func testMigration_v1_v2() {
        
        let readingURL = self.resourceURLFromTestBundle("Buildasaur-format-1-example1")
        let writingURL = self.writingURL("v1-v2")
        let expectedURL = self.resourceURLFromTestBundle("Buildasaur-format-2-example1")
        
        let fileManager = NSFileManager.defaultManager()
        
        let persistence = Persistence(readingFolder: readingURL, writingFolder: writingURL, fileManager: fileManager)
        let migrator = Migrator_v1_v2(persistence: persistence)
        
        do {
            try migrator.attemptMigration()
            try self.ensureEqualHierarchies(persistence, urlExpected: expectedURL, urlReal: writingURL)
        } catch {
            fail("\(error)")
        }
    }
    
    func testMigration_v2_v3() {
        
        let readingURL = self.resourceURLFromTestBundle("Buildasaur-format-2-example2")
        let writingURL = self.writingURL("v2-v3")
        let expectedURL = self.resourceURLFromTestBundle("Buildasaur-format-3-example1")
        
        let fileManager = NSFileManager.defaultManager()
        
        let persistence = Persistence(readingFolder: readingURL, writingFolder: writingURL, fileManager: fileManager)
        let migrator = Migrator_v2_v3(persistence: persistence)
        
        do {
            try migrator.attemptMigration()
            try self.ensureEqualHierarchies(persistence, urlExpected: expectedURL, urlReal: writingURL)
        } catch {
            fail("\(error)")
        }
    }
    
    func testMigration_v3_v4() {
        
        let readingURL = self.resourceURLFromTestBundle("Buildasaur-format-3-example2")
        let writingURL = self.writingURL("v3-v4")
        let expectedURL = self.resourceURLFromTestBundle("Buildasaur-format-4-example1")
        
        let fileManager = NSFileManager.defaultManager()
        
        let persistence = Persistence(readingFolder: readingURL, writingFolder: writingURL, fileManager: fileManager)
        let migrator = Migrator_v3_v4(persistence: persistence)
        
        do {
            try migrator.attemptMigration()
            try self.ensureEqualHierarchies(persistence, urlExpected: expectedURL, urlReal: writingURL)
        } catch {
            fail("\(error)")
        }
    }
    
    func testPersistenceSetter() {
        
        let tmp = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let persistence1 = Persistence(readingFolder: tmp, writingFolder: tmp, fileManager: NSFileManager.defaultManager())
        
        let migrator = CompositeMigrator(persistence: persistence1)
        for i in migrator.childMigrators {
            expect(i.persistence) === persistence1
        }
        
        let persistence2 = Persistence(readingFolder: tmp, writingFolder: tmp, fileManager: NSFileManager.defaultManager())
        migrator.persistence = persistence2
        
        for i in migrator.childMigrators {
            expect(i.persistence) === persistence2
        }
    }
}
