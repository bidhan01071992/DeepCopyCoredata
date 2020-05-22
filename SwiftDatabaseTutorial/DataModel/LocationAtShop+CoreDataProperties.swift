//
//  LocationAtShop+CoreDataProperties.swift
//  SwiftDatabaseTutorial
//
//  Created by Roy, Bidhan (623) on 22/05/20.
//  Copyright © 2020 Roy, Bidhan (623). All rights reserved.
//
//

import Foundation
import CoreData


extension LocationAtShop {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocationAtShop> {
        return NSFetchRequest<LocationAtShop>(entityName: "LocationAtShop")
    }

    @NSManaged public var aisle: String?
    @NSManaged public var items: NSSet?

}

// MARK: Generated accessors for items
extension LocationAtShop {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: Item)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: Item)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}
