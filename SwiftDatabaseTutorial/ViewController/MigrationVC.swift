//
//  MigrationVC.swift
//  SwiftDatabaseTutorial
//
//  Created by Roy, Bidhan (623) on 21/05/20.
//  Copyright © 2020 Roy, Bidhan (623). All rights reserved.
//

import UIKit

class MigrationVC: UIViewController {

    @IBOutlet weak var progressDataLbl: UILabel!
    @IBOutlet weak var migrationProgress: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(progressChanged(note:)), name: NSNotification.Name(rawValue: "migrationProgress"), object: nil)
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
