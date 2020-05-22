//
//  Item+CoreDataProperties.swift
//  SwiftDatabaseTutorial
//
//  Created by Roy, Bidhan (623) on 22/05/20.
//  Copyright © 2020 Roy, Bidhan (623). All rights reserved.
//
//

import Foundation
import CoreData


extension Item {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Item> {
        return NSFetchRequest<Item>(entityName: "Item")
    }

    @NSManaged public var collected: Bool
    @NSManaged public var listed: Bool
    @NSManaged public var name: String?
    @NSManaged public var photoData: Data?
    @NSManaged public var quantity: Float
    @NSManaged public var locationAtShop: LocationAtShop?
    @NSManaged public var locationAtHome: LocationAtHome?
    @NSManaged public var unit: Unit?

}
