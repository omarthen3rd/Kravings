//
//  AddressViewController.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-08-31.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit
import CoreLocation

class AddressViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var addressTextField: UITextField!
    @IBOutlet var addressDone: UIButton!
    @IBOutlet var searchesTableView: UITableView!
    @IBAction func goBack(_ sender: Any) {
        
        self.navigationController?.popViewController(animated: true)
        
    }
    
    let defaults = UserDefaults.standard
    var searches = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addressDone.isUserInteractionEnabled = false

        // Do any additional setup after loading the view.
        setupController()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupController() {
        
        // create recent searches archive
        if defaults.object(forKey: "addressRecentSearches") == nil {
            
            // no recent searches, create arr, encode and replace
            
            let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: searches)
            defaults.set(encodedData, forKey: "addressRecentSearches")
            defaults.synchronize()
            
        } else {
            
            // replace archived searches with current searches arr because archived will always be the most updated one at start
            
            if let decodedArr = defaults.object(forKey: "addressRecentSearches") as? Data {
                
                if let decodedSearches = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [String] {
                    
                    self.searches = decodedSearches
                    
                }
            }
        }
        
        addressDone.addTarget(self, action: #selector(self.masterDone), for: UIControlEvents.touchUpInside)
        addressDone.isUserInteractionEnabled = true
        
    }
    
    func masterDone() {
        
        addToRecent()
        reverseGeocode()
        
    }
    
    func reverseGeocode() {
        
        let address = addressTextField.text
        
        if !(address?.characters.count == 0) {
            
            CLGeocoder().geocodeAddressString(address!) { (placemarks, error) in
                
                if error != nil {
                    
                    let alert = UIAlertController(title: "Error", message: "\(error.debugDescription)", preferredStyle: UIAlertControllerStyle.alert)
                    let action = UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil)
                    alert.addAction(action)
                    self.present(alert, animated: true, completion: nil)
                    
                }
                
                let placemark = placemarks?.first
                let lat = placemark?.location?.coordinate.latitude
                let long = placemark?.location?.coordinate.longitude
                
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "ViewController") as! ViewController
                vc.lat = lat!
                vc.long = long!
                self.present(vc, animated: true, completion: nil)
                
            }
            
        }
        
    }
    
    func addToRecent() {
        
        let currentAddress = addressTextField.text!
        
        if !(searches.contains(currentAddress)) {
            
            // not in archived or current
            
            searches.append(currentAddress)
            
            DispatchQueue.main.async {
                
                self.searchesTableView.reloadData()
                
            }
            
            // now update archived version
            
            if let decodedArr = defaults.object(forKey: "addressRecentSearches") as? Data {
                
                if var decodedSearches = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [String] {
                    
                    decodedSearches.append(currentAddress)
                    
                    let encode: Data = NSKeyedArchiver.archivedData(withRootObject: decodedSearches)
                    defaults.set(encode, forKey: "addressRecentSearches")
                    defaults.synchronize()
                    
                }
            }
        }
        
    }
    
    func addToRecentSearches() {
        
        let currentAddress = addressTextField.text!
        
        if defaults.object(forKey: "addressRecentSearches") == nil {
            
            // no recent searches, create arr, encode and replace
            
            var recentSearches = [String]()
            recentSearches.append(currentAddress)
            
            let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: recentSearches)
            defaults.set(encodedData, forKey: "addressRecentSearches")
            defaults.synchronize()
            
        } else {
            
            if let decodedArr = defaults.object(forKey: "addressRecentSearches") as? Data {
                
                if var decodedSearches = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [String] {
                    
                    if !(decodedSearches.contains(where: { $0 == currentAddress } )) {
                        
                        // not in favourites 
                        decodedSearches.append(currentAddress)
                        
                    } else {
                        
                        let alert = Alert()
                        alert.msg(title: "Already In Favourites", message: "The restaurant you favourited is already in your favourites.")
                        
                    }
                    
                    let encode: Data = NSKeyedArchiver.archivedData(withRootObject: decodedSearches)
                    defaults.set(encode, forKey: "addressRecentSearches")
                    defaults.synchronize()
                    
                }
                
            }
            
        }
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        if defaults.object(forKey: "addressRecentSearches") == nil {
            
            return 0
            
        } else {
            
            return 1
            
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return searches.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchesCell", for: indexPath) as! CategoryTableViewCell
        
        let search = searches[indexPath.row]
        
        cell.categoryLabel.text = search
        
        return cell
        
    }

}
