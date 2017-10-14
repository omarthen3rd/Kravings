//
//  AddressViewController.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-08-31.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit
import CoreLocation

class AddressViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    @IBOutlet var addressTextField: UITextField!
    @IBOutlet var addressDone: UIButton!
    @IBOutlet var searchesTableView: UITableView!
    
    let defaults = UserDefaults.standard
    var searches = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.searchesTableView.isHidden = true
        
        // Do any additional setup after loading the view.
        setupController()
        
    }
    
    func setupController() {
        
        // set delegates
        addressTextField.delegate = self
        addressTextField.returnKeyType = .done
        
        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = true
        }
        
        // create recent searches archive
        if defaults.object(forKey: "addressRecentSearches") == nil {
            
            // no recent searches, create arr, encode and replace
            
            let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: searches)
            defaults.set(encodedData, forKey: "addressRecentSearches")
            defaults.synchronize()
            
            self.searchesTableView.isHidden = true
            
        } else {
            
            // there are searches in archive
            // replace archived searches with current searches arr because archived will always be the most updated one at start
            
            if let decodedArr = defaults.object(forKey: "addressRecentSearches") as? Data {
                
                if var decodedSearches = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [String] {
                    
                    decodedSearches = decodedSearches.reversed()
                    self.searches = decodedSearches
                    
                    self.searchesTableView.isHidden = false
                    
                }
            }
        }
        
        // ui things
        
        searchesTableView.backgroundColor = UIColor.clear
        searchesTableView.layer.cornerRadius = 10
        searchesTableView.clipsToBounds = true
        searchesTableView.contentOffset = CGPoint(x: 0, y: -50)
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = searchesTableView.bounds
        // searchesTableView.backgroundView = blurEffectView
        searchesTableView.separatorEffect = UIBlurEffect(style: UIBlurEffectStyle.regular)
        // searchesTableView.separatorColor = UIColor.lightText
        
        addressDone.addTarget(self, action: #selector(self.masterDone), for: UIControlEvents.touchUpInside)
        addressDone.isUserInteractionEnabled = true
        
    }
    
    func masterDone() {
        
        // done button action
        
        addToRecent()
        reverseGeocode()
        
        DispatchQueue.main.async {
            
            self.searchesTableView.reloadData()
            
        }
        
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
                    
                } else {
                    
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
        
    }
    
    func addToRecent() {
        
        self.searchesTableView.isHidden = false
        
        let currentAddress = addressTextField.text!
        
        DispatchQueue.main.async {
            
            self.searchesTableView.reloadData()
            
        }
        
        if !(searches.contains(currentAddress)) {
            
            // not in archived or current
                        
            searches.insert(currentAddress, at: 0)
            
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
                    
                    self.searchesTableView.isHidden = false
                    
                }
            }
        }
        
    }
    
    // Text field delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        masterDone()
        return true
        
    }
    
    // Table view delegate
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = UIView(frame: CGRect(x: 16, y: 0, width: tableView.bounds.width, height: 20))
        headerView.autoresizingMask = .flexibleWidth
        
        let label = UILabel(frame: CGRect(x: 8, y: 0, width: headerView.bounds.width, height: 15))
        label.text = "Recent Searches".uppercased()
        label.autoresizingMask = .flexibleWidth
        label.font = UIFont.systemFont(ofSize: 15, weight: UIFontWeightSemibold)
        
        headerView.addSubview(label)
        
        return headerView
        
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return "Recent Searches"
        
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let currentAddress = searches[indexPath.row]
        
        addressTextField.text = currentAddress
        masterDone()
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchesCell", for: indexPath)
        
        let search = searches[indexPath.row]
        
        cell.textLabel?.text = search
        // cell.textLabel?.textColor = UIColor.white
        cell.backgroundColor = UIColor.clear
        
        let newSelectionView = UIVisualEffectView(frame: cell.bounds)
        newSelectionView.effect = UIBlurEffect(style: UIBlurEffectStyle.regular)
        cell.selectedBackgroundView = newSelectionView
        
        cell.layer.cornerRadius = 10
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let delAction = UITableViewRowAction(style: UITableViewRowActionStyle.destructive, title: "Delete") { (action, index) in
            
            self.searches.remove(at: indexPath.row)
            
            let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: self.searches)
            self.defaults.set(encodedData, forKey: "addressRecentSearches")
            self.defaults.synchronize()
            
            self.searchesTableView.reloadData()
        }
        
        return [delAction]
        
    }

}
