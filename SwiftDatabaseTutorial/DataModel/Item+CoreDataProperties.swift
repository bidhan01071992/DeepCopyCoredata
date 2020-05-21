//
//  Item+CoreDataProperties.swift
//  SwiftDatabaseTutorial
//
//  Created by Roy, Bidhan (623) on 20/05/20.
//  Copyright © 2020 Roy, Bidhan (623). All rights reserved.
//
//

import Foundation
import CoreData


extension Item {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Item> {
        return NSFetchRequest<Item>(entityName: "Item")
    }

    @NSManaged public var name: String?
    @NSManaged public var quantity: Float
    @NSManaged public var photoData: Data?
    @NSManaged public var listed: Bool
    @NSManaged public var collected: Bool

}
