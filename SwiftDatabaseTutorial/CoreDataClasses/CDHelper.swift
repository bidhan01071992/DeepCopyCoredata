//
//  CDHelper.swift
//  SwiftDatabaseTutorial
//
//  Created by Roy, Bidhan (623) on 20/05/20.
//  Copyright © 2020 Roy, Bidhan (623). All rights reserved.
//

import Foundation
import CoreData

private let _sharedCDHelper = CDHelper()
class CDHelper : NSObject  {

    // MARK: - SHARED INSTANCE
    ///The CDHelper.swift class starts out by importing the CoreData Framework so that it has access to the Core Data classes it will leverage. It also supports a shared instance, which makes using this class easier and reduces code.
    ///The singleton pattern used in Core Data Helper to simplify its use and to centralize data management.
    class var shared : CDHelper {
        return _sharedCDHelper
    }
    
    //MARK: Adding Paths
    ///For Core Data to function correctly it needs to know where the model and store files are located. The paths to these files should be provided by a modelURL and localStoreURL variable. Another variable called storesDirectory should also be added, which makes up part of the localStoreURL and is reused later for other stores. Listing 1.2 shows the code involved, which uses lazy variables whose values aren’t calculated until they’re needed.
    ///to use forSecurityApplicationGroupIdentifier first create appgroups then create a container
    
    lazy var storesDirectory: URL? = {
        let fm = FileManager.default
        let url = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.com.daimler.dataBaseContainer")
        return url
    }()
    
    lazy var localStoreURL: URL? = {
        
        if let url = self.storesDirectory?.appendingPathComponent("LocalStore.sqlite") {
            print("localStoreURL = \(url)")
            return url
        }
        return nil
    }()
    
    ///Configuring the Source Store for deep copy
    ///The same approach used to configure the existing store is used again to configure the source store. This means a variable that returns a URL to the source store is first required.
    ///Copy LocalStore.sqlite to the desktop and rename it to DefaultData.sqlite.
    ///
    ///
    ///Drag DefaultData.sqlite from your desktop into the Data Model group in Xcode. Ensure Copy items if needed and the target are checked before clicking Finish.
    
    lazy var sourceStoreURL: URL? = {
        if let url = Bundle.main.url(forResource: "DefaultData", withExtension: "sqlite") {
            print("sourceStoreURL = \(url)")
            return url
        }
        return nil
    }()
    
    
    lazy var modelURL: URL = {
        let bundle = Bundle.main

        if let url = bundle.url(forResource: "Model", withExtension: "momd") {
            return url
        }
        print("CRITICAL - Managed Object Model file not found")
        abort()
    }()
    
    //MARK: Adding the Core Data Stack
    ///With the paths in place the Core Data Stack can now be set up. The Core Data Stack is made up of the following components:
    ///Image The Managed Object Context, also known as the Context
    ///Image The Managed Object Model, also known as the Model
    ///Image The Persistent Store Coordinator, also known as the Coordinator
    ///Image The Persistent Store, also known as the Store
    ///Each part of the Core Data Stack is provided through the variables context, model, coordinator, and localStore.
    
    ///The context variable returns an instance of NSManagedObjectContext attached to the coordinator. It is initialized with an instance of MainQueueConcurrencyType that tells it to run on a “main thread” queue. You must have at least one context running on the main thread when you have a data-driven user interface
    lazy var context: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        moc.persistentStoreCoordinator = self.coordinator
        return moc
    }()
    
    ///Configuring the Source Context for deep copy
    lazy var sourceContext: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType:.privateQueueConcurrencyType)
        moc.persistentStoreCoordinator = self.sourceCoordinator
        return moc
    }()
    
    
    ///When importing data, you should use a managed object context that does not run on the main thread. It is recommended that you use a context existing solely for importing data. This ensures there’s no chance it will block the queue of another context—most importantly, the main queue context. An import context can use the same persistent store coordinator as another context.

    ///The import context is implemented in the same way as the foreground context; however, it will have a different concurrency type. You have three concurrency types to choose from when configuring an NSManagedObjectContext:
    /// MainQueueConcurrencyType should be used when you want the context to operate on the main thread. Any heavy work performed in this queue may slow down or even freeze the user interface. You need at least one context working in the foreground to update user interface elements.
    ///PrivateQueueConcurrencyType should be used when you don’t want the context to operate on the main thread. This is an ideal concurrency type for potentially heavy work, such as saving or importing data. Any context with a PrivateQueueConcurrencyType should only be sent messages using performBlock or performBlockAndWait. Use performBlockAndWait if you need the block to return before continuing; otherwise, use performBlock. If you call performBlockAndWait on a context running on the main thread, it blocks the main thread.
    ///ConfinementConcurrencyType is a deprecated option, which you should avoid. This legacy option required you to have a separate context for every thread and a managed object context could only be used on the thread or queue that created it.
    
    lazy var importContext: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType:.privateQueueConcurrencyType)
        moc.persistentStoreCoordinator = self.coordinator
        return moc
    }()
    
    

    // MARK: - MODEL
    ///The model variable returns an instance of NSManagedObjectModel. It is initialized based on the path to the model file. If a model file is not found, the application terminates.
    lazy var model: NSManagedObjectModel = {
        return NSManagedObjectModel(contentsOf:self.modelURL)!
    }()

    // MARK: - COORDINATOR
    ///The coordinator variable returns an instance of NSPersistentStoreCoordinator. It is initialized based on the model.
    lazy var coordinator: NSPersistentStoreCoordinator = {
        return NSPersistentStoreCoordinator(managedObjectModel:self.model)
    }()
    ///Configuring the Source Coordinator for deep copy it is same as existing coordinator
    lazy var sourceCoordinator:NSPersistentStoreCoordinator = {
        return NSPersistentStoreCoordinator(managedObjectModel:self.model)
    }()

    // MARK: - STORE
    ///The localStore variable optionally returns an instance of NSPersistentStore. Before a persistent store can be returned it must be added to the coordinator. A call to addPersistentStoreWithType is made based on the URL to the store file and an options dictionary with a special journal_mode of DELETE. This journal mode is used throughout the book so you can inspect the contents of the underlying database. There is otherwise no need to use this journal mode. If the call to addPersistentStoreWithType throws an error, a do-catch statement catches this and a nil store is returned. This should occur only in cases where a manual model migration is required
    ///
    ///
    ///
    ///When the NSMigratePersistentStoresAutomaticallyOption is true (1) and passed to a persistent store coordinator, Core Data automatically attempts to migrate incompatible persistent stores to the current model.
    ///
    ///
    ///When the NSInferMappingModelAutomaticallyOption is true (1) and passed to a persistent store coordinator, Core Data automatically attempts to infer a best guess at what attributes from the source model entities should end up as attributes in the destination model entities.
    ///
    ///
    ///When the persistent store option NSInferMappingModelAutomaticallyOption is true (1), Core Data still checks to see whether there are any model-mapping files it should use before trying to infer automatically. It is recommended that you disable this setting while you’re testing a mapping model. This way, you can be certain that the mapping model is being used and is functioning correctly.
    lazy var localStore: NSPersistentStore? = {
        //TODO - understand
        
        // Don't return a store if it's not compatible with the model
        ///Currently the localStore variable of CDHelper.swift always tries to return a store. If it tried to return a store that wasn’t compatible with the current model, the application would throw an error. To prevent this, a check is needed to see whether the store needs migrating before it is loaded. This check is needed only when migration is handled manually
        ///
        ///
        ///Make true if you want to make manual migration
        let useMigrationManager = false
        if let _localStoreURL = self.localStoreURL {
            if useMigrationManager == true &&
                CDMigration.shared.storeExistsAtPath(storeURL: _localStoreURL) &&
                CDMigration.shared.store(storeURL: _localStoreURL, isCompatibleWithModel: self.model) == false {
                return nil
            }
        }
        
        let options: [String : Any] = [NSSQLitePragmasOption : ["journal_mode":"DELETE"],
        NSMigratePersistentStoresAutomaticallyOption:1,
        NSInferMappingModelAutomaticallyOption:1]
        var _localStore:NSPersistentStore?
        do {
            _localStore = try self.coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: self.localStoreURL, options: options)
            return _localStore
        } catch {
            return nil
        }
    }()
    ///Configurimg the store for deep copy
    ///
    ///
    ///The next step is to implement the sourceStore variable. This variable is responsible for adding the source store to the source coordinator. Because the source store lives in the application bundle, it must be loaded as read-only. This means that if the model is upgraded in the future, you need to ship a pre-upgraded version of DefaultData.sqlite with it.
    
    lazy var sourceStore: NSPersistentStore? = {

        let options:[AnyHashable:Any] = [NSReadOnlyPersistentStoreOption:1]

        var _sourceStore:NSPersistentStore?
        do {
            _sourceStore = try self.sourceCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: self.sourceStoreURL, options: options)
            return _sourceStore
        } catch {
            return nil
        }
    }()
    
    //MARK: Adding the Setup Section
    ///With the Core Data Stack ready to go it’s time to implement the functions responsible for its initial setup.
    ///The init function runs when an instance of CDHelper is created.
    required override init() {
        super.init()
        self.setupCoreData()
    }
    ///It creates a constant pointing to self.localStore. Creating this constant starts the chain of events that instantiates the Core Data Stack.
    func setupCoreData() {
        
        // Model Migration
        if let _localStoreURL = self.localStoreURL {
            CDMigration.shared.migrateStoreIfNecessary(storeURL: _localStoreURL, destinationModel: self.model)
        }
        //For deep copy
        _ = self.sourceStore
        _ = self.localStore
        
        //This triggers a test of the localStore to see whether it needs to import default data.
        if let _localStoreURL = self.localStoreURL {
            CDImport.shared.checkIfDefaultDataNeedsImporting(url: _localStoreURL, type:
        NSSQLiteStoreType)
        } else {print("ERROR getting localStoreURL in \(#function)")}
    }
    
    //MARK: Adding the Saving Section
    ///To prevent data loss, you’ll eventually want to save the contents of the context to its persistent store. This is as easy as sending the context a save() message,
    
    ///Everything is executed within performBlockAndWait to ensure that the contexts are saved on an appropriate thread and in order. The first thing the save class function does is check for unsaved changes. If they exist, the given context is saved. If the context has a parent context, it is saved too. Parent contexts are used for background saving
    class func save(moc:NSManagedObjectContext) {
        //////What if you call those methods from some other queue? If code is executing on some other queue, it can call perform or performBlockAndWait on a managed object context that uses main queue concurrency. The code in that closure executes on the main queue even though the calling code is not on the main queue.
        moc.performAndWait {
            
            if moc.hasChanges {

                do {
                    try moc.save()
                    print("SAVED context \(moc.description)")
                } catch {
                    print("ERROR saving context \(moc.description) - \(error)")
                }
            } else {
                print("SKIPPED saving context \(moc.description) because there are no changes")
            }
            if let parentContext = moc.parent {
                save(moc: parentContext)
            }
        }
    }
    ///The saveSharedContext class function exists only to make using CDHelper.swift easier and the code tidier.
    class func saveSharedContext() {
        save(moc: shared.context)
    }
}
