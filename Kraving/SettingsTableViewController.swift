//
//  SettingsTableViewController.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-07-10.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit
import CoreLocation

protocol SettingsDelegate {
    
    func dataChanged()
    
}

class UIPickerCell: UITableViewCell {
    
    @IBOutlet var cellName: UILabel!
    @IBOutlet var label: UILabel!
    @IBOutlet var picker: UIPickerView!
    
    var arr = [String]()
    
    let defaults = UserDefaults.standard
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        picker.dataSource = self
        picker.delegate = self
        
        self.selectionStyle = .default
        
        var pickerString = ""
        var pickerIndex = 0
        
        switch defaults.object(forKey: "whichCell") as! String {
        case "Maps":
            arr = ["Apple Maps", "Google Maps", "Waze"]
            pickerString = defaults.object(forKey: "defaultMaps") as! String
            pickerIndex = arr.index(of: pickerString)!
            picker.selectRow(pickerIndex, inComponent: 0, animated: true)
        case "Browser":
            arr = ["Safari", "Google Chrome"]
            pickerString = defaults.object(forKey: "defaultBrowser") as! String
            pickerIndex = arr.index(of: pickerString)!
            picker.selectRow(pickerIndex, inComponent: 0, animated: true)
        default:
            arr = ["Apple Maps", "Google Maps", "Waze"]
            pickerString = defaults.object(forKey: "defaultMaps") as! String
            pickerIndex = arr.index(of: pickerString)!
            picker.selectRow(pickerIndex, inComponent: 0, animated: true)
        }
        
    }
    
}

extension UIPickerCell: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        let name = arr[row]
        // appIcon.image = UIImage(named: name)
        label.text = name
        
        if arr.contains("Safari") {
            defaults.set(name, forKey: "defaultBrowser")
        } else {
            defaults.set(name, forKey: "defaultMaps")
        }
        
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return arr.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return arr[row]
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
}

class SettingsTableViewController: UITableViewController {
    
    let defaults = UserDefaults.standard
    
    var previousRadius = Int()
    
    var delegate: SettingsDelegate?
    
    var selectedIndex : NSInteger! = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = true
        }
        
        self.previousRadius = defaults.integer(forKey: "searchRadius")
        
        addBlur()
        
        tableView.register(UINib(nibName: "Slidercell", bundle: nil), forCellReuseIdentifier: "Slidercell")
        tableView.register(UINib(nibName: "ButtonCell", bundle: nil), forCellReuseIdentifier: "ButtonCell")
        
        tableView.tableFooterView = UIView(frame: .zero)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.previousRadius != defaults.integer(forKey: "searchRadius") {
            if let del = delegate {
                del.dataChanged()
            }
            
        }
        
    }
    
    func addBlur() {
        
        self.tableView.backgroundColor = UIColor.clear
        let blurEffect = UIBlurEffect(style: .extraLight)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        tableView.separatorEffect = UIVibrancyEffect(blurEffect: blurEffect)
        
        self.tableView.backgroundView = blurEffectView
        
    }
    
    func goBackToAddressView() {
        
        self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: {
            
            if let vc = self.presentingViewController?.presentingViewController as? AddressViewController {
                
                let btn = vc.navigationController?.navigationItem.rightBarButtonItems?.first
                btn?.isEnabled = false
                
            }
            
        })
        
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if section == 0 {
            
            let blurEffect = UIBlurEffect(style: .extraLight)
            let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
            let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
            vibrancyEffectView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 60)
            vibrancyEffectView.autoresizingMask = .flexibleWidth
            
            // Create header label
            let vibrantLabel = UILabel()
            vibrantLabel.frame = CGRect(x: 15, y: 30, width: tableView.bounds.size.width, height: 30)
            vibrantLabel.autoresizingMask = .flexibleWidth
            vibrantLabel.text = "SEARCH RADIUS"
            vibrantLabel.font = UIFont.systemFont(ofSize: 13)
            vibrantLabel.textColor = UIColor(white: 0.64, alpha: 1)
            
            vibrancyEffectView.contentView.addSubview(vibrantLabel)
            
            return vibrancyEffectView
            
        } else if section == 1 {
            
            let blurEffect = UIBlurEffect(style: .extraLight)
            let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
            let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
            vibrancyEffectView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 30)
            vibrancyEffectView.autoresizingMask = .flexibleWidth
            
            // Create header label
            let vibrantLabel = UILabel()
            vibrantLabel.frame = CGRect(x: 15, y: 0, width: tableView.bounds.size.width, height: 30)
            vibrantLabel.autoresizingMask = .flexibleWidth
            vibrantLabel.text = "DEFAULT APPS"
            vibrantLabel.font = UIFont.systemFont(ofSize: 13)
            vibrantLabel.textColor = UIColor(white: 0.64, alpha: 1)
            
            vibrancyEffectView.contentView.addSubview(vibrantLabel)
            
            return vibrancyEffectView

            
        } else {
            
            
            let blurEffect = UIBlurEffect(style: .extraLight)
            let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
            let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
            vibrancyEffectView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 30)
            vibrancyEffectView.autoresizingMask = .flexibleWidth
            
            // Create header label
            let vibrantLabel = UILabel()
            vibrantLabel.frame = CGRect(x: 15, y: 0, width: tableView.bounds.size.width, height: 30)
            vibrantLabel.autoresizingMask = .flexibleWidth
            vibrantLabel.text = "LOCATION"
            vibrantLabel.font = UIFont.systemFont(ofSize: 13)
            vibrantLabel.textColor = UIColor(white: 0.64, alpha: 1)
            
            vibrancyEffectView.contentView.addSubview(vibrantLabel)
            
            return vibrancyEffectView
            
        }
        
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if section == 0 {
            
            return 60
            
        } else {
            
            return 30
            
        }
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        if CLLocationManager.locationServicesEnabled() && CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            
            if defaults.bool(forKey: "usesAddressServices") == true {
                return 3
            } else {
                return 2
            }
            
        } else {
            
            return 3
            
        }
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            
            return 1
            
        } else if section == 1 {
            
            return 2
            
        } else  {
            
            return 1
            
        }
        
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "Slidercell", for: indexPath) as! SliderTableViewCell
            
            let defaultsValue = defaults.integer(forKey: "searchRadius")
            
            cell.selectionStyle = .none
            
            let locale = Locale.current
            let isMetric = locale.usesMetricSystem
            
            cell.slider.minimumValue = 1
            
            if isMetric {
                
                cell.slider.maximumValue = 40
                cell.radiusLabel.text = "\(defaultsValue / 1000) km"
                cell.slider.value = Float(defaultsValue / 1000)
                
            } else {
                
                cell.slider.maximumValue = 24
                cell.radiusLabel.text = "\(defaultsValue) mi"
                cell.slider.value = Float(defaultsValue)
                
            }
            
            cell.slider.addTarget(cell, action: #selector(cell.setSearchRadius(_:)), for: .valueChanged)
            
            return cell
            
        } else if indexPath.section == 1 {
            
            if indexPath.row == 0 {
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! UIPickerCell
                
                defaults.set("Browser", forKey: "whichCell")
                
                cell.cellName.text = "Maps"
                cell.label.text = defaults.object(forKey: "defaultMaps") as? String
                // cell.appIcon?.image = UIImage(named: defaults.object(forKey: "defaultMaps") as! String) ?? UIImage(named: "Apple Maps")
                
                return cell
                
            } else {
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! UIPickerCell
                
                defaults.set("Maps", forKey: "whichCell")
                
                cell.cellName.text = "Browser"
                cell.label.text = defaults.object(forKey: "defaultBrowser") as? String
                // cell.appIcon?.image = UIImage(named: defaults.object(forKey: "defaultBrowser") as! String) ?? UIImage(named: "Safari")
                
                return cell
                
            }
            
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath) as! ButtonTableViewCell
            
            print("ran cell")
            cell.changeAddress.addTarget(self, action: #selector(self.goBackToAddressView), for: UIControlEvents.touchUpInside)
            
            return cell
            
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 && (indexPath.row == 0 || indexPath.row == 1) {
            
            if indexPath.row == selectedIndex {
                
                selectedIndex = -1
                
            } else {
                
                selectedIndex = indexPath.row
                
            }
            
            tableView.beginUpdates()
            tableView.endUpdates()
            
        }
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.section == 1 {
            
            if indexPath.row == selectedIndex {
                
                return 250
                
            } else {
                
                return 68
                
            }
            
        } else {
            
            return 68
            
        }
        
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
}
