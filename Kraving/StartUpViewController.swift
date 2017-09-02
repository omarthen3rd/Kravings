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

class StartUpViewController: UIViewController {

    @IBOutlet var setupContainerView: UIView!
    @IBOutlet var appIconImageView: UIImageView!
    @IBOutlet var viewTitleLabel: UILabel!
    @IBOutlet var viewSubtitleLabel: UILabel!
    @IBOutlet var useLocation: UIButton!
    @IBOutlet var useAddress: UIButton!
    
    @IBAction func unwindToViewController(segue: UIStoryboardSegue) {}
    
    let defaults = UserDefaults.standard
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if defaults.bool(forKey: "usesLocationServices") == true {
            
            let vc = storyboard?.instantiateViewController(withIdentifier: "ViewController") as! ViewController
            self.present(vc, animated: true, completion: nil)
            
        } else if defaults.bool(forKey: "usesAddressServices") == true {
            
            let vc = storyboard?.instantiateViewController(withIdentifier: "AddressViewController") as! AddressViewController
            let nav = UINavigationController(rootViewController: vc)
            self.present(nav, animated: true, completion: nil)
            
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        useLocation.addTarget(self, action: #selector(self.useLocationServices), for: UIControlEvents.touchUpInside)
        useAddress.addTarget(self, action: #selector(self.useAddressServices), for: UIControlEvents.touchUpInside)
        
        let isFirstLaunch = defaults.object(forKey: "firstLaunch") == nil
        
        if isFirstLaunch {
            
            defaults.set("yes", forKey: "firstLaunch")
                        
            self.navigationController?.navigationBar.isHidden = true
            self.setupContainerView.isHidden = false
            
        } else {
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func useLocationServices() {
        
        defaults.set(true, forKey: "usesLocationServices")
        defaults.set(false, forKey: "usesAddressServices")
        
        let vc = storyboard?.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        self.present(vc, animated: true, completion: nil)
        
    }
    
    func useAddressServices() {
        
        defaults.set(false, forKey: "usesLocationServices")
        defaults.set(true, forKey: "usesAddressServices")
        
        let vc = storyboard?.instantiateViewController(withIdentifier: "AddressViewController") as! AddressViewController
        self.present(vc, animated: true, completion: nil)
        
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

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
    }

}
