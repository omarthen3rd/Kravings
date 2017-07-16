//
//  FavouritesDetailContainerViewController.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-07-14.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit

class FavouritesDetailContainerViewController: UIViewController {
    
    @IBOutlet var containerThingy: UIView!

    var restaurant: Restaurant!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "FavouritesChildSegue" {
            
            let childController = segue.destination as! FavouritesDetailTableViewController
            childController.restaurant = restaurant
            
        }
        
    }

}
