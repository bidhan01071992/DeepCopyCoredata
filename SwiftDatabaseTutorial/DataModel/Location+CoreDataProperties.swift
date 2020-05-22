//
//  Location+CoreDataProperties.swift
//  SwiftDatabaseTutorial
//
//  Created by Roy, Bidhan (623) on 22/05/20.
//  Copyright © 2020 Roy, Bidhan (623). All rights reserved.
//
//

import Foundation
import CoreData


extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var summary: String?

}
