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
    
    ///Before inserting a new object into the target context, a check needs to be performed to ensure the proposed object doesn’t already exist to prevent duplicates. Because the import is from XML, the only uniqueness indicator to match against is one or more of the target context entity attribute values. For SwiftDatabaseTutorial, this is an easy selection because item name, unit name, location at home storedIn, and location at shop aisle fit the bill nicely. In other applications, email addresses or phone numbers might be more appropriate. In some cases, you may end up needing to add a uniqueness ID to your source and target data.
    ///
    ///Checking for an existing managed object with a specific set of attribute values centers around creating an appropriate predicate.
    ///
    ///
    ///A compound predicate is a set of NSPredicate objects used together. When a compound predicate is created it needs to be of a certain type, either AND, OR, or NOT. The chosen type specifies how the predicates that make up the compound predicate should be used together. The predicateForAttributes function supports all compound predicate types. The following list explains how to create compound predicates:
    ///
    ///To create a compound AND predicate, pass .AndPredicateType as the type. This specifies that all the criteria of all subpredicates must be met. In SQL terms, this is similar to the WHERE clause in the statement SELECT * FROM MyTable WHERE FirstName = 'Bidhan' AND LastName = 'Roy'.
    ///
    ///To create a compound OR predicate, pass .OrPredicateType as the type. This specifies that criteria of at least one of the subpredicates must be met. In SQL terms, this is similar to the WHERE clause in the statement SELECT * FROM MyTable WHERE FirstName = 'Bidhan' OR LastName = 'Roy'.
    ///
    ///To create a compound NOT predicate, pass .NotPredicateType as the type. This specifies that none of the criteria of any subpredicates are allowed to be met. In SQL terms, this is similar to the WHERE clause in the statement SELECT * FROM MyTable WHERE FirstName NOT IN ('Bidhan') AND LastName NOT IN ('Roy').
    
    class func predicateForAttributes (attributes:[String:AnyObject], type:NSCompoundPredicate.LogicalType ) -> NSPredicate? {

        // Create an array of predicates, which will be later combined into a compound predicate.
        var predicates:[NSPredicate]?

        // Iterate unique attributes in order to create a predicate for each
        for (attribute, value) in attributes {

            var predicate:NSPredicate?

            // If the value is a string, create the predicate based on a string value
            if let stringValue = value as? String {
                predicate = NSPredicate(format: "%K == %@", attribute, stringValue)
            }

            // If the value is a number, create the predicate based on a numerical value
            if let numericalValue = value as? NSNumber {
                predicate = NSPredicate(format: "%K == %@", attribute, numericalValue)
            }

            // Append new predicate to predicate array, or create it if it doesn't exist yet
            if let newPredicate = predicate {
                if var _predicates = predicates {
                    _predicates.append(newPredicate)
                } else {predicates = [newPredicate]}
            }
        }

        // Combine all predicates into a compound predicate
        if let _predicates = predicates {
            return NSCompoundPredicate(type: type, subpredicates: _predicates)
        }
        return nil
    }
    
    ///Before inserting a managed object from XML, a check is needed against the target context to ensure that the proposed object does not already exist. To achieve this, a fetch is performed on the target context with a predicate specific to the unique attribute values.
    ///
    ///
    ///The uniqueObjectWithAttributeValuesForEntity function returns the first managed object it finds that matches the specified predicate. An existing objectsForEntity function of CDOperation.swift is leveraged to achieve this. If no matching objects are found, nothing is returned.
    class func uniqueObjectWithAttributeValuesForEntity(entityName:String, context:NSManagedObjectContext, uniqueAttributes:[String:AnyObject]) -> NSManagedObject? {

        let predicate = CDOperation.predicateForAttributes(attributes: uniqueAttributes, type: .and)
        if let objects = CDOperation.objectsForEntity(entityName: entityName, context: context, filters: predicate, sorts: nil)
        {
            if objects.count > 0 {
                if let object = objects[0] as? NSManagedObject {
                    return object
                }
            }
        }
        return nil
    }
    
    ///If the uniqueObjectWithAttributeValuesForEntity function returns nil, the object does not exist in the target context. When importing from XML, this result indicates that a new object with the given unique attribute values is required in the target context. To insert objects, a new function called insertUniqueObject is required
    ///
    ///
    ///The insertUniqueObject function returns an NSManagedObject with its attributes populated from the dictionaries of attribute values given to the function. The insertNewObjectForEntityForName returns an AnyObject object, so the insertUniqueObject function needs to cast this to NSManagedObject. If this cast fails, an error is shown in the console log and a default NSManagedObject is returned. This is an extremely unlikely scenario; however, it must be included for the code to compile.
    
    class func insertUniqueObject(entityName:String, context:NSManagedObjectContext, uniqueAttributes:[String:AnyObject], additionalAttributes:[String:AnyObject]?) -> NSManagedObject {

        // Return existing object after adding the additional attributes.
        if let existingObject = CDOperation.uniqueObjectWithAttributeValuesForEntity(entityName: entityName, context: context, uniqueAttributes: uniqueAttributes) {
            if let _additionalAttributes = additionalAttributes {
                existingObject.setValuesForKeys(_additionalAttributes)
            }
            return existingObject
        }

        // Create object with given attribute value
        let newObject = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
        newObject.setValuesForKeys(uniqueAttributes)
        if let _additionalAttributes = additionalAttributes {
            newObject.setValuesForKeys(_additionalAttributes)
        }
        return newObject
    }

}

