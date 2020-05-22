//
//  Location+CoreDataClass.swift
//  SwiftDatabaseTutorial
//
//  Created by Roy, Bidhan (623) on 22/05/20.
//  Copyright © 2020 Roy, Bidhan (623). All rights reserved.
//
//

import Foundation
import CoreData

@objc(Location)
public class Location: NSManagedObject {
    
    class func locationfetchRequest() ->NSFetchRequest<Location> {
        return fetchRequest()
    }

}
