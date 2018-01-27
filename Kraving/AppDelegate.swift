//
//  AppDelegate.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-07-07.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit
import CoreLocation
import NotificationCenter

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            
            if shortcutItem.type == "com.omar.kravings.openfavourites" {
                
                self.window = UIWindow(frame: UIScreen.main.bounds)
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                
                if CLLocationManager.locationServicesEnabled() && CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
                    
                    // location has successfully been authenticated and it isn't first launch
                    
                    let initialVC = storyboard.instantiateViewController(withIdentifier: "DefaultViewController") as! DefaultViewController
                    self.window?.rootViewController = initialVC
                    self.window?.makeKeyAndVisible()
                    let favouritesVC = storyboard.instantiateViewController(withIdentifier: "FavouritesViewController") as! FavouritesViewController
                    let nav = UINavigationController(rootViewController: favouritesVC)
                    initialVC.present(nav, animated: true, completion: nil)
                    
                } else if (CLLocationManager.authorizationStatus() == .denied) || (CLLocationManager.authorizationStatus() == .restricted) || (CLLocationManager.authorizationStatus() == .notDetermined) {
                    
                    // .denied = user explicitly said no to using location or location services are off in settings
                    // .restricted = ¯\_(ツ)_/¯
                    // .notDetermined = user has not chosen option about Location Services (ie went driectly to "Use Address" option)
                    // user has succesfully chosen addresses as their primary input of location, open address view
                    
                    let vc = storyboard.instantiateViewController(withIdentifier: "AddressViewController") as! AddressViewController
                    let nav = UINavigationController(rootViewController: vc)
                    self.window?.rootViewController = nav
                    self.window?.makeKeyAndVisible()
                    let favouritesVC = storyboard.instantiateViewController(withIdentifier: "FavouritesViewController") as! FavouritesViewController
                    let nav2 = UINavigationController(rootViewController: favouritesVC)
                    vc.present(nav2, animated: true, completion: nil)
                    
                }
                
            }
            
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
        // not good practce apparently
        // ¯\_(ツ)_/¯
        // self.window = UIWindow(frame: UIScreen.main.bounds)
        // (window?.rootViewController as? DefaultViewController)?.updateDislikes()
        
        
        // send notification within application that application will resign being active
        // apparently a better solution
        // TODO: add removeObserver
        NotificationCenter.default.post(name: .applicationWillResignActive, object: nil)
        print("ran applicationWillResignActive")
 
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

