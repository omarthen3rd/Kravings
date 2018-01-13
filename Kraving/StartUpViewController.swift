//
//  StartUpViewController.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-08-31.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit
import SystemConfiguration
import CoreLocation

class StartUpViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet var setupContainerView: UIView!
    @IBOutlet var appIconImageView: UIImageView!
    @IBOutlet var viewTitleLabel: UILabel!
    @IBOutlet var viewSubtitleLabel: UILabel!
    @IBOutlet var useLocation: UIButton!
    @IBOutlet var useAddress: UIButton!
    
    @IBAction func unwindToViewController(segue: UIStoryboardSegue) {}
    
    let defaults = UserDefaults.standard
    
    var isFirstLaunch = Bool()
    
    var locationManager = CLLocationManager()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        
        let internetIsAvailable = isInternetAvailable()
        
        if internetIsAvailable {
                        
            isFirstLaunch = defaults.object(forKey: "firstLaunch") == nil
            
            if isFirstLaunch {
                
                self.navigationController?.navigationBar.isHidden = true
                self.setupContainerView.isHidden = false
                
            } else {
                
                if CLLocationManager.locationServicesEnabled() && CLLocationManager.authorizationStatus() == .authorizedWhenInUse {

                    // location has successfully been authenticated and it isn't first launch
                    
                    let vc = storyboard?.instantiateViewController(withIdentifier: "DefaultViewController") as! DefaultViewController
                    self.present(vc, animated: true, completion: nil)
                    
                } else if (CLLocationManager.authorizationStatus() == .denied) || (CLLocationManager.authorizationStatus() == .restricted) || (CLLocationManager.authorizationStatus() == .notDetermined) {
                    
                    // user has succesfully chosen addresses as their primary input of location, open address view
                    // .denied = user explicitly said no to using location or location services are off in settings
                    // .restricted = ¯\_(ツ)_/¯
                    // .notDetermined = user has not chosen option about Location Services (ie went driectly to "Use Address" option)
                    
                    let vc = storyboard?.instantiateViewController(withIdentifier: "AddressViewController") as! AddressViewController
                    let nav = UINavigationController(rootViewController: vc)
                    self.present(nav, animated: true, completion: nil)
                    
                }
                
            }
            
            useLocation.addTarget(self, action: #selector(self.useLocationServices), for: UIControlEvents.touchUpInside)
            useAddress.addTarget(self, action: #selector(self.useAddressServices), for: UIControlEvents.touchUpInside)
            
            useLocation.isEnabled = true
            useAddress.isEnabled = true
            
        } else {
            
            // no internet connection
            
            useLocation.isEnabled = false
            useAddress.isEnabled = false
            
            let alrt = UIAlertController(title: "No Internet Connection", message: "You are not connected to the internet. Please turn on your Cellular Data or Wi-Fi", preferredStyle: .alert)
            let alrtAction = UIAlertAction(title: "Retry", style: UIAlertActionStyle.default, handler: { (action) in
                
                self.viewDidAppear(false)
                
            })
            alrt.addAction(alrtAction)
            self.present(alrt, animated: true, completion: nil)
            
        }
    }
    
    func useLocationServices() {
        
        if CLLocationManager.locationServicesEnabled() {
            
            // look at location delegate "didUpdateLocations" to see how everything works
            
            locationManager.distanceFilter = 100
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            locationManager.requestLocation() // didUpdateLocations
            
        } else {
            
            // user location services are turned off
            
            let alrt = UIAlertController(title: "Please Enable Location Services", message: "This option cannot work without enabling Location Services.", preferredStyle: .alert)
            let alrtAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alrt.addAction(alrtAction)
            self.present(alrt, animated: true, completion: nil)
            
        }
        
    }
    
    func useAddressServices() {
        
        let vc = storyboard?.instantiateViewController(withIdentifier: "AddressViewController") as! AddressViewController
        self.present(vc, animated: true) {
            // self.defaults.set("yes", forKey: "firstLaunch")
            // doesn't work because of error with "present view which is not in view hierarchy"
            // will fix soon...
        }
        
        self.defaults.set("yes", forKey: "firstLaunch")
        
    }
    
    func internetChecker(completetionHandler: @escaping (Bool) -> Void) {
        
        let thing = isInternetAvailable()
        
        completetionHandler(thing)
        
    }
    
    func isInternetAvailable() -> Bool {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }) else {
            return false
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return (isReachable && !needsConnection)
    }
    
    private var didPerformGeocode = false
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        self.locationManager.stopUpdatingLocation()
        
        guard let location = locations.first, (locations.first?.horizontalAccuracy)! >= CLLocationAccuracy(0) else { return }
        
        guard !didPerformGeocode else { return }
        
        didPerformGeocode = true
        locationManager.stopUpdatingLocation()
        
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
            
            let coord = location.coordinate
            
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "DefaultViewController") as! DefaultViewController
            vc.lat = coord.latitude
            vc.long = coord.latitude
            self.present(vc, animated: true, completion: {
                
                self.defaults.set("yes", forKey: "firstLaunch")
                
            })
            
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        let alrt = UIAlertController(title: "Please Enable Location Services", message: "This option cannot work without enabling Location Services.", preferredStyle: .alert)
        let alrtAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alrt.addAction(alrtAction)
        self.present(alrt, animated: true, completion: nil)
        
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
    }

}
