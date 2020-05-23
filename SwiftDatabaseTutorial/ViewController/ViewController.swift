//
//  ViewController.swift
//  SwiftDatabaseTutorial
//
//  Created by Roy, Bidhan (623) on 20/05/20.
//  Copyright © 2020 Roy, Bidhan (623). All rights reserved.
//

import UIKit
import CoreData

///ViewController
///
///
///Reporting on the progress of a migration is useful for keeping the user informed (and less annoyed) about a slow launch. Although most migrations should be fast, some large databases requiring complex changes can take a while to migrate. To keep the user interface responsive, the migration must be performed on a background thread. At the same time, the user interface has to be responsive to provide updates to the user. The challenge is to prevent the user from attempting to use the application during the migration. This is because the data won’t be ready yet, so you don’t want the user staring at a blank screen wondering what’s going on. This is where a migration progress view comes into play.


class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        ///Demo insert data to show in tableview
        
        let context = CDHelper.shared.context

        let homeLocations = ["Fruit Bowl","Pantry","Nursery","Bathroom","Fridge"]
        let shopLocations = ["Produce","Aisle 1","Aisle 2","Aisle 3","Deli"]
        let unitNames = ["g","pkt","box","ml","kg"]
        let itemNames = ["Grapes","Biscuits","Nappies","Shampoo","Sausages"]

        var i = 0

        for itemName in itemNames {
            print("Inserting '\(itemName)'")
            if let locationAtHome = NSEntityDescription.insertNewObject(forEntityName: "LocationAtHome", into: context) as? LocationAtHome
                , let locationAtShop = NSEntityDescription.insertNewObject(forEntityName: "LocationAtShop", into: context) as? LocationAtShop
                , let unit = NSEntityDescription.insertNewObject(forEntityName: "Unit", into: context) as? Unit
                , let item = NSEntityDescription.insertNewObject(forEntityName: "Item", into: context) as? Item {

                locationAtHome.storedIn = homeLocations[i]
                locationAtShop.aisle    = shopLocations[i]
                unit.name = unitNames[i]
                item.name = itemNames[i]
                item.locationAtHome = locationAtHome
                item.locationAtShop = locationAtShop
                item.unit = unit
                i += 1
            } else {"ERROR preparing items in \(#function)"}
        }
        print("Test data was inserted")
        CDHelper.saveSharedContext()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate
        {
            //appDelegate.demoItemUnitRelationShipDataEntry()
            //appDelegate.demoDeleteUnitswithDenyDeleteRule()
            //appDelegate.demoInsertIntemswithLocation()
//            appDelegate.deletelocationData()
//            appDelegate.deletelocationDatawithCascadeDeleteRule()
        }
    }
    
    

}

