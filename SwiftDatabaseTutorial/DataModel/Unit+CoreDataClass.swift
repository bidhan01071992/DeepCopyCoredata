//
//  Unit+CoreDataClass.swift
//  SwiftDatabaseTutorial
//
//  Created by Roy, Bidhan (623) on 21/05/20.
//  Copyright © 2020 Roy, Bidhan (623). All rights reserved.
//
//

import Foundation
import CoreData

@objc(Unit)
public class Unit: NSManagedObject {
    
    class func fetchUnitRequest() -> NSFetchRequest<Unit> {
        return fetchRequest()
    }
}
