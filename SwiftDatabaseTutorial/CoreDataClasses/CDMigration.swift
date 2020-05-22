//
//  CDMigration.swift
//  SwiftDatabaseTutorial
//
//  Created by Roy, Bidhan (623) on 21/05/20.
//  Copyright © 2020 Roy, Bidhan (623). All rights reserved.
//

import Foundation
import CoreData
import UIKit


private let _sharedCDMigration = CDMigration()
class CDMigration: NSObject {

    // MARK: - SHARED INSTANCE
    class var shared : CDMigration {
        return _sharedCDMigration
    }
    
    // MARK: - SUPPORTING FUNCTIONS
    ///The storeExistsAtPath function uses NSFileManager to determine whether a store exists at the given URL. It returns a Bool indicating the result.
    func storeExistsAtPath(storeURL:URL?) -> Bool {
        if let storeURL = storeURL {
           let storePath = storeURL.path
            if FileManager.default.fileExists(atPath: storePath) {
                return true
            }
        } else {print("\(#function) FAILED to get store path")}
        return false
    }

    ///The store:isCompatibleWithModel function first checks that a store exists at the given path. If there is no store, true is returned because this prevents a migration from being attempted. If a store exists at the given URL, it is checked for model compatibility against the given model. To do this, the model used to create the store is drawn from the store’s metadata and then compared to the given model via its isConfiguration:compatibleWithStoreMetadata function.
    func store(storeURL:URL, isCompatibleWithModel model:NSManagedObjectModel) -> Bool {

        if self.storeExistsAtPath(storeURL: storeURL) == false {
            return true // prevent migration of a store that does not exist
        }

        do {
            var metadata:[String : Any]?
            metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL, options: nil)
            if let metadata = metadata {
                if model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) {

                    print("The store is compatible with the current version of the model")
                    return true
                }
            } else {print("\(#function) FAILED to get metadata")}
        } catch {
            print("ERROR getting metadata from \(storeURL) \(error)")
        }
        print("The store is NOT compatible with the current version of the model")
        return false
    }
    
    ///The replaceStore function uses NSFileManager to remove the incompatible store from the file system and then replaces it with the compatible store.
    func replaceStore(oldStore:URL, newStore:URL) throws {

        let manager = FileManager.default

        do {
            try manager.removeItem(at: oldStore)
            try manager.moveItem(at: newStore, to: oldStore)
        }
    }
    
    // MARK: - PROGRESS REPORTING
    ///When a migration is in progress, the value of the migration manager’s migrationProgress variable is constantly updated. This is information that the user needs to see, so a function is required to react whenever the migrationProgress value changes.
    ///
    ///
    ///TODO -  Add RXSwift here
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object is NSMigrationManager, let manager = object as? NSMigrationManager {
            if let notification = keyPath {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: notification), object: NSNumber(value: manager.migrationProgress))
            }
        } else {
            print("observeValueForKeyPath did not receive a NSMigrationManager class")
        }
    }
    
    
    //MARK: Migration
    ///function is where the actual migration happens. Most of this function is used to gather all the pieces required to perform a migration
    ///
    ///
    ///The migrateStore function needs to be given a store to migrate, a source model to migrate from, and destination model to migrate to. The source model could have been taken from the given store’s metadata; however, seeing as this step is performed first in another function, this approach saves repeated code.
    ///
    ///The first thing migrateStore does is prepare four variables:
    ///
    /// The tempdir variable holds the URL to the given store and is used to build a URL to a temporary store used for migration.
    ///
    /// The tempStore variable holds the URL to the temporary store used for migration.
    ///
    /// The mappingModel variable holds an instance of NSMappingModel specific to the models being migrated from and to. The migration will fail without a mapping model.
    ///
    /// The migrationManager variable holds an instance of NSMigrationManager based on the source and destination models. An observer is added for the migrationProgress variable so that the observeValueForKeyPath function is called whenever the migrationProgress variable changes.
    ///
    /// All these variables are then used to make a call to the migrateStoreFromURL function, which is responsible for migrating the given store to be compatible with the destination model. Once this is complete, the old incompatible store is removed and the new compatible store is put in its place.
    
    func migrateStore(store:URL, sourceModel:NSManagedObjectModel, destinationModel:NSManagedObjectModel) {

        if let tempdir = store.deletingLastPathComponent() as URL? {
            let tempStore = tempdir.appendingPathComponent("Temp.sqlite")
            let mappingModel = NSMappingModel(from: nil, forSourceModel: sourceModel, destinationModel: destinationModel)
            let migrationManager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)
            migrationManager.addObserver(self, forKeyPath: "migrationProgress", options: NSKeyValueObservingOptions.new, context: nil)

            do {

                try migrationManager.migrateStore(from: store, sourceType: NSSQLiteStoreType, options: nil,with: mappingModel, toDestinationURL: tempStore, destinationType: NSSQLiteStoreType, destinationOptions: nil)
                try replaceStore(oldStore: store, newStore: tempStore)

                print("SUCCESSFULLY MIGRATED \(store) to the Current Model")

            } catch {
                print("FAILED MIGRATION: \(error)")
            }
            migrationManager.removeObserver(self, forKeyPath: "migrationProgress")
        } else {print("\(#function) FAILED to prepare temporary directory")}
    }
    
    ///The migration code that has just been implemented needs to be called from a background thread so that the user interface can be updated without freezing. This, along with the instantiation of the progress view that the user sees
    ///
    ///
    ///The migrateStoreWithProgressUI function uses a storyboard identifier to instantiate and present the migration view. Once the view is blocking user interaction the migration can begin. The migrateStore function is called on a background thread. Once migration is complete, the localStore is loaded as usual, the migration view is dismissed, and normal use of the application can resume.
    func migrateStoreWithProgressUI(store:URL, sourceModel:NSManagedObjectModel, destinationModel:NSManagedObjectModel) {

        // Show migration progress view preventing the user from using the app
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let appkeyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        if let initialVC = appkeyWindow?.rootViewController as? UINavigationController {

            if let migrationVC = storyboard.instantiateViewController(withIdentifier: "MigrationVC") as? MigrationVC {

                initialVC.present(migrationVC, animated: false, completion: {
                    DispatchQueue.global(qos: .background).async {
                       print("BACKGROUND Migration started...")
                        self.migrateStore(store: store, sourceModel: sourceModel, destinationModel: destinationModel)
                        DispatchQueue.main.async {
                            print("Main thread started")
                          // trigger the stack setup again, this time with the upgraded store
                           let  _ = CDHelper.shared.localStore
                            DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: 2000000000)) {
                                migrationVC.dismiss(animated: true, completion: nil)
                            }
                        }
                    }})
            } else {print("FAILED to find a view controller with a story board id of 'migration'")}
        } else {print("FAILED to find the root view controller, which is supposed to be a navigation controller")}
    }
    
    ///The final piece of code required in CDMigration.swift is used to migrate the store if necessary. This function is called from the setupCoreData function of CDHelper.swift, which is run as a part of initialization.
    ///
    ///
    ///Once it’s established that the given store exists, a model compatibility check is performed and the store is migrated if necessary. The model used to create the given store is drawn from the store’s metadata. This is then given to the migrateStoreWithProgressUI function.
    func migrateStoreIfNecessary (storeURL:URL, destinationModel:NSManagedObjectModel) {

        if storeExistsAtPath(storeURL: storeURL) == false {
            return
        }

        if store(storeURL: storeURL, isCompatibleWithModel: destinationModel) {
            return
        }

        do {
            var metadata:[String : Any]?
            metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL, options: nil)
            if let metadata = metadata, let sourceModel = NSManagedObjectModel.mergedModel(from: [Bundle.main], forStoreMetadata: metadata) {
                self.migrateStoreWithProgressUI(store: storeURL, sourceModel: sourceModel, destinationModel: destinationModel)
            }
        } catch {
            print("\(#function) FAILED to get metadata \(error)")
        }
    }
}


