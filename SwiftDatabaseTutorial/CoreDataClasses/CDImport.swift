//
//  CDImport.swift
//  SwiftDatabaseTutorial
//
//  Created by Roy, Bidhan (623) on 24/05/20.
//  Copyright © 2020 Roy, Bidhan (623). All rights reserved.
//

import Foundation
import CoreData
import UIKit

///When your Core Data application is released, you may want to ship it with some default data. In some cases, default data only serves as an example of how to use an application. In other cases, the application is useless without it.
///
///Before an application imports default data, it’s prudent to check that the import is required and, optionally, that the user wants the default data imported.
///To indicate whether an import is required, a value can be set in a persistent store’s metadata. Each time the application runs, this value can be checked to verify whether an import is required. This technique acts as a safety switch against importing duplicate default data. The first time the application is launched, this value won’t exist and the default data is free to import. The code required to support this functionality is added to a new class specific to importing data into Core Data

private let _sharedCDImport = CDImport()
class CDImport : NSObject, XMLParserDelegate {

    // MARK: - SHARED INSTANCE
    class var shared : CDImport {
        return _sharedCDImport
    }
    
    // MARK: - DATA IMPORT
    ///The isDefaultDataAlreadyImportedForStoreWithURL function has the job of returning true or false when asked whether default data has already been imported for the store at the given URL. It works this out by looking for an existing metadata value for the DefaultDataImported key. If this key doesn’t exist or exists with a false value, the default data import is assumed to be required.
    ///
    ///
    ///The key name DefaultDataImported is an arbitrary (random) name. The key name itself is not important. What is important is that it matches the key name set in the upcoming setDefaultDataAsImportedForStoreWithURL function, which is responsible for marking a store as imported.
    class func isDefaultDataAlreadyImportedForStoreWithURL (url:URL, type:String) -> Bool {

        do {
            var metadata:[String : Any]?
            metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: url, options: nil)
            if let dictionary = metadata {

                if let defaultDataAlreadyImported = dictionary["DefaultDataImported"] as? NSNumber {
                    if defaultDataAlreadyImported.boolValue == false {
                        print("Default Data has not been imported yet")
                        return false
                    } else {
                        print("Default Data import is not required")
                        return true
                    }
                } else {
                    print("Default Data has not been imported yet")
                    return false
                }
            } else {print("\(#function) FAILED to get metadata")}
        } catch {
            print("ERROR getting metadata from \(url) \(error)")
        }
        return true // default to true to prevent a default data import when an error occurs
    }
    
    ///The next function required is checkIfDefaultDataNeedsImporting. This function calls isDefaultDataAlreadyImportedForStoreWithURL as it checks whether an import is required. If an import is required, an alert is shown to the user to double-check that she wants the import to occur. If an import is not required, nothing happens.
    
    func checkIfDefaultDataNeedsImporting (url:URL, type:String) {
        if CDImport.isDefaultDataAlreadyImportedForStoreWithURL(url: url, type: type) == false {

            let alert = UIAlertController(title: "Import Default Data?", message: "If you've never used this application before then some default data might help you understand how to use it. Tap 'Import' to import default data. Tap 'Cancel' to skip the import, especially if you've done this before on your other devices.", preferredStyle: .alert)

            let importButton = UIAlertAction(title: "Import", style: .destructive, handler: { (action) -> Void in
                // Reserved for import code
                // Import data
                //When the import alert is displayed, the user can tap Skip to bypass the import or tap Import to proceed with loading default data. The code required to trigger an import with the Import button can now be added to the checkIfDefaultDataNeedsImporting function.
                if let url = Bundle.main.url(forResource: "preload", withExtension: "xml") {
                    //performBlock is asynchronous, in that it returns immediately, and the block is executed at some time in the future, on some undisclosed thread. All blocks given to the MOC via performBlock will execute in the order they were added.

                    //performBlockAndWait is synchronous, in that the calling thread will wait until the block has executed before returning. Whether the block runs in some other thread, or runs in the calling thread is not all that important, and is an implementation detail that can't be trusted.
                    CDHelper.shared.importContext.perform {
                        print("Attempting preload.xml Import...")
                        self.importFromXML(url: url)
                    }
                } else {print("preload.xml not found")}

                // Set the data as imported
                if let store = CDHelper.shared.localStore {
                    self.setDefaultDataAsImportedForStore(store: store)
                }
            })

            let skipButton = UIAlertAction(title: "Skip", style: .default, handler: { (action) -> Void in

                // Set the data as imported
                if let store = CDHelper.shared.localStore {
                    self.setDefaultDataAsImportedForStore(store: store)
                }
            })
            alert.addAction(importButton)
            alert.addAction(skipButton)

            // PRESENT
            DispatchQueue.main.async {
                let appkeyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
                if let initialVC = appkeyWindow?.rootViewController {
                    initialVC.present(alert, animated: true, completion: nil)
                } else {NSLog("ERROR getting the initial view controller in %@",#function)}
            }
        }
    }
    
    
    // MARK: - XML PARSER
    
    var parser:XMLParser?
    ///Importing data from XML is a technique you can use to generate a persistent store containing default data. Once you have a “default data” persistent store, you can then ship it with your application bundle without the XML file. The advantage with this approach is that the default data will be ready to go instantly because no XML import process is required.
    ///
    ///
    ///Many good XML parsers are available that can be used to create the default data store. Although some of those parsers would give better performance, the NSXMLParser included in the iOS SDK is fit for this purpose. The process to create the default data store isn’t something the user will have to sit through, so performance isn’t an issue.
    ///
    ///A new function called importFromXML will now be implemented that is responsible for configuring the CDImport instance as an XMLParser delegate and then triggering the XML file parse. Once the parse is complete, a notification is sent to ensure that the table views are refreshed with the latest data. There would be no need for this notification if context were a parent of an import context.
    func importFromXML (url:URL) {

        self.parser = XMLParser(contentsOf: url)
        if let _parser = self.parser {
            _parser.delegate = self

            print("START PARSE OF \(url)")
            _parser.parse()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SomethingChanged"), object: nil)
            print("END PARSE OF \(url)")
        }
    }
    
    ////To prevent default data from being imported more than once, a DefaultDataImported metadata key set to true needs to be applied to the persistent store. To do this, the existing metadata dictionary is first taken from the store and the DefaultDataImported key added to it. This process occurs in the setDefaultDataAsImportedForStore function, which can be used for any persistent store
    func setDefaultDataAsImportedForStore (store:NSPersistentStore) {

        if let coordinator = store.persistentStoreCoordinator {
            var metadata = store.metadata
            metadata?["DefaultDataImported"] = NSNumber(value: true)
            coordinator.setMetadata(metadata, for: store)
            print("Store metadata after setDefaultDataAsImportedForStore \(String(describing: store.metadata))")
        }
    }
    
    ///The data import engine that CDImport and CDOperation provide can now be leveraged by the parse results of an XMLParser. All that’s left to do is implement the appropriate delegate functions defined by the XMLParserDelegate protocol, which are as follows:
    ///
    /// The parseErrorOccurred function is used to log any errors that occur during the XML parse, usually from the XMLParserErrorDomain. If you receive errors, they probably are due to a formatting error or invalid character in the XML file.
    ///
    /// The didStartElement function is called every time the parser finds a new element in the given XML file. In the case of SwiftDatabaseTutorial’ default data XML file this is the <Item> element. Every attribute and associated value found within this element is passed to the delegate function as a dictionary. This dictionary is perfect for creating managed objects. If you were to adapt this import technique to your own applications, the didStartElement function is where you need to customize according to your data and model.
    // MARK: - DELEGATE: NSXMLParser
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("ERROR PARSING: \(parseError.localizedDescription)")
    }
    // NOTE: - The code in the didStartElement function is customized for 'SwiftDatabaseTutorial' func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
    ///The didStartElement delegate function is called every time the parser finds a new element in the XML file. If the XML element name is equal to “Item,” the import routine begins. First the managed objects are inserted using the insertUniqueObject function. Once inserted, additional attributes and relationships can be set as per steps 2 and 3 in Listing 8.12. Finally, the context is saved and objects turned into faults to save memory. This whole process is run within performBlockAndWait on the import context so that each item is completely processed before moving on to the next. The main thread is not blocked and the application remains usable during the import only because importContext runs on a private queue.
    ///
    ///

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        let importContext = CDHelper.shared.importContext
        importContext.performAndWait {

            // Process only the 'Item' element in the XML file
            if elementName == "Item" {

                // STEP 1a: Insert a unique 'Item' object
                var item:Item?
                if let itemName = attributeDict["name"] {
                    item = CDOperation.insertUniqueObject(entityName: "Item", context: importContext, uniqueAttributes: ["name":itemName as AnyObject], additionalAttributes: nil) as? Item
                    if let _item = item {_item.name = itemName}
                }

                // STEP 1b: Insert a unique 'Unit' object
                var unit:Unit?
                if let unitName = attributeDict["unit"] {
                    unit = CDOperation.insertUniqueObject(entityName: "Unit", context: importContext, uniqueAttributes: ["name":unitName as AnyObject], additionalAttributes: nil) as? Unit
                    if let _unit = unit {_unit.name = unitName}
                }

                // STEP 1c: Insert a unique 'LocationAtHome' object
                var locationAtHome:LocationAtHome?
                if let storedIn = attributeDict["locationAtHome"] {
                    locationAtHome = CDOperation.insertUniqueObject(entityName: "LocationAtHome", context: importContext, uniqueAttributes: ["storedIn":storedIn as AnyObject], additionalAttributes:nil) as? LocationAtHome
                    if let _locationAtHome = locationAtHome {_locationAtHome.storedIn = storedIn}
                }

                // STEP 1d: Insert a unique 'LocationAtShop' object
                var locationAtShop:LocationAtShop?
                if let aisle = attributeDict["locationAtShop"] {
                    locationAtShop = CDOperation.insertUniqueObject(entityName: "LocationAtShop", context: importContext, uniqueAttributes: ["aisle":aisle as AnyObject], additionalAttributes: nil) as? LocationAtShop
                    if let _locationAtShop = locationAtShop {_locationAtShop.aisle = aisle}
                }

                // STEP 2: Manually add extra attribute values.
                if let _item = item {_item.listed = false}

                // STEP 3: Create relationships
                if let _item = item {

                    _item.unit = unit
                    _item.locationAtHome = locationAtHome
                    _item.locationAtShop = locationAtShop
                }

                // STEP 4: Save new objects to the persistent store.
                CDHelper.save(moc: importContext)

                // STEP 5: Turn objects into faults to save memory
                if let _item = item { importContext.refresh(_item, mergeChanges: false)}
                if let _unit = unit { importContext.refresh(_unit, mergeChanges: false)}
                if let _locationAtHome = locationAtHome { importContext.refresh(_locationAtHome, mergeChanges: false)}
                if let _locationAtShop = locationAtShop { importContext.refresh(_locationAtShop, mergeChanges: false)}
            }
        }
    }
}
