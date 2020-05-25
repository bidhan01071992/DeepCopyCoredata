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
             /*   if let url = Bundle.main.url(forResource: "preload", withExtension: "xml") {
                    //performBlock is asynchronous, in that it returns immediately, and the block is executed at some time in the future, on some undisclosed thread. All blocks given to the MOC via performBlock will execute in the order they were added.

                    //performBlockAndWait is synchronous, in that the calling thread will wait until the block has executed before returning. Whether the block runs in some other thread, or runs in the calling thread is not all that important, and is an implementation detail that can't be trusted.
                    CDHelper.shared.importContext.perform {
                        print("Attempting preload.xml Import...")
                        self.importFromXML(url: url)
                    }
                    
                    
                    
                } else {print("preload.xml not found")}   */
                
                
                //Finally, the triggerDeepCopy function needs to be called instead of importFromXML when the user taps the Import button. This means the checkIfDefaultDataNeedsImporting function needs updating,
                CDHelper.shared.importContext.perform {
                    //print("Attempting DefaultData.xml Import...")
                    //self.importFromXML(url)
                    print("Attempting DefaultData.sqlite Import...")
                    CDImport.triggerDeepCopy(sourceContext: CDHelper.shared.sourceContext, targetContext: CDHelper.shared.importContext, mainContext: CDHelper.shared.context)
                }
                

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
    
    //Mark: DeepCopy
    
    //ENHANCING CDIMPORTER
    //To enable deep copy, the CDImporter class is enhanced to allow the complicated procedure of copying a managed object. The complexity comes from relationship copies, as each relationship must be evaluated to find related objects. The three relationship types (To-One, To-Many, and Ordered To-Many) must also be supported. As complicated as this process can be, by breaking it down into understandable chunks, it should become easier to understand. This breakdown is the reason many functions are required to perform a deep copy.
    
    ///Identifying Unique Attributes
    ///To prevent the creation of duplicate objects, you need to predefine a list of attributes that should be considered unique for an entity.
    ///
    ///
    ///When you apply this approach to your own applications, you need to carefully consider what about each object makes it unique. Examples of unique identifiers are email addresses, product codes, object IDs, and so on.
    ///
    ///The selectedUniqueAttributesForEntity function optionally returns an array of strings. Each string represents an attribute considered unique for the given entity. If multiple unique attributes are specified for an entity, both must be matched for an object to be considered unique.
    class func selectedUniqueAttributesForEntity (entityName:String) -> [String]? {

        // Return an array of attribute names to be considered unique for an entity.
        // Multiple unique attributes are supported.
        // Only use attributes whose values are alphanumeric.

        switch (entityName) {
            case "Item"          :return ["name"]
            case "Unit"          :return ["name"]
            case "LocationAtHome":return ["storedIn"]
            case "LocationAtShop":return ["aisle"]
            default:
                break;
        }
        return nil
    }
    
    ///Object Info
    ///
    ///A new objectInfo function is used to cut down repetitive code otherwise required in most of the upcoming deep copy functions. By passing a managed object to this function, you get back a string containing the object’s entity name, unique attribute, and unique attribute value information.
    
    class func objectInfo (object:NSManagedObject) -> String {

        if let entityName = object.entity.name {

            var attributes:String = ""

            if let uniqueAttributes = CDImport.selectedUniqueAttributesForEntity(entityName: entityName) {

                for attribute in uniqueAttributes {
                    if let valueForKey = object.value(forKey: attribute) as? NSObject {
                        attributes = "\(attributes)\(attribute) \(valueForKey)"
                    }
                }

                // trim trailing space
                attributes = attributes.trimmingCharacters(in: .whitespaces)

                return "\(entityName) with \(attributes)"
            } else {print("ERROR: \(#function) could not find any uniqueAttributes")}
        } else {print("ERROR: \(#function) could not find an entityName")}
        return ""
    }
    
    ///Copying a Unique Object
    ///
    ///
    ///The next function required is copyUniqueObject. This function is responsible for ensuring a unique copy of an object exists in the target context. Technically, this function does not copy a managed object. Instead, it creates a new object in the target context and then copies the attribute values from the source object to the new object. As discussed in the previous chapter, the insertUniqueObject function is used to ensure only unique objects are inserted. If the object already exists, this function just returns the existing object. Note that relationships are not copied in this function because they need to be copied in another way.
    
    class func copyUniqueObject (sourceObject:NSManagedObject, targetContext:NSManagedObjectContext) -> NSManagedObject? {

        if let entityName = sourceObject.entity.name {

            if let uniqueAttributes = CDImport.selectedUniqueAttributesForEntity(entityName: entityName) {

                // PREPARE unique attributes to copy
                var uniqueAttributesFromSource:[String:Any] = [:]
                for uniqueAttribute in uniqueAttributes {
                    uniqueAttributesFromSource[uniqueAttribute] = sourceObject.value(forKey: uniqueAttribute)
                }

                // PREPARE additional attributes to copy
                var additionalAttributesFromSource:[String:Any] = [:]
                let attributesByName:[String:Any?] = sourceObject.entity.attributesByName
                    for (additionalAttribute, _) in attributesByName {
                        additionalAttributesFromSource[additionalAttribute] = sourceObject.value(forKey: additionalAttribute)
                    }

                // COPY attributes to new object
                let copiedObject = CDOperation.insertUniqueObject(entityName: entityName, context: targetContext, uniqueAttributes: uniqueAttributesFromSource, additionalAttributes: additionalAttributesFromSource)

                return copiedObject
            } else {print("ERROR: \(#function) could not find any selected unique attributes for the '\(entityName)' entity")}
        } else {print("ERROR: \(#function) could not find an entity name for the given object '\(sourceObject)'")}
        return nil
    }
    
    ///Establishing a To-One Relationship
    ///The next function required is establishToOneRelationship. This function is responsible for establishing a To-One relationship by name, from one object to another. If the relationship already exists, the relationship creation is skipped.
    ///
    ///
    ///Establishing a To-One relationship requires a single line of code. It is established by setting the value of the relationship’s key-value pair on an object. The relationship name is the key, and the related object is the value. You only need to set a relationship in one direction; the inverse is implied by the managed object model.
    ///
    ///The final part of the establishToOneRelationship function is the important cleanup task that removes references to the specified objects from each context. By calling refreshObject for each object after a context save, the managed objects are faulted. This removes the objects from memory, thus breaking strong reference cycles that would otherwise keep unneeded objects around wasting resources. Without this step, importing from a persistent store would be no better than importing from XML, as all the source data would be loaded in memory. Although it can be resource intensive to call save so frequently, it keeps the memory overhead low. In addition, the process occurs in the background, so it won’t impact the user interface negatively. It will, however, refresh the visible table view cells onscreen.
    
    class func establishToOneRelationship (relationshipName:String,from object:NSManagedObject, to relatedObject:NSManagedObject) {

        // SKIP establishing an existing relationship
        if object.value(forKey: relationshipName) != nil {
            print("SKIPPED \(#function) because the relationship already exists")
            return
        }

        if let targetContext = object.managedObjectContext {

            // ESTABLISH the relationship
            object.setValue(relatedObject, forKey: relationshipName)
            print("    A copy of \(CDImport.objectInfo(object: object)) is related via To-One \(relationshipName) relationship to \(CDImport.objectInfo(object: relatedObject))")

            // REMOVE the relationship from memory after it is committed to disk
            CDHelper.save(moc: targetContext)
            targetContext.refresh(object, mergeChanges: false)
            targetContext.refresh(relatedObject, mergeChanges: false)
        } else {print("ERROR: \(#function) could not get a targetContext")}
    }
    
    ///Establishing a To-Many Relationship
    ///The next function required is establishToManyRelationship, which is responsible for establishing a To-Many relationship from an object. It is expected that the object passed to this function is from the deep copy target context. The given NSMutableSet should contain objects from the source context. The function creates missing objects required as a part of the new relationship in the target context.
    ///
    ///A To-Many relationship is established by adding an object to another object’s NSMutableSet that represents a particular relationship. The NSMutableSet is accessed through the object’s key-value pair. The relationship name is the key, and the NSMutableSet is the value. An NSMutableSet can only contain unique objects, so there is no chance of accidentally duplicating a relationship from the same object.
    
    class func establishToManyRelationship (relationshipName:String,from object:NSManagedObject, sourceSet:NSMutableSet) {

        // SKIP establishing an existing relationship
        if object.value(forKey: relationshipName) != nil {
            print("SKIPPED \(#function) because the relationship already exists")
            return
        }

        if let targetContext = object.managedObjectContext {

            let targetSet = object.mutableSetValue(forKey: relationshipName)

            targetSet.enumerateObjects({ (relatedObject, stop) -> Void in

                if let theRelatedObject = relatedObject as? NSManagedObject {

                    if let copiedRelatedObject = CDImport.copyUniqueObject(sourceObject: theRelatedObject, targetContext: targetContext) {

                        targetSet.add(copiedRelatedObject)
                        print("    A copy of \(CDImport.objectInfo(object: object)) is related via To-Many \(relationshipName) relationship to \(CDImport.objectInfo(object: copiedRelatedObject))")

                        // REMOVE the relationship from memory after it is committed to disk
                        CDHelper.save(moc: targetContext)
                        targetContext.refresh(object, mergeChanges: false)
                        targetContext.refresh(theRelatedObject, mergeChanges: false)
                    } else {print("ERROR: \(#function) could not get a copiedRelatedObject")}
                } else {print("ERROR: \(#function) could not get theRelatedObject")}
            })
        } else {print("ERROR: \(#function) could not get a targetContext")}
    }
    
    ///Establishing an Ordered To-Many Relationship
    ///The next function required is establishOrderedToManyRelationship, which is responsible for establishing an Ordered To-Many relationship from an object. It is expected that the object passed to this function is from the deep copy target context. The given NSMutableOrderedSet should contain objects from the source context. The function creates missing objects required as a part of the new relationship in the target context.
    ///
    ///
    ///An Ordered To-Many relationship is established by adding one object to another object’s NSMutableOrderedSet that represents a particular relationship. The NSMutableOrderedSet is accessed through the object’s key-value pair. The relationship name is the key, and the NSMutableOrderedSet is the value. An NSMutableOrderedSet can only contain unique objects, so there is no chance of accidentally duplicating a relationship from the same object. The order of the set in the target context needs to match the order of the set from the source context. The order of the source set is maintained as the equivalent objects are added to the target object’s ordered set in the order they are found.
    
    class func establishOrderedToManyRelationship (relationshipName:String,from object:NSManagedObject, sourceSet:NSMutableOrderedSet) {

        // SKIP establishing an existing relationship
        if object.value(forKey: relationshipName) != nil {
            print("SKIPPED \(#function) because the relationship already exists")
            return
        }

        if let targetContext = object.managedObjectContext {

            let targetSet = object.mutableOrderedSetValue(forKey: relationshipName)

            targetSet.enumerateObjects { (relatedObject, index, stop) -> Void in

                if let theRelatedObject = relatedObject as? NSManagedObject {

                    if let copiedRelatedObject = CDImport.copyUniqueObject(sourceObject: theRelatedObject, targetContext: targetContext) {

                        targetSet.add(copiedRelatedObject)
                        print("    A copy of \(CDImport.objectInfo(object: object)) is related via Ordered To-Many \(relationshipName) relationship to \(CDImport.objectInfo(object: copiedRelatedObject))'")

                        // REMOVE the relationship from memory after it is committed to disk
                        CDHelper.save(moc: targetContext)
                        targetContext.refresh(object, mergeChanges: false)
                        targetContext.refresh(theRelatedObject, mergeChanges: false)
                    } else {print("ERROR: \(#function) could not get a copiedRelatedObject")}
                } else {print("ERROR: \(#function) could not get theRelatedObject")}
            }
        } else {print("ERROR: \(#function) could not get a targetContext")}
    }
    
    ///Copying Relationships
    ///The next function required is copyRelationshipsFromObject, which is responsible for copying all relationships from an object in the source context to an equivalent object in the target context. This function is what the other functions implemented so far have been building up to.
    ///
    ///
    ///The first task this function performs is to ensure there is an equivalent object in the target context. Referred to as the copiedObject, this object is created as required using the previously implemented copyUniqueObject function. If it still doesn’t exist after a copy is attempted, this function returns prematurely.
    ///
    ///To copy relationships, the function works out what relationships exist on the source object using sourceObject.entity.relationshipsByName. This dictionary is then iterated to find valid relationships. Provided the relationship exists, the equivalent relationship is recreated from the copiedObject. Before copying a relationship, its type is first determined. For To-Many or Ordered To-Many relationships, the appropriate source set is passed to the appropriate “copy To-Many” function. For a To-One relationship, the object to be related is copied to the target context before the appropriate function is called to establish the relationship.
    
    class func copyRelationshipsFromObject(sourceObject:NSManagedObject, to targetContext:NSManagedObjectContext) {

        if let copiedObject = CDImport.copyUniqueObject(sourceObject: sourceObject, targetContext: targetContext) {

            let relationships = sourceObject.entity.relationshipsByName // [String : NSRelationshipDescription]

            for (_, relationship) in relationships {

                if relationship.isToMany && relationship.isOrdered {

                    // COPY To-Many Ordered Relationship
                    let sourceSet = sourceObject.mutableOrderedSetValue(forKey: relationship.name)
                    CDImport.establishOrderedToManyRelationship(relationshipName: relationship.name, from: copiedObject, sourceSet: sourceSet)

                } else if relationship.isToMany && relationship.isOrdered == false {

                    // COPY To-Many Relationship
                    let sourceSet = sourceObject.mutableSetValue(forKey: relationship.name)
                    CDImport.establishToManyRelationship(relationshipName: relationship.name, from: copiedObject, sourceSet: sourceSet)

                } else {

                    // COPY To-One Relationship
                    if let relatedSourceObject = sourceObject.value(forKey: relationship.name) as? NSManagedObject {

                        if let relatedCopiedObject = CDImport.copyUniqueObject(sourceObject: relatedSourceObject, targetContext: targetContext) {

                            CDImport.establishToOneRelationship(relationshipName: relationship.name, from:copiedObject, to: relatedCopiedObject)

                        } else {print("ERROR: \(#function) could not get a relatedCopiedObject")}
                    } else {print("ERROR: \(#function) could not get a relatedSourceObject")}
                }
            }
        } else {print("ERROR: \(#function) could not find or create an object to copy relationships to.")}
    }
    
    
    ///Deep Copy Entities
    ///The next function required is deepCopyEntities, which is responsible for copying all objects from the specified entities in one context to another context. There are several ways this function could be implemented, and the user experience would differ with each option. If you search the Internet for “core data programming guide: efficiently importing data,” you should find an Apple guide that discusses techniques for importing data. It says that when possible it is more efficient to copy all the objects in a single pass and then fix up relationships later. Depending on the application, this may not be feasible. An import can take a long time, and if the relationships are missing even for a few seconds, the user might assume the application has a bug. The options open to you to combat this issue are as follows (your selection varies depending on the nature of your application):
    ///
    ///
    ///Prevent the user from using the application, partially or wholly. During the import, you could display a progress indicator. If the import takes a long time, this may annoy the user. Depending on the application, you may instead only disable partial functionality, until the data is ready.
    ///
    /// Import all objects first and then establish relationships. The user might see half-imported data with little or no established relationships. Depending on the data model, this may or may not be acceptable. Consider prioritizing the order the entities are imported to make this option more palatable.
    ///
    /// Import objects and relationships together. Although this is certainly not as efficient as the other options, the entire deep copy process is run in the background so the user impact is minimal to nonexistent. This is a more resource intensive task than the alternative; however, the application remains usable.
    ///
    ///CDImporter is configured to import objects and relationships together and a notification is sent each time an entity finishes processing. This ensures that table views relying on relationships for their sections are updated appropriately.
    
    class func deepCopyEntities(entities:[String], from sourceContext:NSManagedObjectContext, to targetContext:NSManagedObjectContext) {

        for entityName in entities {
            print("DEEP COPYING '\(entityName)' objects to target context...")
            if let sourceObjects = CDOperation.objectsForEntity(entityName: entityName, context: sourceContext, filters: nil, sorts: nil) as? [NSManagedObject] {

                for sourceObject in sourceObjects {
                    print("DEEP COPYING OBJECT: \(CDImport.objectInfo(object: sourceObject))")
                    _ = CDImport.copyUniqueObject(sourceObject: sourceObject, targetContext: targetContext)
                    CDImport.copyRelationshipsFromObject(sourceObject: sourceObject, to: targetContext)
                }
            } else {print("ERROR: \(#function) could not find any sourceObjects")}
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SomethingChanged"), object: nil)
        }
    }
    
    ///TRIGGERING A DEEP COPY
    ///As mentioned at the beginning of this chapter, a deep copy is demonstrated using the existing default data store. The default data store DefaultData.sqlite was previously configured as the initial store during setupCoreData via setDefaultDataStoreAsInitialStore. This function call has since been commented out, so on new installations an import from XML would be triggered instead. This is due to the call to checkIfDefaultDataNeedsImporting in the setupCoreData function that triggers an alert giving the option to import with importFromXML. To trigger a deep copy from a persistent store instead, a new function called triggerDeepCopy is required in CDImporter.swift.
    ///
    ///
    ///The triggerDeepCopy function calls deepCopyEntities using performBlock. This has the effect of performing the deep copy in the background because sourceContext has a private queue concurrency type. When the copy is finished a final interface refresh is triggered via a notification.
    
    class func triggerDeepCopy (sourceContext:NSManagedObjectContext, targetContext:NSManagedObjectContext, mainContext:NSManagedObjectContext) {

        sourceContext.perform {

            CDImport.deepCopyEntities(entities: ["Item","Unit","LocationAtHome", "LocationAtShop"], from: sourceContext, to: targetContext)

            mainContext.perform {
                // Trigger interface refresh
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SomethingChanged"), object: nil)
            }
            print("*** FINISHED DEEP COPY FROM DEFAULT DATA PERSISTENT STORE ***")
        }
    }
}
