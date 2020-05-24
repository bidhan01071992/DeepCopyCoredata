//
//  AppDelegate.swift
//  SwiftDatabaseTutorial
//
//  Created by Roy, Bidhan (623) on 20/05/20.
//  Copyright © 2020 Roy, Bidhan (623). All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    ///CREATING A MANAGED OBJECT
    ///Everything is now in place to create some new managed objects. New objects are based off the NSEntityDescription class of a particular entity, specified by name. In addition to specifying the entity to base an object on, you also need to provide a pointer to a managed object context where the new managed object goes. Access to a shared context is now available from anywhere in the application through the CDHelper.shared.context variable.

    ///The code  demonstrates how to insert a new managed object based on an entity into a context. Inserting a new managed object is as simple as calling the insertNewObjectForEntityForName function of the NSEntityDescription class and then passing it an appropriate entity name and context pointer.

    ///Once a new Item-based managed object is created, you can then manipulate its values directly in code. The print command at the end  demonstrates this when item.name is passed in as a string variable. The dot notation shown is a particularly clean way of working with objects because it makes your code easier to read.
    func insertDemo() {
        let demoItemNames = ["Apple", "Banana","Orange","Mango","Peas"]
        
        for itemName in demoItemNames {
            if let item: Item = NSEntityDescription.insertNewObject(forEntityName: "Item", into: CDHelper.shared.context) as? Item {
                item.name = itemName;
                print("Inserted New Managed Object for '\(item.name!)'")
            }
        }
        
        CDHelper.saveSharedContext()
    }
    
    ///FETCHING MANAGED OBJECTS
    ///To work with existing data from a managed object context, you first need to fetch it. If the data isn’t already in a context when fetched, it is retrieved from the underlying persistent store transparently. To fetch, you need an instance of NSFetchRequest, which returns an array of managed objects. When the fetch is executed, every managed object for the specified entity is returned in the resulting array. In SQL database terms, a fetch is similar to a SELECT statement.
    ///
    ///
    ///Sorting Fetch Requests
    ///An NSFetchRequest returns an array, which by nature supports being sorted. As such, you may optionally configure an NSFetchRequest with a sort descriptor configured to order managed objects in a certain way. Sort descriptors are passed to an NSFetchRequest as instance(s) of NSSortDescriptor in an array. An array is used so you can sort by multiple attributes. In SQL database terms, a sort descriptor is similar to an ORDER BY statement.
    ///
    ///
    ///Filtering Fetch Requests
    ///When you don’t want to fetch every object for an entity, you can filter fetches using a predicate. A predicate is defined for a fetch request using an instance of NSPredicate and then passing that to an instance of NSFetchRequest. Using a predicate limits the number of objects in the fetch results based on the criteria specified. Predicates are persistent store agnostic, so you can use the same predicates regardless of the backend store. That said, there are some corner cases where particular predicates won’t work with certain stores. For example, the matches operator works with in-memory filtering; however, it does not work with an SQLite store. In SQL database terms, a predicate is similar to a WHERE clause.
    ///
    ///
    ///A predicate is evaluated against each potential managed object as a part of fetch execution. The predicate evaluation result is a Boolean value. If true, the predicate criteria are satisfied and the managed object is part of the fetched results. If false, the predicate criteria are not satisfied and the managed object is not part of the fetched results.
    func fetchDemo() {
        let request = Item.itemFetchRequest()
        let sort = NSSortDescriptor(key: "name", ascending: true)
        request.sortDescriptors = [sort]
        
        let filter = NSPredicate(format: "name != %@","Apple")
        request.predicate = filter
        do {
             let items = try CDHelper.shared.context.fetch(request)
                for item in items {
                    print(item.name as Any)
                }
            } catch {
                print("Unable to fetch with error \(error.localizedDescription)")
            }
    }
    
    ///Fetch Request Templates
    ///Determining the correct predicate format to use for every fetch can become laborious. Thankfully, the Xcode Data Model Designer supports predefining fetch requests. These reusable templates are easier to configure than predicates and they reduce repeated code. Fetch request templates are configured using a series of drop-down boxes and fields specific to the application’s model. Unfortunately, given their simplicity they aren’t as powerful as predicates. If you need features such as custom AND/OR combinations, you have to revert to predicate programming.

    ///Update SwiftDatabaseTutorial as follows to create a fetch request template:

    ///1. Select Model.xcdatamodeld.

    ///2. Click Editor > Add Fetch Request.

    ///3. Set the name of the fetch request template to Test.

    ///4. Click the + on the far right side; then configure the Test fetch request template to fetch all Item objects that have a name attribute that contains the letter “e”
    
    func fetchRequestTemplate() {
        let model = CDHelper.shared.model
        if let template = model.fetchRequestTemplate(forName: "Test"), let request = template.copy() as? NSFetchRequest<Item> {
            
            let sort = NSSortDescriptor(key: "name", ascending: true)
            request.sortDescriptors = [sort]
            do {
                let items = try CDHelper.shared.context.fetch(request)
                for item in items {
                    print("Templatew item - \(String(describing: item.name))")
                }
            }catch {
                print("Unable to fetch template with error \(error.localizedDescription)")
            }
            
        }
    }
    
    ///DELETING MANAGED OBJECTS
    ///
    ///
    ///Deleting a managed object is as easy as calling deleteObject or deleteObjects on a containing context. Note that deletion isn’t permanent until you save the context.
    func demoDeleteObjects() {
        let context = CDHelper.shared.context
        let request = Item.itemFetchRequest()
        do {
            let items = try context.fetch(request)
            for item in items {
                if item.name == "Mango" {
                    context.delete(item)
                }
            }
        }catch {
            print("Error while fetching data")
        }
        CDHelper.saveSharedContext()
    }
    
    ///This method is  demo to show why we shouldn't entry large amount of data using main thread context. It blocks the UI. Best way to do so is using a background queue context.
    func demoInsertMeasurement() {
        
        for index in 1...6000 {
            if let amountEntity : Amount = NSEntityDescription.insertNewObject(forEntityName: "Amount", into: CDHelper.shared.context) as? Amount {
                amountEntity.xyz = "Lots of data value \(index)"
                print("Measurement data inserted")
            }
        }
        CDHelper.saveSharedContext()
    }
    
    ///In this function we will use fetchlimit to fetch 50 records from measurement table
    func demoFetchMeasurement() {
        let context = CDHelper.shared.context
        let request = Amount.amountFetchRequest()
        request.fetchLimit = 50;
        do {
            let amounts = try context.fetch(request)
            for amount in amounts {
                print(amount.xyz as Any)
            }
        } catch {
            print("Error while fetching measurement data \(error.localizedDescription)")
        }
    }
    
    ///In this function we will fetch data from Unit entity
    func demoFetchUnit() {
        let context = CDHelper.shared.context
        let request = Unit.fetchUnitRequest()
        do {
            let units = try context.fetch(request)
            for unit in units {
                print("Unit Data - \(String(describing: unit.name))")
            }
        } catch {
            print("Error while fetch data from Unit entity \(error.localizedDescription)")
        }
    }
    
    ///Relationship data entry
    ///
    ///In this method some items will be inserter along with its units in Unit entity
    func demoItemUnitRelationShipDataEntry() {
        let context = CDHelper.shared.context
        if let orange = NSEntityDescription.insertNewObject(forEntityName: "Item", into: context) as? Item,
            let banana = NSEntityDescription.insertNewObject(forEntityName: "Item", into: context) as? Item,
            let kg = NSEntityDescription.insertNewObject(forEntityName: "Unit", into: context) as? Unit {
            kg.name = "KG / Kilogram"
            banana.name = "Banana"
            banana.quantity = 2.5
            banana.listed = true
            banana.unit = kg
            
            orange.name = "Orange"
            orange.quantity = 2
            orange.unit = kg
            orange.listed = true
            
            print("Inserted \(orange.quantity)\(orange.unit!.name!) of \(orange.name!)")
            print("Inserted \(banana.quantity)\(banana.unit!.name!) of \(banana.name!)")
            CDHelper.saveSharedContext()
        }
    }
    
    ///Fetch number of items, Units by calling objectCountForEntity method in CDOperation class
    ///
    ///
    ///The expected result shows there are two item objects and one unit object in the context. The two item objects are oranges and bananas. Which were inserted in demoItemUnitRelationShipDataEntry, the only unit object is Kg, which both items are related to.
    func demoDeleteUnitswithDenyDeleteRule() {
        let context = CDHelper.shared.context
        //Before Delete fetch the quantities of data
        _ = CDOperation.objectCountForEntity(entityName: "Item", context: context)
        _ = CDOperation.objectCountForEntity(entityName: "Unit", context: context)
        
        //call objectsForEntity method inorder to first fetch the data from table to delete that
        //we will fetch the unit MOM where value is kg
        
        let predicate = NSPredicate(format: "name == %@", "KG / Kilogram")
        if let units = CDOperation.objectsForEntity(entityName: "Unit", context: context, filters: predicate, sorts: nil) as? [Unit] {
            for unit in units {
                if CDOperation.objectDeletionisValidForObject(object: unit) {
                   context.delete(unit)
                }
                
            }
            /// Deny delete rule in place testing that
            //1.2Save the context the display the changes in persistent store from context
            //It will throw error as Deny delete rule is in place.
            //delete rule is only enforced when it comes time to save the context
            //Even though the save fails, the context still reports that the unit object has been deleted and the delete rule generates an NSCocoaErrorDomain error 1600. This error is an NSValidationRelationshipDeniedDeleteError. To get around it, you need to check that the unit object can be safely deleted before deleting it.
            CDHelper.saveSharedContext()
        }
        print("Deletion complete")
        //After Delete fetch the quantities of data
        //
        //1.1Upon examining the console log, it appears that the Deny delete rule hasn’t worked. What’s going on here? Why are there no units anymore? Shouldn’t the Deny rule have prevented the Kg unit object from being deleted because oranges and bananas are related to it?
        _ = CDOperation.objectCountForEntity(entityName: "Item", context: context)
        _ = CDOperation.objectCountForEntity(entityName: "Unit", context: context)
    }
    
    //Nullify will nil the unit in Item entity
    //Cascade will delete all the items in Item entity
    //NoAction will just delete the unit and unit will be there in Item entity as Dangling pointer
    //TODO - Task check all other delete rules by writting different methods
    
    ///Insert code to insert data in item with their location at shop and location at home
    ///
    ///
    ///Delete rule is now nullify
    func demoInsertIntemswithLocation() {
        let context = CDHelper.shared.context
        if let mango = NSEntityDescription.insertNewObject(forEntityName: "Item", into: context) as? Item,
            let locationAtHome = NSEntityDescription.insertNewObject(forEntityName: "LocationAtHome", into: context) as? LocationAtHome,
            let locationAtShop = NSEntityDescription.insertNewObject(forEntityName: "LocationAtShop", into: context) as? LocationAtShop {
            locationAtHome.storedIn = "Kitchen"
            locationAtShop.aisle = "4th"
            locationAtHome.summary = "Check 4th self in kitchen"
            locationAtShop.summary = "in the the supermarket shop"
            mango.name = "Mango"
            mango.collected = true
            mango.listed = true
            mango.quantity = 7.5
            mango.locationAtHome = locationAtHome
            mango.locationAtShop = locationAtShop
            do {
                let unitRequest = Unit.fetchUnitRequest()
                let filter = NSPredicate(format: "name == %@", "KG / Kilogram")
                unitRequest.predicate = filter
                let kgUnit = try context.fetch(unitRequest).last
                mango.unit = kgUnit
            } catch {
                print("unable to filter fetch from unit entity fro KG element")
            }
            print("A new element inserted with name \(String(describing: mango.name)) of quantity \(mango.quantity) \(String(describing: mango.unit?.name)) its there in \(String(describing: mango.locationAtHome?.storedIn)) - \(String(describing: mango.locationAtHome?.summary)), it's also available in \(String(describing: mango.locationAtShop?.aisle)) aisle \(String(describing: mango.locationAtShop?.summary))")
            CDHelper.saveSharedContext()
        }
    }
    
    ///Test method to delete the entry made from demoInsertIntemswithLocation
    ///
    ///
    ///We will first make the delete rule as nullify in locationathome and locationatshop relationships
    ///Then we will check this method
    ///
    ///Expected result mango object locationAtShop relation will be null
    func deletelocationData() {
        let context = CDHelper.shared.context
        let locationRequest = Location.locationfetchRequest()
        let predicate = NSPredicate(format: "aisle == %@", "4th")
        locationRequest.predicate = predicate
        do {
            let locations = try context.fetch(locationRequest)
            for location in locations {
                context.delete(location)
            }
        } catch {
            print("Unable to fetch location data")
        }
        CDHelper.saveSharedContext()
    }
    
    ///Test method to delete the entry made from demoInsertIntemswithLocation
    ///
    ///
    ///We will first make the delete rule as nullify in locationathome and locationatshop relationships
    ///Then we will check this method
    ///Will revert the delete rule to nillify again
    ///
    ///
    ///expected result mango object will be deleted along with location object
    func deletelocationDatawithCascadeDeleteRule() {
        let context = CDHelper.shared.context
        let locationRequest = Location.locationfetchRequest()
        let predicate = NSPredicate(format: "storedIn == %@", "Kitchen")
        locationRequest.predicate = predicate
        do {
            let locations = try context.fetch(locationRequest)
            for location in locations {
                context.delete(location)
            }
        } catch {
            print("Unable to fetch location data")
        }
        CDHelper.saveSharedContext()
    }
    
    //MARK: Appdelegate methods

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //test purpose
//        _ = CDHelper.shared
//        insertDemo()
//        demoDeleteObjects()
//        fetchDemo()
//        fetchRequestTemplate()
//        demoInsertMeasurement()
//        demoFetchMeasurement()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        CDHelper.saveSharedContext()
    }


}

