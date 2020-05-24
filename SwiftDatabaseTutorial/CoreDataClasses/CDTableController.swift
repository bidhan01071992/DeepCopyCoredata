//
//  CDTableController.swift
//  SwiftDatabaseTutorial
//
//  Created by Roy, Bidhan (623) on 22/05/20.
//  Copyright © 2020 Roy, Bidhan (623). All rights reserved.
//

import Foundation
import UIKit
import CoreData

///This claass is responsible when we want to fetch data from coredata using fetch result controller from a certain entity
///The tableview controller will be a subclass of the CDTablecontroller and it will pass the Entity. For reference please check prepareTVC. Inside that all need to do is override properties like entity, sort filter etc. and configureCell method need to be overridden to affect the Ui changes of the tableview cell.
///
///
///The perform fetch method should be called in viewdid appear which will fetch the data from the coredata to display in tableview.
///
///If we make some changed to the databse from someplace else we have to post "SomethingChanged" notification which will call perform fetch.

class CDTableController<T>: UITableViewController, NSFetchedResultsControllerDelegate where T: NSManagedObject {
    
    // MARK: - CELL CONFIGURATION
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: IndexPath) {

        // Use self.frc.objectAtIndexPath(indexPath) to get an object specific to a cell in the subclasses
        print("Please override configureCell in \(#function)!")
    }
    
    //Override properties
       var entity = "TestEntity"
       var sort = [NSSortDescriptor(key: "", ascending: true)]
       var context = CDHelper.shared.context
       //Optional override
       var filter : NSPredicate? = nil
       var cacheName: String? = nil
       var sectionNameKeyPath:String? = nil
       var fetchBatchSize = 0 // 0 = No Limit
       var cellIdentifier = "Cell"
       
       // MARK: - FETCHED RESULTS CONTROLLER
    lazy var frc: NSFetchedResultsController<T> = {

            let request = NSFetchRequest<T>(entityName:self.entity)
               request.sortDescriptors = self.sort
               request.fetchBatchSize  = self.fetchBatchSize
               if let _filter = self.filter {request.predicate = _filter}

               let newFRC = NSFetchedResultsController(
                                   fetchRequest: request,
                           managedObjectContext: self.context,
                             sectionNameKeyPath: self.sectionNameKeyPath,
                                      cacheName: self.cacheName)
               newFRC.delegate = self
               return newFRC
           }()
    
    
    // MARK: - FETCHING
    ///The performFetch function is responsible for fetching data. If errors occur during the fetch, they are logged to the console.
    @objc func performFetch () {
        self.frc.managedObjectContext.perform ({

            do {
                try self.frc.performFetch()
            } catch {
                print("\(#function) FAILED : \(error)")
            }
            self.tableView.reloadData()
        })
    }
    
    // MARK: - VIEW
    ///The viewDidLoad function is configured to listen for notifications that the table view should refetch all its data. When underlying data changes for an entity other than the one the table view is displaying, the fetched results controller won’t tell the table view to refresh. For example, when a unit name is updated, the items table view won’t be updated even if it relies on item.unit.name. In this case you need to post a SomethingChanged notification manually.
    override func viewDidLoad() {
        super.viewDidLoad()
        // Force fetch when notified of significant data changes
        NotificationCenter.default.addObserver(self, selector: #selector(performFetch), name: NSNotification.Name(rawValue: "SomethingChanged"), object: nil)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - DEALLOCATION
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "SomethingChanged"), object: nil)
    }
    
    // MARK: - DATA SOURCE: UITableView
    
    
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.frc.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.frc.sections![section].numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell:UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: self.cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .value1, reuseIdentifier: self.cellIdentifier)
        }
        cell!.selectionStyle = .none
        cell!.accessoryType = .detailButton
        self.configureCell(cell: cell!, atIndexPath: indexPath)
        return cell!
    }
    
    ///The sectionForSectionIndexTitle function indicates what section a particular section title belongs to. A fetched results controller has a function specifically to help provide this. This means returning self.frc.sectionForSectionIndexTitle(title, atIndex: index) is all that’s required here.
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return self.frc.section(forSectionIndexTitle: title, at: index)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?  {
        return self.frc.sections![section].name
    }
    
    ///The sectionIndexTitlesForTableView function indicates the text title of each index that should be shown in the table view. A fetched results controller has a variable specifically to help populate this table view data source function. This means returning self.frc.sectionIndexTitles is all that’s required here.
    override func sectionIndexTitles(for tableView: UITableView) -> [String]?  {
        return self.frc.sectionIndexTitles
    }
    
    // MARK: - DELEGATE: NSFetchedResultsController
    ///Whenever you need to make a change to the data presented in a table view, you need to tell the table view to beginUpdates, and when you’re done, endUpdates. When you’re using a fetched results controller, you need to call these functions from controllerWillChangeContent and controllerDidChangeContent, respectively,
    
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)  {
        self.tableView.beginUpdates()
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
    /// two fetched results controller delegate protocol functions to be implemented are controller:didChangeSection and controller:didChangeObject. They handle table view cell moves, deletes, updates, and insertions.
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            self.tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            self.tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
        return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            self.tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            self.tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            self.tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            self.tableView.deleteRows(at: [indexPath!], with: .fade)
            self.tableView.insertRows(at: [newIndexPath!], with: .fade)
        @unknown default:
            fatalError()
        }
    }
    
}

