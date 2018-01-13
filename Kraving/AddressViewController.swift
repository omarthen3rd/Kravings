//
//  AddressViewController.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-08-31.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit
import CoreLocation

class CoolerUITextField: UITextField {
    
    override func tintColorDidChange() {
        // set vibrant color for place holder text
        self.setValue(self.tintColor, forKey: "_placeholderLabel.textColor")
        // below for normal text as well
        // self.textColor = self.tintColor
        
    }
    
}

class AddressViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    @IBOutlet var backgroundBlur: VisualEffectView!
    @IBOutlet var addressTextField: CoolerUITextField!
    @IBOutlet var addressDone: UIButton!
    @IBOutlet var searchesTableView: UITableView!
    @IBOutlet var openFavourites: UIButton!
    
    @IBOutlet var alertView: UIVisualEffectView!
    @IBOutlet var alertViewLabel: UILabel!
    @IBOutlet var alertViewSpinner: UIActivityIndicatorView!
    
    var closeBlur = UIViewPropertyAnimator()
    
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
            
            // no recent searches, create arr and encode
            
            let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: searches)
            defaults.set(encodedData, forKey: "addressRecentSearches")
            defaults.synchronize()
            
            self.searchesTableView.isHidden = true
            
        } else {
            
            // there are searches in archive
            // replace archived searches with current searches arr because archived will always be the most updated one at start
            
            if let decodedArr = defaults.object(forKey: "addressRecentSearches") as? Data {
                
                if let decodedSearches = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [String] {
                    
                    self.searches = decodedSearches
                    
                    self.searchesTableView.isHidden = false
                    
                }
            }
        }
        
        // ui stuff
        
        // backgroundBlur.colorTint = UIColor(white: 1.0, alpha: 0.3)
        // backgroundBlur.colorTintAlpha = 1.0
        // backgroundBlur.blurRadius = 35
        // backgroundBlur.scale = 1.0
        
        backgroundBlur.effect = UIBlurEffect(style: .light)
        
        // table view ui
        searchesTableView.backgroundColor = UIColor.clear
        searchesTableView.contentOffset = CGPoint(x: 0, y: -50)
        searchesTableView.separatorColor = UIColor.clear
        searchesTableView.separatorEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
        searchesTableView.separatorStyle = .singleLine
        searchesTableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        let image1 = #imageLiteral(resourceName: "btn_openFavourites_selected").withRenderingMode(.alwaysTemplate)
        
        openFavourites.setImage(image1, for: .normal)
        openFavourites.setImage(image1, for: UIControlState.highlighted)
        openFavourites.imageView?.tintColor = UIColor.white
        openFavourites.imageView?.contentMode = .scaleAspectFit
        openFavourites.imageEdgeInsets = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        
        addressDone.addTarget(self, action: #selector(self.masterDone), for: UIControlEvents.touchUpInside)
        addressDone.isUserInteractionEnabled = true
        
    }
    
    func masterDone() {
        
        // done button action
        
        searchesTableView.isUserInteractionEnabled = false
        addressTextField.isUserInteractionEnabled = false
        showAlertView()
        
        addToRecent()
        reverseGeocode()
        
        DispatchQueue.main.async {
            
            self.searchesTableView.reloadData()
            
        }
        
    }
    
    func reverseGeocode() {
        
        guard let address = addressTextField.text else { return }
        
        if address.count != 0 {
            
            CLGeocoder().geocodeAddressString(address) { (placemarks, error) in
                
                if error != nil {
                    
                    let alert = UIAlertController(title: "Error", message: "\(error.debugDescription)", preferredStyle: UIAlertControllerStyle.alert)
                    let action = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
                    alert.addAction(action)
                    self.present(alert, animated: true, completion: nil)
                    self.searchesTableView.isUserInteractionEnabled = true
                    self.addressTextField.isUserInteractionEnabled = true
                    
                } else {
                    
                    let placemark = placemarks?.first
                    let lat = placemark?.location?.coordinate.latitude
                    let long = placemark?.location?.coordinate.longitude
                    
                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "DefaultViewController") as! DefaultViewController
                    vc.modalTransitionStyle = .crossDissolve
                    vc.lat = lat!
                    vc.long = long!
                    self.closeBlur.startAnimation() // close alertView
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
            // add to searches array
            
            searches.insert(currentAddress, at: 0)
            
            DispatchQueue.main.async {
                
                self.searchesTableView.reloadData()
                
            }
            
            // now update archived version with new array
            
            if let decodedArr = defaults.object(forKey: "addressRecentSearches") as? Data {
                
                if var decodedSearches = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [String] {
                    
                    decodedSearches = searches
                    
                    let encode: Data = NSKeyedArchiver.archivedData(withRootObject: decodedSearches)
                    defaults.set(encode, forKey: "addressRecentSearches")
                    defaults.synchronize()
                    
                    self.searchesTableView.isHidden = false
                    
                }
            }
            
        } else if searches.contains(currentAddress) {
            
            // already in searches arr
            // now move it to the top of recent searches
            
            // find index of current string
            guard let index = searches.index(of: currentAddress) else { return }
            
            // remove string from array
            searches.remove(at: index)
            
            // insert again at first index
            searches.insert(currentAddress, at: 0)
            DispatchQueue.main.async {
                self.searchesTableView.reloadData()
            }
            
            // now update archived version with new array
            if let decodedArr = defaults.object(forKey: "addressRecentSearches") as? Data {
                
                if var decodedSearches = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [String] {
                    
                    decodedSearches = searches
                    
                    let encode: Data = NSKeyedArchiver.archivedData(withRootObject: decodedSearches)
                    defaults.set(encode, forKey: "addressRecentSearches")
                    defaults.synchronize()
                    
                    self.searchesTableView.isHidden = false
                    
                }
            }
            
        }
        
    }
    
    func showAlertView() {
        
        closeBlur = UIViewPropertyAnimator(duration: 0.2, curve: .easeOut) {
            
            self.alertView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            self.alertView.alpha = 0
            self.alertViewSpinner.stopAnimating()
            
        }
        closeBlur.addCompletion { (position) in
            
            self.alertView.isHidden = true
            
        }
        
        let blurAnimator = UIViewPropertyAnimator(duration: 0.2, curve: .easeIn) {
            
            self.alertView.transform = CGAffineTransform.identity
            self.alertView.alpha = 1
            
        }
        
        self.alertView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        self.alertView.alpha = 0
        self.alertView.isHidden = false
        
        alertViewSpinner.startAnimating()
        alertViewLabel.text = "Figuring Out Where You Live..."
        blurAnimator.startAnimation()
        
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
        
        let blurEffect = UIBlurEffect(style: .light)
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
        let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
        vibrancyEffectView.frame = CGRect(x: 16, y: 0, width: tableView.bounds.size.width, height: 20)
        vibrancyEffectView.autoresizingMask = .flexibleWidth
        
        // create header label
        let vibrantLabel = UILabel()
        vibrantLabel.frame = CGRect(x: 8, y: 0, width: tableView.bounds.size.width, height: 20)
        vibrantLabel.autoresizingMask = .flexibleWidth
        vibrantLabel.text = "RECENT SEARCHES"
        vibrantLabel.font = UIFont.systemFont(ofSize: 13)
        
        vibrancyEffectView.contentView.addSubview(vibrantLabel)
        
        return vibrancyEffectView

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
