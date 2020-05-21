//
//  ViewController.swift
//  SwiftDatabaseTutorial
//
//  Created by Roy, Bidhan (623) on 20/05/20.
//  Copyright © 2020 Roy, Bidhan (623). All rights reserved.
//

import UIKit

///ViewController
///
///
///Reporting on the progress of a migration is useful for keeping the user informed (and less annoyed) about a slow launch. Although most migrations should be fast, some large databases requiring complex changes can take a while to migrate. To keep the user interface responsive, the migration must be performed on a background thread. At the same time, the user interface has to be responsive to provide updates to the user. The challenge is to prevent the user from attempting to use the application during the migration. This is because the data won’t be ready yet, so you don’t want the user staring at a blank screen wondering what’s going on. This is where a migration progress view comes into play.


class ViewController: UIViewController {

    @IBOutlet weak var progressDataLbl: UILabel!
    @IBOutlet weak var migrationProgress: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        NotificationCenter.default.addObserver(self, selector: #selector(progressChanged(note:)), name: NSNotification.Name(rawValue: "migration"), object: nil)
    }
    
    //MARK: Migration
    ///The progressChanged function simply unwraps the progress notification and constructs a string with the migration completion percentage. It then updates the user interface with this information. Of course, none of this can happen without first adding an observer of the migrationProgress variable in the viewDidLoad function. When the view deinitializes, it is unregistered as an observer of the migrationProgress variable.
    @objc func progressChanged(note: AnyObject?) {
        
        guard let notification = note as? NSNotification else {
            return
        }
        guard let progress = notification.object as? NSNumber else {
           return
        }
        
        let progressFloat = round(progress.doubleValue * 100)
        DispatchQueue.main.async {
            self.progressDataLbl.text = "Migration \(progressFloat)% completed"
            self.migrationProgress.progress = progress.floatValue
        }
        
    }

    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "migration"), object: nil)
    }

}

