//
//  PrepareTVC.swift
//  SwiftDatabaseTutorial
//
//  Created by Roy, Bidhan (623) on 23/05/20.
//  Copyright © 2020 Roy, Bidhan (623). All rights reserved.
//

import UIKit

class PrepareTVC: CDTableController<Item> {
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.entity = "Item"
        self.sort = [NSSortDescriptor(key: "name", ascending: true)]
        self.sectionNameKeyPath = "locationAtHome.storedIn"
        self.fetchBatchSize = 50
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.performFetch()
    }

    // MARK: - Table view data source

    override func configureCell(cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let item = frc.object(at: indexPath)
        var itemName = ""
        if let name = item.name {
            itemName = "\(name) \(item.quantity)"
        }
        
        if let unitname = item.unit?.name {
            itemName = "\(itemName) \(unitname)"
        }
        
        if let textLabel = cell.textLabel {
            textLabel.text = itemName
            cell.accessoryType = .detailButton
            if item.listed == true {
                textLabel.textColor = .red
            } else {
                textLabel.textColor = .gray
            }
        } else {
            print("error getting textlabel")
        }
        
    }
    
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let item  = self.frc.object(at: indexPath)
            self.frc.managedObjectContext.delete(item)
            CDHelper.saveSharedContext()
        }
    }

}
