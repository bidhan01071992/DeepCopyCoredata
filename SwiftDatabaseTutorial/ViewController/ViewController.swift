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

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate
        {
            appDelegate.demoFetchUnit()
        }
    }
    
    

}

