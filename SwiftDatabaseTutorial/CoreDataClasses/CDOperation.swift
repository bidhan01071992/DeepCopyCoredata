//
//  CDOperation.swift
//  SwiftDatabaseTutorial
//
//  Created by Roy, Bidhan (623) on 21/05/20.
//  Copyright © 2020 Roy, Bidhan (623). All rights reserved.
//

import Foundation
import CoreData

class CDOperation {

    /// This class function simply prints the number of objects found for a given entity and context in the console log
    class func objectCountForEntity (entityName:String, context:NSManagedObjectContext) -> Int {

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        
        do {
            let count = try context.count(for: request)
            print("There are \(count) \(entityName) object(s) in \(context)")
            return count
        } catch {
            print("\(#function) Error: \(error.localizedDescription)")
        }
        return 0
    }
    
    ///Fetch the mange objects for an Entity using context, filter, sort
    //TODO make it generic
    class func objectsForEntity(entityName: String, context: NSManagedObjectContext, filters: NSPredicate?, sorts:[NSSortDescriptor]?) -> [AnyObject]? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        if let predicate = filters {
            fetchRequest.predicate = predicate
        }
        if let sort = sorts {
            fetchRequest.sortDescriptors = sort
        }
        
        do {
            if let objects = try context.fetch(fetchRequest) as [AnyObject]? {
                return objects
            }
            
        } catch {
            print("Unable to fetch data with error \(error.localizedDescription)")
        }
        return nil
    }
    
    ///In reality this type of issue would probably come up after a user tries to delete a unit from a table view, at which point you could inform the user of the issue. When a Deny delete rule is in place, you should use a function available from the super class NSManagedObject called validateForDelete. If a call to this function does not throw an error, it’s safe to delete the object in question.
    ///
    ///
    ///The objectName function is used to print out the name of an object, so long as it has a string attribute called name. If no name attribute exists, the built-in description variable of the managed object is used instead. It’s harder to distinguish between managed objects when the built-in description variable is used; however, it’s a good enough fallback when the name attribute doesn’t exist.
    
    class func objectName(object: NSManagedObject) -> String {
        if let name = object.value(forKey: "name") as? String {
            return name
        }
        return object.description
    }
    
    ///this function checks if an object is valid for deletion returning a Boolean value
    class func objectDeletionisValidForObject(object: NSManagedObject) -> Bool {
        do {
            try object.validateForDelete()
            return true
        } catch{
            print("'\(objectName(object: object))' can't be deleted. \(error.localizedDescription)")
            return false
        }
    }

}

