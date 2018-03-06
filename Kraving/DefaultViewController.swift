//
//  DefaultViewController.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-12-15.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit
import CoreLocation
import SwiftyJSON
import Alamofire
import DeviceKit
import NotificationCenter

enum OpenClose {
    
    case open, close
    
}

enum SourceOfFunction {
    case settings, tableview, mainview, searchRadius
}

class SortByCollectionCell: UICollectionViewCell {
    
    @IBOutlet var sortByButton: UIButton!
    @IBOutlet var sortByLabel: UILabel!
    
}

class DefaultViewController: UIViewController, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, RemoveFromMainArray, SettingsDelegate, UpdateStatusBar {
    
    @IBOutlet var emptyView: UIView!
    @IBOutlet var emptyViewLabel: UILabel!
    @IBOutlet var increaseRadius: UIButton!
    
    @IBOutlet var loadingView: UIView!
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet var loadingText: UILabel!
    
    @IBOutlet var headerView: UIView!
    @IBOutlet var categoryTapView: UIView!
    @IBOutlet var currentCategory: UILabel!
    @IBOutlet var categoriesBtn: UIButton!
    @IBOutlet var sortedBy: UILabel!
    @IBOutlet var settingsBtn: UIButton!
    @IBOutlet var favouritesBtn: UIButton!
    
    
    @IBOutlet var cardPlaceholder: UIView!
    
    @IBOutlet var categoryAndSortByContainerView: UIView!
    
    // Categories/Sort By View
    @IBOutlet var categoriesTableView: UITableView!
    @IBOutlet var categoriesTitle: UILabel!
    @IBOutlet var categoriesSearchBar: UISearchBar!
    @IBOutlet var categoriesSearchButton: UIButton!
    
    @IBOutlet var sortByColletionView: UICollectionView!
    @IBOutlet var sortByTitle: UILabel!
    
    @IBOutlet var categoriesDoneButton: UIButton!
    
    @IBAction func unwindToMainController(segue: UIStoryboardSegue) {}
    
    var feedbackGenerator = UIImpactFeedbackGenerator()
    var defaults = UserDefaults.standard
    
    var restaurantCategories = [RestaurantCategory]()
    var filteredRestaurantCategories = [RestaurantCategory]()
    var sortByItems = ["Best Match", "Rating", "Review Count", "Distance"]
    var selectedCategory = String() // initialized in getCategories()
    var selectedSortBy = String() // initialized in setupView()
    var shouldSelectCell = false
    var didSelectCell = false
    
    var counter = 0.0
    var cornerRadius = Float()
    
    var currentRestaurants = [Restaurant]()
    var googleRestauarants = [GoogleRestaurant]()
    var restaurants = [Restaurant]()
    var likes = [Restaurant]()
    var dislikes = [Restaurant]()
    var restaurantIndex = 0
    var cards = [RestaurantCardView]()
    
    var locationManager = CLLocationManager()
    var locationToUse = String()
    var lat = Double()
    var long = Double()
    
    let device = Device()
    var plusDevices = [Device]()
    var smallDevices = [Device]()
        
    // UIKit dynamics variables for card animation
    var dynamicAnimator: UIDynamicAnimator!
    var cardAttachmentBehavior: UIAttachmentBehavior!
    var cardIntersectsWithStatusBar = false
    
    var statusBarShouldBeHidden = false
    
    override var prefersStatusBarHidden: Bool {
        return statusBarShouldBeHidden
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide // animation when opening/closing cardDetail
    }

    // MARK: - Default Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        dynamicAnimator = UIDynamicAnimator(referenceView: self.view)
        setDefaults()
        setupView()
        
    }

    // MARK: - Location delegate
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        // add some kind of error view telling user to allow location
        
        // if failed with error: dismiss view and go back to StartUpViewController
        self.dismiss(animated: true) {
            
        }
        
    }
    
    private var didPerformGeocode = false
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locationManager.stopUpdatingLocation()
        
        guard let location = locations.first, (locations.first?.horizontalAccuracy)! >= CLLocationAccuracy(0) else { return }
        
        // only make it run once since delegate has a habit of firing off multiple times
        guard !didPerformGeocode else { return }
        
        didPerformGeocode = true
        locationManager.stopUpdatingLocation()
        
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
            
            let coord = location.coordinate
            self.lat = coord.latitude
            self.long = coord.longitude
            
            self.searchRestaurants(.mainview)
            
        }
    }
    
    // MARK: - Functions
    
    func setupView() {
        
        loadingAnimator(.unhide) // unhide loading view
        
        // notification observer
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateDislikes), name: .applicationWillResignActive, object: nil)
        
        plusDevices = [.iPhone6Plus, .iPhone7Plus, .iPhone8Plus, .iPhoneX]
        smallDevices = [.iPhone5, .iPhone5c, .iPhone5s, .iPhoneSE, .iPodTouch5, .iPodTouch6]
        
        self.view.backgroundColor = UIColor.newWhite
        
        emptyView.alpha = 0
        emptyViewLabel.text = "That's All Folks!"
        selectedSortBy = "best_match"
        sortedBy.text = "Sorting by " + sortByItems[0]
        loadingIndicator.hidesWhenStopped = true
        
        categoriesTableView.dataSource = self
        categoriesTableView.delegate = self
        
        // set images
        let settingsImage = #imageLiteral(resourceName: "btn_settings_selected").withRenderingMode(.alwaysTemplate)
        let favouritesImage = #imageLiteral(resourceName: "happyHeart").withRenderingMode(.alwaysTemplate)
        let categoriesImage = #imageLiteral(resourceName: "chevron").withRenderingMode(.alwaysTemplate)
        settingsBtn.setImage(settingsImage, for: .normal)
        favouritesBtn.setImage(favouritesImage, for: .normal)
        categoriesBtn.setImage(categoriesImage, for: .normal)
        
        // set colors/tints
        categoriesBtn.imageView?.tintColor = UIColor.flatGray
        categoriesBtn.tintColor = UIColor.flatGray
        favouritesBtn.imageView?.tintColor = UIColor.flatGray
        favouritesBtn.tintColor = UIColor.flatGray
        settingsBtn.imageView?.tintColor = UIColor.flatGray
        settingsBtn.tintColor = UIColor.flatGray
        sortedBy.textColor = UIColor.flatGray
        currentCategory.textColor = UIColor.newBlack
        categoriesTitle.textColor = UIColor.newBlack
        sortByTitle.textColor = UIColor.newBlack
        
        // search bar
        
        categoriesSearchButton.tintColor = UIColor.newBlack
        categoriesSearchButton.setImage(UIBarButtonSystemItem.search.image(), for: .normal)
        categoriesSearchButton.addTarget(self, action: #selector(openSearchBar), for: .touchUpInside)
        
        categoriesSearchBar.delegate = self
        categoriesSearchBar.showsCancelButton = true
        categoriesSearchBar.alpha = 0 // used to animate it to open and close
        categoriesSearchBar.searchBarStyle = .minimal
        categoriesSearchBar.barStyle = .default
        categoriesSearchBar.tintColor = UIColor.newBlack
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.openCategories))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.numberOfTouchesRequired = 1
        categoryTapView.addGestureRecognizer(tapGesture)
        categoriesDoneButton.addTarget(self, action: #selector(self.doneButtonCaller(_:)), for: .touchUpInside)
                
        if CLLocationManager.locationServicesEnabled() && CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            
            // location services is main source
            locationManager.delegate = self
            locationManager.distanceFilter = 100
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            locationManager.requestLocation() // this is when requestLocation delegate function runs and user location is used for 'searchBusinesses' func
            
        } else {
            
            // address is main source
            self.searchRestaurants(.mainview)
            
        }
        
        // 3D Touch shortcut
        let icon = UIApplicationShortcutIcon(type: .love)
        let favouritesShortcutItem = UIApplicationShortcutItem(type: "com.omar.kravings.openfavourites", localizedTitle: "Favourites", localizedSubtitle: "", icon: icon, userInfo: nil)
        UIApplication.shared.shortcutItems = [favouritesShortcutItem]
        
        // table/collection view
        
        categoriesTableView.backgroundColor = UIColor.darkGray
        sortByColletionView.backgroundColor = UIColor.darkGray
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: sortByColletionView.bounds.size.width / 2, height: sortByColletionView.bounds.size.height / 2)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        sortByColletionView!.collectionViewLayout = layout
        
        // configure increase radius button
        setIncreaseRadiusButton()
        increaseRadius.setTitleColor(UIColor.flatWhite, for: [])
        increaseRadius.layer.cornerRadius = CGFloat(cornerRadius)
        increaseRadius.clipsToBounds = true
        increaseRadius.addTarget(self, action: #selector(increaseSearchRadius), for: .touchUpInside)
        
    }
    
    func setDefaults() {
        
        let locale = Locale.current
        let isMetric = locale.usesMetricSystem
        
        if defaults.integer(forKey: "searchRadius") == 0 {
            
            if isMetric {
                
                // searchRadius is in meters because metric (duh doi)
                defaults.set(5000, forKey: "searchRadius")
                
            } else {
                
                // searchRadius is in miles because screw the goddamn freedom country equivalents
                defaults.set(3, forKey: "searchRadius")
                
            }
            
        }
        
        if defaults.object(forKey: "defaultMaps") == nil {
            
            defaults.set("Apple Maps", forKey: "defaultMaps")
            
        }
        
        if defaults.object(forKey: "defaultBrowser") == nil {
            
            defaults.set("Safari", forKey: "defaultBrowser")
            
        }
        
        if defaults.object(forKey: "whichCell") == nil {
            
            defaults.set("", forKey: "whichCell")
            
        }
        
        if defaults.object(forKey: "cornerRadius") == nil {
            
            defaults.set(15, forKey: "cornerRadius")
            
        }
        
        cornerRadius = defaults.float(forKey: "cornerRadius")
        
    }
    
    func shouldHideCards(_ bool: Bool) {
        
        let yTranslation = CGFloat(Int(300 / 0.6))
        
        if bool {
            
            if self.cards.isEmpty {
                
                self.emptyView.alpha = 0
                
            } else if self.cards.count <= 4 {
                
                self.emptyView.alpha = 0
                
                for i in 0...self.cards.count - 1 {
                    
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                        self.cards[i].alpha = 0
                        self.cards[i].isUserInteractionEnabled = false
                        self.cards[i].transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
                        self.cards[i].transform = CGAffineTransform(translationX: 0, y: yTranslation)
                    }, completion: nil)

                }
                
            } else {
                
                self.emptyView.alpha = 0
                
                for i in 0...4 {
                    
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                        self.cards[i].alpha = 0
                        self.cards[i].isUserInteractionEnabled = false
                        self.cards[i].transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
                        self.cards[i].transform = CGAffineTransform(translationX: 0, y: yTranslation)
                    }, completion: nil)
                    
                }
                
            }
            
        } else {
            
            if self.cards.isEmpty {
                
                self.emptyView.alpha = 1
                
            } else if self.cards.count <= 4 {
                
                // self.emptyView.alpha = 1
                
                for i in 0...self.cards.count - 1 {
                    
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                        self.cards[i].alpha = 1
                        self.cards[i].isUserInteractionEnabled = true
                        self.cards[i].transform = CGAffineTransform.identity
                        self.layoutCards()
                    }, completion: nil)
                    
                }
                
            } else {
                
                // self.emptyView.alpha = 1
                
                for i in 0...4 {
                    
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                        self.cards[i].alpha = 1
                        self.cards[i].isUserInteractionEnabled = true
                        self.cards[i].transform = CGAffineTransform.identity
                        self.layoutCards()
                    }, completion: nil)
                    
                }
                
            }
            
        }
        
    }
    
    func openCategories() {
        
        let duration = 0.5
        let dampingRatio: CGFloat = 0.9
        let yTrans = CGFloat(Int(-300 / 0.6))
        
        let openView = UIViewPropertyAnimator(duration: duration, dampingRatio: dampingRatio) {
            
            self.headerView.transform = CGAffineTransform(translationX: 0, y: 900)
            self.headerView.alpha = 0
            
            self.shouldHideCards(true)
            
            self.categoryAndSortByContainerView.transform = CGAffineTransform.identity
            self.categoryAndSortByContainerView.alpha = 1
            
        }
        
        let closeView = UIViewPropertyAnimator(duration: duration, dampingRatio: dampingRatio) {
            
            self.categoryAndSortByContainerView.transform = CGAffineTransform(translationX: 0, y: yTrans)
            self.categoryAndSortByContainerView.alpha = 0
            
            self.headerView.transform = CGAffineTransform.identity
            self.headerView.alpha = 1
            
            self.shouldHideCards(false)
            
        }
        closeView.addCompletion { (position) in
            
            self.categoryAndSortByContainerView.isHidden = true
            
        }
        
        if categoryAndSortByContainerView.isHidden == true {
            
            self.categoryAndSortByContainerView.transform = CGAffineTransform(translationX: 0, y: yTrans)
            self.categoryAndSortByContainerView.isHidden = false
            
            openView.startAnimation()
            
        } else {
            
            closeView.startAnimation()
            
        }
        
    }
    
    func handleTableViewTap() {
        
        searchRestaurants(.tableview)
        
    }
    
    func loadingAnimator(_ attribute: LoadingOpener) {
        
        if attribute == .hide {
            
            // hide view
            self.loadingView.isHidden = true
            self.loadingIndicator.stopAnimating()
            
        } else {
            
            // open view
            self.loadingText.text = self.getLoadingLines()
            self.view.bringSubview(toFront: loadingView)
            self.loadingView.isHidden = false
            self.loadingIndicator.startAnimating()
            
        }
        
    }
    
    func getLoadingLines() -> String {
        
        guard let filePath = Bundle.main.url(forResource: "loadingLines", withExtension: "json") else { return "Loading..." }
        
        do {
            
            let jsonData = try Data(contentsOf: filePath)
            let json = try JSON(data: jsonData)
            let randomIndex = Int(arc4random_uniform(UInt32(json["lines"].arrayValue.count)))
            
            let loadingLine = json["lines"][randomIndex].stringValue
            
            return loadingLine
            
        } catch {
            return "Loading..."
        }

        
    }
    
    func timeConverter(_ time: String) -> String {
        
        var timeToUse = time
        timeToUse.insert(":", at: time.index(time.startIndex, offsetBy: 2))
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let dateToUse = timeFormatter.date(from: timeToUse)
        
        timeFormatter.dateFormat = "h:mm a"
        let date12 = timeFormatter.string(from: dateToUse!)
        
        return date12
        
        
    }
    
    func addToLikes(_ isFromPanGesture: Bool = false) {
        
        if !isFromPanGesture {
            
            // do same animation as pan gesture would by pressing button
            // code is taken from pan gesture
            
            // if card was snapped to center, it will remove the snapping behaviour which would stop the card from "flying" away
            dynamicAnimator.removeAllBehaviors()
            
            let restaurant = self.restaurants[self.restaurantIndex]
            self.likes.append(restaurant)
            
            var velocity = CGPoint()
            
            if device.isOneOf(smallDevices) {
                velocity = CGPoint(x: 240, y: 80) // sample taken from pan gesture
            } else {
                velocity = CGPoint(x: 980, y: 320) // sample taken from pan gesture
            }
            
            let pushBehavior = UIPushBehavior(items: [cards[0]], mode: .instantaneous)
            pushBehavior.pushDirection = CGVector(dx: velocity.x/10, dy: velocity.y/10)
            pushBehavior.magnitude = 240
            dynamicAnimator.addBehavior(pushBehavior)
            // spin after throwing
            var angular = CGFloat.pi / 2 // angular velocity of spin
            angular = angular * 1
            
            let itemBehavior = UIDynamicItemBehavior(items: [cards[0]])
            itemBehavior.friction = 0.2
            itemBehavior.allowsRotation = true
            itemBehavior.addAngularVelocity(CGFloat(angular), for: cards[0])
            dynamicAnimator.addBehavior(itemBehavior)
            
            showNextCard()
            hideFrontCard()
            
        } else {
            
            let restaurant = self.restaurants[self.restaurantIndex]
            self.likes.append(restaurant)
            
        }
        
    }
    
    func addToDislikes(_ isFromPanGesture: Bool = true) {
        
        if !isFromPanGesture {
            
            // do same animation as pan gesture would by pressing button
            // code is taken from pan gesture
            
            // if card was snapped to center, it will remove the snapping behaviour which would stop the card from "flying" away
            dynamicAnimator.removeAllBehaviors()
            
            let velocity = CGPoint(x: -980, y: 320) // sample taken from pan gesture
            
            let pushBehavior = UIPushBehavior(items: [cards[0]], mode: .instantaneous)
            pushBehavior.pushDirection = CGVector(dx: velocity.x/10, dy: velocity.y/10)
            pushBehavior.magnitude = 240
            dynamicAnimator.addBehavior(pushBehavior)
            // spin after throwing
            var angular = CGFloat.pi / 2 // angular velocity of spin
            angular = angular * -1
            
            let itemBehavior = UIDynamicItemBehavior(items: [cards[0]])
            itemBehavior.friction = 0.2
            itemBehavior.allowsRotation = true
            itemBehavior.addAngularVelocity(CGFloat(angular), for: cards[0])
            dynamicAnimator.addBehavior(itemBehavior)
            
            showNextCard()
            hideFrontCard()
            
        } else {
            
            // called by panGesture, animation is handled by handleCardPan()
            
            let restaurant = self.restaurants[self.restaurantIndex]
            self.dislikes.append(restaurant)
            
        }
        
    }
    
    func loadLongTermFavourites(completetionHandler: @escaping ([Restaurant]!) -> Void) {
        
        let favouritesExist = defaults.object(forKey: "favourites") != nil
        
        if favouritesExist {
            
            if let decodedArr = defaults.object(forKey: "favourites") as? Data {
                
                if let decodedRestaurants = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [Restaurant] {
                    
                    completetionHandler(decodedRestaurants)
                    
                }
                
            }
            
        } else {
            
            // no long term favourites
            completetionHandler(nil)
        }
        
    }
    
    func loadDislikes(completetionHandler: @escaping ([Restaurant]!) -> Void) {
        
        let dislikesExist = defaults.object(forKey: "dislikes") != nil
        
        if dislikesExist {
            
            if let decodedArr = defaults.object(forKey: "dislikes") as? Data {
                
                if let decodedRestaurants = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [Restaurant] {
                    
                    completetionHandler(decodedRestaurants)
                    
                }
                
            }
            
        } else {
            
            // no dislikes
            completetionHandler(nil)
        }
        
    }
    
    func removeDuplicates(array: [Restaurant]) -> [Restaurant] {
        var encounteredMap = [String]()
        var result: [Restaurant] = []
        for restaurant in array {
            if encounteredMap.contains(restaurant.id) {
                // Do not add a duplicate element.
            } else {
                // Add value to the set.
                encounteredMap.append(restaurant.id)
                // ... Append the value.
                result.append(restaurant)
            }
        }
        return result
    }
    
    func updateDislikes() {
        
        loadDislikes { (dislikesArray) in
            
            if var dislikesArr = dislikesArray {
                
                // dislikes exist
                dislikesArr.append(contentsOf: self.dislikes)
                let newArr = self.removeDuplicates(array: dislikesArr)
                let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: newArr)
                self.defaults.set(encodedData, forKey: "dislikes")
                self.defaults.synchronize()
                
            } else {
                
                // dislikes do not exist
                
                let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: self.dislikes)
                self.defaults.set(encodedData, forKey: "dislikes")
                self.defaults.synchronize()
                
            }
            
            
        }
        
    }
    
    func filterOutNonRestaurants(completetionHandler: @escaping ([Restaurant]!) -> Void) {
        
        let categoriesToRemove = ["Parks", "Hiking", "Veterinarians", "Shopping Centers", "Recreation Centers"]
        let filteredRestaurants = self.restaurants.filter{ !categoriesToRemove.contains($0.category) } // only return restaurants that don't match the mapped id
        
        completetionHandler(filteredRestaurants)
        
    }
    
    func removeFromLikesWith(_ index: Int, shouldRemoveAll: Bool) {
        
        // func for protocol RemoveFromMainArray
        // for removing likes in main view when removed in Favourites Controller
        
        if shouldRemoveAll {
            self.likes.removeAll()
        } else {
            self.likes.remove(at: index)
        }
        
    }
    
    func removeFromDislikesWith(_ index: Int, shouldRemoveAll: Bool) {
        
        // func for protocol RemoveFromMainArray
        // for removing dislikes in main view when removed in Favourites Controller
        
        if shouldRemoveAll {
            self.dislikes.removeAll()
        } else {
            self.dislikes.remove(at: index)
        }
        
    }
    
    func openSearchBar() {
        
        if categoriesSearchBar.alpha == 0 {
            
            // open search bar here
            UIView.animate(withDuration: 0.3, animations: {
                
                self.categoriesTitle.alpha = 0
                self.categoriesSearchButton.alpha = 0
                self.categoriesSearchBar.alpha = 1
                
            })
            
            self.categoriesSearchBar.becomeFirstResponder()
            
        } else {
            
            // close search bar here
            UIView.animate(withDuration: 0.3, animations: {
                
                self.categoriesTitle.alpha = 1
                self.categoriesSearchButton.alpha = 1
                self.categoriesSearchBar.alpha = 0
                
            })
            
            self.categoriesSearchBar.resignFirstResponder()
            
        }
        
    }
    
    func runCases(_ source: SourceOfFunction, completionHandler: @escaping (Bool) -> ()) {
        
        switch source {
        case .mainview:
            // runs when first searching for restaurants on app launch
            self.currentRestaurants.removeAll()
            self.restaurants.removeAll()
            self.cards.removeAll()
            self.restaurantIndex = 0
            self.getCategories(completionHandler: { (success) in
                
                if success {
                    self.shouldSelectCell = true // will be accessed in willDisplayCell to select first cell of categoriesTableView
                    
                    DispatchQueue.main.async {
                        print("got categories")
                        completionHandler(true)
                        self.currentCategory.text = self.restaurantCategories[0].title
                        self.categoriesTableView.reloadData()
                    }
                } else {
                    self.loadingText.text = "An error has occured while getting restaurants. Please try again later."
                }
                
            })
            
        case .settings:
            // runs when data changed through settings
            UIView.animate(withDuration: 0.4) {
                self.shouldHideCards(true)
            }
            // not running updateDislikes as it already runs when opening settings view
            self.restaurantIndex = 0
            self.restaurants.removeAll()
            self.currentRestaurants.removeAll()
            self.cards.removeAll()
            loadingAnimator(.unhide)
            completionHandler(true)
            
        case .tableview:
            // runs when category/sort changes through table view
            loadingAnimator(.unhide) // open loading view before closing categories for better effect
            self.updateDislikes()
            self.restaurantIndex = 0
            self.restaurants.removeAll()
            self.currentRestaurants.removeAll()
            self.cards.removeAll()
            categoriesSearchBar.resignFirstResponder() // get rid of keyboard
            openCategories() // TODO: fix header view poping up before loading shows when done button pressed
            completionHandler(true)
            
        case .searchRadius:
            // runs when increasing just search radius
            self.updateDislikes()
            self.restaurantIndex = 0
            self.restaurants.removeAll()
            self.cards.removeAll()
            loadingAnimator(.unhide)
            completionHandler(true)
            
        }
        
    }
    
    func searchRestaurants(_ source: SourceOfFunction, _ restaurantsToRemove: [Restaurant]? = nil) {
        
        runCases(source) { (success) in
            
            if success {
                
                print("ran cases")
                
                self.getGoogleRestaurants(completionHandler: { (success) in
                    
                    DispatchQueue.main.async {
                        self.resetCards()
                        self.loadingAnimator(.hide)
                    }
                    
                })
                
                /*
                
                self.searchBusinesses(self.lat, self.long, completetionHandler: { (success) in
                    
                    if success {
                        
                        self.loadLongTermFavourites(completetionHandler: { (arr) in
                            
                            if let arr = arr {
                                let mapped = Set(arr.map( {$0.id} )) // map out only id of longTermFavourites
                                let filteredRestaurants = self.restaurants.filter{ !mapped.contains($0.id) } // only return restaurants that don't match the mapped id
                                
                                self.restaurants = filteredRestaurants // replace restaurants with the filtered ones
                            }
                            
                            self.loadDislikes(completetionHandler: { (arr) in
                                
                                if let arr = arr {
                                    
                                    let mapped = Set(arr.map( {$0.id} )) // map out only id of longTermFavourites
                                    let filteredRestaurants = self.restaurants.filter{ !mapped.contains($0.id) } // only return restaurants that don't match the mapped id
                                    
                                    self.restaurants = filteredRestaurants // replace restaurants with the filtered ones
                                    
                                }
                                
                            })
                            
                            self.filterOutNonRestaurants(completetionHandler: { (newArr) in
                                
                                if let newArr = newArr {
                                    self.restaurants = newArr
                                }
                                
                                // filter out session favourites too
                                let mapped = self.likes.map( { $0.id } )
                                let filteredRestaurants = self.restaurants.filter{ !mapped.contains($0.id) } // only return restaurants that don't match the mapped id
                                self.restaurants = filteredRestaurants
                                
                                if let restaurantsToRemove = restaurantsToRemove {
                                    if source == .searchRadius && !restaurantsToRemove.isEmpty {
                                        
                                        let mapped = restaurantsToRemove.map( { $0.id } )
                                        let filteredRestaurants2 = self.restaurants.filter{ !mapped.contains($0.id) } // only return restaurants that don't match the mapped id
                                        self.restaurants = filteredRestaurants2
                                        
                                    }
                                }
                                
                                DispatchQueue.main.async {
                                    self.resetCards()
                                    self.loadingAnimator(.hide)
                                }
                                
                            })
                            
                        })
                        
                    } else {
                        
                        // TODO: - fix error handling
                        
                        if source == .tableview {
                            
                            let text = "No Results With Your Chosen Criteria \n \nTry Changing The Radius In Settings"
                            let attributedString = NSMutableAttributedString(string: text)
                            attributedString.setSizeForText("Try Changing The Radius In Settings", with: 21)
                            self.emptyViewLabel.attributedText = attributedString
                            
                            self.emptyViewLabel.numberOfLines = 0
                            self.emptyView.alpha = 1
                            self.loadingAnimator(.hide)
                            
                        } else {
                            
                            self.loadingText.text = "An error has occured while getting restaurants. Please try again later."
                            
                        }
                        
                        
                    }
                    
                })
 
                 */
            }
            
        }
        
    }
    
    func reloadView() {
        
        self.viewDidAppear(false)
        
    }
    
    func doneButtonCaller(_ button: UIButton) {
        
        if didSelectCell {
            loadingAnimator(.unhide)
            handleTableViewTap()
            didSelectCell = false // reset for selecting again
            openCategories()
        } else {
            openCategories()
        }
        
    }
    
    func setIncreaseRadiusButton() {
        
        // confirgure button at startup
        
        let isMetric = Locale.current.usesMetricSystem
        
        let radiusLimit = isMetric ? 40000 : 23
        let searchRadius = defaults.integer(forKey: "searchRadius")
        
        if isMetric {
            
            if searchRadius != radiusLimit {
                
                if 18...23 ~= searchRadius {
                    let increaseTitle = "Increase Radius By 1 km"
                    self.increaseRadius.setTitle(increaseTitle, for: [])
                } else {
                    let increaseTitle = "Increase Radius By 2 km"
                    self.increaseRadius.setTitle(increaseTitle, for: [])
                }
                
            } else {
                self.emptyViewLabel.text = self.emptyViewLabel.text! + "\nYou have reached the maximum radius limit of 40 km"
                self.increaseRadius.isEnabled = false
            }
            
        } else {
            
            if searchRadius != radiusLimit {
                
                if 18...23 ~= searchRadius {
                    let increaseTitle = "Increase Radius By 1 mile"
                    self.increaseRadius.setTitle(increaseTitle, for: [])
                } else {
                    let increaseTitle = "Increase Radius By 3 miles"
                    self.increaseRadius.setTitle(increaseTitle, for: [])
                }
                
            } else {
                // self.emptyViewLabel.text = self.emptyViewLabel.text! + "\n\nYou have reached the maximum radius limit of 23 miles"
                let limitString = isMetric ? "40 KM Reached" : "23 Miles Reached"
                self.increaseRadius.setTitle("Limit of " + limitString, for: [])
                self.increaseRadius.isUserInteractionEnabled = false
            }
            
        }
        
    }
    
    func increaseSearchRadius() {
        
        let isMetric = Locale.current.usesMetricSystem
        
        let radiusLimit = isMetric ? 40000 : 23
        
        var searchRadius = defaults.integer(forKey: "searchRadius")
        
        if isMetric {
            
            if searchRadius != radiusLimit {
                
                if 18...23 ~= searchRadius {
                    let increaseTitle = "Increase Radius By 1 km"
                    self.increaseRadius.setTitle(increaseTitle, for: [])
                    searchRadius += 1000
                } else {
                    let increaseTitle = "Increase Radius By 2 km"
                    self.increaseRadius.setTitle(increaseTitle, for: [])
                    searchRadius += 2000
                }
                
            } else {
                self.emptyViewLabel.text = self.emptyViewLabel.text! + "\nYou have reached the maximum radius limit of 40 km"
                self.increaseRadius.isEnabled = false
            }
            
        } else {
            
            if searchRadius != radiusLimit {
                
                if 18...23 ~= searchRadius {
                    let increaseTitle = "Increase Radius By 1 mile"
                    self.increaseRadius.setTitle(increaseTitle, for: [])
                    searchRadius += 1
                } else {
                    let increaseTitle = "Increase Radius By 3 miles"
                    self.increaseRadius.setTitle(increaseTitle, for: [])
                    searchRadius += 3
                }

            } else {
                // self.emptyViewLabel.text = self.emptyViewLabel.text! + "\n\nYou have reached the maximum radius limit of 23 miles"
                let limitString = isMetric ? "40 KM Reached" : "23 Miles Reached"
                self.increaseRadius.setTitle("Limit of " + limitString, for: [])
                self.increaseRadius.isUserInteractionEnabled = false
            }
            
        }
        
        defaults.set(searchRadius, forKey: "searchRadius")
        
        currentRestaurants += restaurants
        
        // current restaurants: resturants to not include when updating radius
        searchRestaurants(.searchRadius, currentRestaurants)
        
    }
    
    // MARK: - API Functions
    
    func getCategories(completionHandler: @escaping (Bool) -> ()) {
        
        let url = "https://www.yelp.com/developers/documentation/v3/all_category_list/categories.json"
        
        Alamofire.request(url).responseJSON { (response) in
            
            if let value = response.result.value {
                
                let json = JSON(value)
                
                for item in json.arrayValue {
                    
                    let thing = item["parents"].arrayValue
                    for things in thing {
                        
                        let parent = things.stringValue
                        if parent == "restaurants" {
                            // only return restaurants that fall under the parent category of restaurants
                            let category = RestaurantCategory(title: item["title"].stringValue, alias: item["alias"].stringValue)
                            self.restaurantCategories.append(category)
                        }
                    }
                    
                }
                self.restaurantCategories.insert(RestaurantCategory(title: "All Types", alias: "alltypes"), at: 0)
                DispatchQueue.main.async {
                    self.categoriesTableView.reloadData()
                }
                self.selectedCategory = "alltypes"
                
                completionHandler(true)
                
            } else {
                
                completionHandler(false)
                
            }
            
        }
        
    }
    
    func searchBusinesses(_ lat: Double, _ long: Double, completetionHandler: @escaping (Bool) -> Void) {
        
        let headers: HTTPHeaders = ["Authorization": "Bearer 8cHaNbcZ6-R4jvJN4KKAZn6pH8TsLJ341MB41avny9HLVOiawJHgbf6D21Hifmetesmx6jefbHJEYRc5j5ocrEeX0zlOMB_adj5mtUu_gdn6drQbWebaiJCej36RWnYx"]
        
        var searchRadius = defaults.integer(forKey: "searchRadius")
        
        let locale = Locale.current
        let isMetric = locale.usesMetricSystem
        
        if !isMetric {
            
            // convert searchRadius to meteres here from miles
            
            let numberFormatter = NumberFormatter()
            numberFormatter.maximumFractionDigits = 0
            let measurementFormatter = MeasurementFormatter()
            measurementFormatter.unitOptions = .providedUnit
            measurementFormatter.numberFormatter = numberFormatter
            
            let searchMiles = Measurement(value: Double(searchRadius), unit: UnitLength.miles)
            let searchMeters = searchMiles.converted(to: UnitLength.meters)
            
            let searchToUse = measurementFormatter.string(from: searchMeters)
            let oneReplaced = searchToUse.replacingOccurrences(of: " m", with: "")
            
            if let intVal = Int(oneReplaced) {
                
                searchRadius = intVal
                
            }
            
        }
        
        var url = ""
        
        switch self.selectedCategory {
        case "alltypes":
            
            url = "https://api.yelp.com/v3/businesses/search?radius=\(searchRadius)&latitude=\(lat)&longitude=\(long)&limit=50&sort_by=\(selectedSortBy)"
            
        default:
            
            url = "https://api.yelp.com/v3/businesses/search?radius=\(searchRadius)&latitude=\(lat)&longitude=\(long)&limit=50&categories=\(selectedCategory.lowercased())&sort_by=\(selectedSortBy)"
            
        }
        
        var name = String()
        var website = String()
        var image = UIImage()
        
        var rating = Int()
        var priceRange = String()
        var phone = String()
        var id = String()
        var closedBool = Bool()
        var restaurantCategory = String()
        var reviewCount = Int()
        var distance = Double()
        
        var city = String()
        var country = String()
        var state = String()
        var address = String()
        var zipCode = String()
        
        var transactions = [String]()
        
        Alamofire.request(url, headers: headers).responseJSON { response in
            
            if let value = response.result.value {
                
                let json = JSON(value)
                
                if json["total"].intValue == 0 {
                    
                    completetionHandler(false)
                    
                } else {
                    
                    for business in json["businesses"].arrayValue {
                        
                        name = business["name"].stringValue
                        website = business["url"].stringValue
                        let imageURL = business["image_url"].stringValue
                        rating = business["rating"].intValue
                        priceRange = business["price"].stringValue
                        phone = business["phone"].stringValue
                        id = business["id"].stringValue
                        closedBool = business["is_closed"].boolValue
                        reviewCount = business["review_count"].intValue
                        distance = business["distance"].doubleValue
                        
                        city = business["location"]["city"].stringValue
                        country = business["location"]["country"].stringValue
                        state = business["location"]["state"].stringValue
                        address = business["location"]["address1"].stringValue
                        zipCode = business["location"]["zip_code"].stringValue
                        
                        transactions = business["transactions"].arrayValue.map( { $0.string! } )
                        
                        if let upwrappedImageURL = URL(string: imageURL) {
                            
                            if let imageData = try? Data(contentsOf: upwrappedImageURL) {
                                
                                image = UIImage(data: imageData)!
                                
                            }
                            
                        } else {
                            
                            image = #imageLiteral(resourceName: "placeholderImage")
                            
                        }
                        
                        for category in business["categories"].arrayValue {
                            
                            restaurantCategory = category["title"].stringValue
                            
                        }
                        
                        let newRestaurant = Restaurant(name: name, website: website, image: image, rating: rating, priceRange: priceRange, phone: phone, id: id, isClosed: closedBool, category: restaurantCategory, reviewCount: reviewCount, distance: distance, city: city, country: country, state: state, address: address, zipCode: zipCode, transactions: transactions)
                        self.restaurants.append(newRestaurant)
                        
                    }
                    
                    completetionHandler(true)
                    
                }
                
            } else {
                
                // add refresh type of button to try to reload results
                
                completetionHandler(false)
                
            }
            
        }
        
    }
    
    func getGoogleRestaurants(completionHandler: @escaping (Bool) -> ()) {
        
        var searchRadius = defaults.integer(forKey: "searchRadius")
        
        let locale = Locale.current
        let isMetric = locale.usesMetricSystem
        
        if !isMetric {
            
            // convert searchRadius to meteres here from miles
            
            let numberFormatter = NumberFormatter()
            numberFormatter.maximumFractionDigits = 0
            let measurementFormatter = MeasurementFormatter()
            measurementFormatter.unitOptions = .providedUnit
            measurementFormatter.numberFormatter = numberFormatter
            
            let searchMiles = Measurement(value: Double(searchRadius), unit: UnitLength.miles)
            let searchMeters = searchMiles.converted(to: UnitLength.meters)
            
            let searchToUse = measurementFormatter.string(from: searchMeters)
            let oneReplaced = searchToUse.replacingOccurrences(of: " m", with: "")
            
            if let intVal = Int(oneReplaced) {
                
                searchRadius = intVal
                
            }
            
        }
        
        let stringUrl = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(lat),\(long)&radius=\(searchRadius)&type=restaurant&key=AIzaSyBfBphVionPiyoDp0KFcz_jrKwJIKiWStI"
        
        print(stringUrl)
        
        guard let url = URL(string: stringUrl) else { return }
        Alamofire.request(url).responseJSON { (response) in
            
            if let value = response.result.value {
                
                let json = JSON(value)
                
                if json["status"].stringValue == "OK" {
                    
                    for result in json["results"].arrayValue {
                        
                        let placeID = result["place_id"].stringValue
                        let name = result["name"].stringValue
                        let rating = result["rating"].doubleValue
                        let photo_reference = result["photos"][0]["photo_reference"].stringValue
                        let address = result["vicinity"].stringValue
                        let openNow = result["opening_hours"]["open_now"].boolValue
                        var heroImage = UIImage()
                        
                        if let unwrappedImageURL = URL(string: "https://maps.googleapis.com/maps/api/place/photo?maxheight=600&photoreference=\(photo_reference)&key=AIzaSyBfBphVionPiyoDp0KFcz_jrKwJIKiWStI") {
                            
                            print(unwrappedImageURL)
                            
                            if let imageData = try? Data(contentsOf: unwrappedImageURL) {
                                
                                heroImage = UIImage(data: imageData)!
                                
                            }
                            
                        } else {
                            
                            heroImage = #imageLiteral(resourceName: "placeholderImage")
                            
                        }
                        
                        let newRestaurant = GoogleRestaurant(placeId: placeID, name: name, website: "", heroImage: heroImage, images: [heroImage], rating: rating, priceRange: "", phone: "", openNow: openNow, distance: 0, address: address, timings: [""], types: [""])
                        self.googleRestauarants.append(newRestaurant)
                        
                        
                    }
                    
                    completionHandler(true)
                    
                } else {
                    
                    completionHandler(false)
                    
                }
                
            }
            
        }
        
    }
    
    func showBusinessDetails(_ id: String, completionHandler: @escaping ([RestaurantHours]) -> ()) {
        
        let headers = ["Authorization": "Bearer 8cHaNbcZ6-R4jvJN4KKAZn6pH8TsLJ341MB41avny9HLVOiawJHgbf6D21Hifmetesmx6jefbHJEYRc5j5ocrEeX0zlOMB_adj5mtUu_gdn6drQbWebaiJCej36RWnYx"]
        var restaurantHoursEmbedded = [RestaurantHours]()
        
        Alamofire.request("https://api.yelp.com/v3/businesses/\(id)", headers: headers).responseJSON { (Response) in
            
            if let value = Response.result.value {
                
                let json = JSON(value)
                
                for day in json["hours"].arrayValue {
                    
                    for thingy in day["open"].arrayValue {
                        
                        let isOvernight = thingy["is_overnight"].boolValue
                        
                        let openTime = self.timeConverter(thingy["start"].stringValue)
                        let endTime = self.timeConverter(thingy["end"].stringValue)
                        
                        var weekDay = String()
                        
                        switch thingy["day"].intValue {
                            
                        case 0:
                            weekDay = "Monday"
                        case 1:
                            weekDay = "Tuesday"
                        case 2:
                            weekDay = "Wednesday"
                        case 3:
                            weekDay = "Thursday"
                        case 4:
                            weekDay = "Friday"
                        case 5:
                            weekDay = "Saturday"
                        case 6:
                            weekDay = "Sunday"
                        default:
                            weekDay = "Unknown"
                            
                        }
                        
                        let dayToUse = RestaurantHours(day: weekDay, isOvernight: isOvernight, startTime: openTime, endTime: endTime)
                        restaurantHoursEmbedded.append(dayToUse)
                        
                    }
                    
                }
                
                completionHandler(restaurantHoursEmbedded)
            }
            
        }
        
    }
    
    // MARK: - Card Functions
    
    func resetCards() {
        
        self.cards.removeAll()
        
        if restaurants.count != 0 {
            
            for i in 0...self.restaurants.count - 1 {
                
                let card = RestaurantCardView(frame: CGRect(x: 0, y: 0, width: cardPlaceholder.bounds.size.width, height: cardPlaceholder.bounds.size.height))
                card.restaurant = self.restaurants[i]
                self.cards.append(card)
                
            }
            
            // layout the first 4 cards for the user
            self.layoutCards()
            
        } else {
            
            loadingAnimator(.unhide)
            emptyView.alpha = 1
            
        }
        
    }
    
    // Scale and alpha of successive cards visible to the user
    let cardAttributes: [(downscale: CGFloat, alpha: CGFloat)] = [(1, 1), (0.92, 0.8), (0.84, 0.6), (0.76, 0.4)]
    
    let cardInteritemSpacing: CGFloat = 10
    
    func layoutCards() {
        
        let firstCard = cards[0]
        self.view.addSubview(firstCard)
        firstCard.layer.zPosition = CGFloat(cards.count)
        firstCard.center = self.cardPlaceholder.center
        firstCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openCardDetail)))
        firstCard.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleCardPan)))
        shadowTo(firstCard, shouldRemove: false) // add shadow to card
        
        // the next 3 cards in the deck
        for i in 1...3 {
            if i > (cards.count - 1) { continue }
            
            let card = cards[i]
            
            card.layer.zPosition = CGFloat(cards.count - i)
            
            // here we're just getting some hand-picked vales from cardAttributes (an array of tuples)
            // which will tell us the attributes of each card in the 4 cards visible to the user
            let downscale = cardAttributes[i].downscale
            let alpha = cardAttributes[i].alpha
            card.transform = CGAffineTransform(scaleX: downscale, y: downscale)
            card.alpha = alpha
            
            // position each card so there's a set space (cardInteritemSpacing) between each card, to give it a fanned out look
            card.center.x = self.cardPlaceholder.center.x
            card.frame.origin.y = cards[0].frame.origin.y - (CGFloat(i) * cardInteritemSpacing)
            // workaround: scale causes heights to skew so compensate for it with some tweaking
            if i == 3 {
                card.frame.origin.y += 1.5
            }
            
            self.view.addSubview(card)
        }
        
        // make sure that the first card in the deck is at the front
        self.view.bringSubview(toFront: cards[0])
        
    }
    
    /// This is called whenever the front card is swiped off the screen or is animating away from its initial position.
    /// showNextCard() just adds the next card to the 4 visible cards and animates each card to move forward.
    func showNextCard() {
        let animationDuration: TimeInterval = 0.2
        // 1. animate each card to move forward one by one
        for i in 1...3 {
            if i > (cards.count - 1) { continue }
            let card = cards[i]
            let newDownscale = cardAttributes[i - 1].downscale
            let newAlpha = cardAttributes[i - 1].alpha
            UIView.animate(withDuration: animationDuration, delay: (TimeInterval(i - 1) * (animationDuration / 2)), usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: [], animations: {
                card.transform = CGAffineTransform(scaleX: newDownscale, y: newDownscale)
                card.alpha = newAlpha
                if i == 1 {
                    card.center = self.cardPlaceholder.center
                } else {
                    card.center.x = self.cardPlaceholder.center.x
                    card.frame.origin.y = self.cards[1].frame.origin.y - (CGFloat(i - 1) * self.cardInteritemSpacing)
                }
            }, completion: { (_) in
                if i == 1 {
                    // increase index for current restaurant everytime new card shows up
                    self.restaurantIndex += 1
                    card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.openCardDetail)))
                    card.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.handleCardPan)))
                    self.shadowTo(card, shouldRemove: false) // add shadow to card
                }
            })
            
        }
        
        // 2. add a new card (now the 4th card in the deck) to the very back
        if 4 > (cards.count - 1) {
            if cards.count != 1 {
                self.view.bringSubview(toFront: cards[1])
            }
            return
        }
        let newCard = cards[4]
        newCard.layer.zPosition = CGFloat(cards.count - 4)
        let downscale = cardAttributes[3].downscale
        let alpha = cardAttributes[3].alpha
        
        // initial state of new card
        newCard.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        newCard.alpha = 0
        newCard.center.x = self.cardPlaceholder.center.x
        newCard.frame.origin.y = cards[1].frame.origin.y - (4 * cardInteritemSpacing)
        self.view.addSubview(newCard)
        
        // animate to end state of new card
        UIView.animate(withDuration: animationDuration, delay: (3 * (animationDuration / 2)), usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: [], animations: {
            newCard.transform = CGAffineTransform(scaleX: downscale, y: downscale)
            newCard.alpha = alpha
            newCard.center.x = self.cardPlaceholder.center.x
            newCard.frame.origin.y = self.cards[1].frame.origin.y - (3 * self.cardInteritemSpacing) + 1.5
        }, completion: { (_) in
            
        })
        // first card needs to be in the front for proper interactivity
        self.view.bringSubview(toFront: self.cards[1])
        
    }
    
    func removeOldFrontCard() {
        cards[0].removeFromSuperview()
        cards.remove(at: 0)
        
    }
    
    func handleCardPan(sender: UIPanGestureRecognizer) {
        
        // if we're in the process of hiding a card, don't let the user interace with the cards yet
        if cardIsHiding { return }
        // distance user must pan right or left to trigger an option
        let requiredOffsetFromCenter: CGFloat = 10
        
        guard let card = sender.view else { return }
        guard let cardRestaurant = card as? RestaurantCardView else { return }
        let statusBar = UIApplication.shared.statusBarFrame
        
        let panLocationInView = sender.location(in: view)
        let panLocationInCard = sender.location(in: cards[0])
        
        let animationTiming: Double = 0.1
        
        switch sender.state {
        case .began:
            // shadowTo(card, shouldRemove: true)
            dynamicAnimator.removeAllBehaviors()
            let offset = UIOffsetMake(panLocationInCard.x - cards[0].bounds.midX, panLocationInCard.y - cards[0].bounds.midY);
            // card is attached to center
            cardAttachmentBehavior = UIAttachmentBehavior(item: cards[0], offsetFromCenter: offset, attachedToAnchor: panLocationInView)
            dynamicAnimator.addBehavior(cardAttachmentBehavior)
            
        case .changed:
            cardAttachmentBehavior.anchorPoint = panLocationInView
            
            if card.frame.intersects(statusBar) && cardIntersectsWithStatusBar {
                if !statusBarShouldBeHidden {
                    statusBarShouldBeHidden = true
                    UIView.animate(withDuration: 0.25) {
                        self.setNeedsStatusBarAppearanceUpdate()
                    }
                }
            } else if card.frame.intersects(statusBar) {
                cardIntersectsWithStatusBar = true
            }
            
            if cards[0].center.x > (self.cardPlaceholder.center.x + requiredOffsetFromCenter) {
                // show likes (going towards the right)
                
                UIView.animate(withDuration: animationTiming, animations: {
                    
                    cardRestaurant.thumbsUpDownImage.image = #imageLiteral(resourceName: "happyHeart").withRenderingMode(.alwaysTemplate)
                    cardRestaurant.thumbsUpDownView.backgroundColor = UIColor.flatGreen
                    
                    if cardRestaurant.thumbsUpDownView.alpha == 0 {
                        cardRestaurant.thumbsUpDownView.alpha = 1
                    }
                    
                })
                
            } else if cards[0].center.x < (self.view.center.x - requiredOffsetFromCenter) {
                // show dislikes (going towards the left)
                
                UIView.animate(withDuration: animationTiming, animations: {
                    
                    cardRestaurant.thumbsUpDownImage.image = #imageLiteral(resourceName: "notHappyHeart").withRenderingMode(.alwaysTemplate)
                    cardRestaurant.thumbsUpDownView.backgroundColor = UIColor.flatRed
                    
                    if cardRestaurant.thumbsUpDownView.alpha == 0 {
                        cardRestaurant.thumbsUpDownView.alpha = 1
                    }
                    
                })
                
            } else {
                // fade it out (center)
                UIView.animate(withDuration: animationTiming, animations: {
                    cardRestaurant.thumbsUpDownView.alpha = 0
                })
                
            }
            
        case .ended:
            
            dynamicAnimator.removeAllBehaviors()
            
            if statusBarShouldBeHidden && !card.frame.intersects(statusBar) {
                statusBarShouldBeHidden = false
                UIView.animate(withDuration: 0.25) {
                    self.setNeedsStatusBarAppearanceUpdate()
                }
            }
            
            if !(cards[0].center.x > (self.cardPlaceholder.center.x + requiredOffsetFromCenter) || cards[0].center.x < (self.view.center.x - requiredOffsetFromCenter)) {
                // snap to center
                let snapBehavior = UISnapBehavior(item: cards[0], snapTo: self.cardPlaceholder.center)
                dynamicAnimator.addBehavior(snapBehavior)
                
                UIView.animate(withDuration: 0.2, animations: {
                    cardRestaurant.thumbsUpDownImage.image = nil
                    cardRestaurant.thumbsUpDownView.backgroundColor = nil
                    cardRestaurant.thumbsUpDownView.alpha = 0
                })
                self.statusBarShouldBeHidden = false
                UIView.animate(withDuration: 0.25) {
                    self.setNeedsStatusBarAppearanceUpdate()
                }
            } else {
                
                let velocity = sender.velocity(in: self.view)
                let pushBehavior = UIPushBehavior(items: [cards[0]], mode: .instantaneous)
                pushBehavior.pushDirection = CGVector(dx: velocity.x/10, dy: velocity.y/10)
                pushBehavior.magnitude = 175
                dynamicAnimator.addBehavior(pushBehavior)
                // spin after throwing
                var angular = CGFloat.pi / 2 // angular velocity of spin
                
                let currentAngle: Double = atan2(Double(cards[0].transform.b), Double(cards[0].transform.a))
                
                if currentAngle > 0 {
                    angular = angular * 1
                } else {
                    angular = angular * -1
                }
                let itemBehavior = UIDynamicItemBehavior(items: [cards[0]])
                itemBehavior.friction = 0.2
                itemBehavior.allowsRotation = true
                itemBehavior.addAngularVelocity(CGFloat(angular), for: cards[0])
                dynamicAnimator.addBehavior(itemBehavior)
                
                if cards[0].center.x > (self.cardPlaceholder.center.x + requiredOffsetFromCenter) {
                    // like
                    self.addToLikes(true)
                } else if cards[0].center.x < (self.view.center.x - requiredOffsetFromCenter) {
                    // dislike
                    self.addToDislikes(true)
                }
                UIView.animate(withDuration: 0.2, animations: {
                    cardRestaurant.thumbsUpDownView.alpha = 1
                })
                
                self.statusBarShouldBeHidden = false
                UIView.animate(withDuration: 0.25) {
                    self.setNeedsStatusBarAppearanceUpdate()
                }
                
                showNextCard()
                hideFrontCard()
                
            }
            
        default:
            break
        }
        
    }
    
    /// This function continuously checks to see if the card's center is on the screen anymore. If it finds that the card's center is not on screen, then it triggers removeOldFrontCard() which removes the front card from the data structure and from the view.
    var cardIsHiding = false
    func hideFrontCard() {
        if #available(iOS 10.0, *) {
            var cardRemoveTimer: Timer? = nil
            cardRemoveTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] (_) in
                guard self != nil else { return }
                if !(self!.view.bounds.contains(self!.cards[0].center)) {
                    cardRemoveTimer!.invalidate()
                    self?.cardIsHiding = true
                    UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseIn], animations: {
                        self?.cards[0].alpha = 0.0
                    }, completion: { (_) in
                        self?.removeOldFrontCard()
                        self?.cardIsHiding = false
                        if (self?.cards.isEmpty)! {
                            let text = "That's All Folks!"
                            self?.emptyViewLabel.text = text
                            self?.emptyView.alpha = 1
                            // disable buttons if empty here
                        }
                        // re-enable buttons after addToLikes/Dislikes function is run to prevent rapid tapping
                        
                    })
                }
            })
        } else {
            // fallback for earlier versions
            UIView.animate(withDuration: 0.2, delay: 1.5, options: [.curveEaseIn], animations: {
                self.cards[0].alpha = 0.0
            }, completion: { (_) in
                self.removeOldFrontCard()
                if self.cards.isEmpty {
                    // disable buttons if empty here
                    self.emptyView.alpha = 1
                }
                // re-enable buttons after addToLikes/Dislikes function is run to prevent rapid tapping
            })
        }
    }
    
    func shadowTo(_ card: UIView, shouldRemove: Bool) {
        
        if shouldRemove {
            
            let animation = CABasicAnimation(keyPath: "shadowOpacity")
            animation.fromValue = card.layer.shadowOpacity
            animation.toValue = 0.0
            animation.duration = 0.3
            card.layer.add(animation, forKey: animation.keyPath)
            card.layer.shadowOpacity = 0.0
            
            card.layer.shadowPath = nil
            
        } else {
            
            card.clipsToBounds = false
            card.layer.shadowColor = UIColor(averageColorFrom: self.restaurants[self.restaurantIndex].heroImage).withAlphaComponent(0.65).cgColor
            card.layer.shadowOffset = CGSize(width: 0, height: 8)
            card.layer.shadowRadius = 12
            card.layer.shadowPath = UIBezierPath(roundedRect: card.bounds, cornerRadius: CGFloat(cornerRadius)).cgPath
            
            let animation = CABasicAnimation(keyPath: "shadowOpacity")
            animation.fromValue = card.layer.shadowOpacity
            animation.toValue = 1.0
            animation.duration = 0.3
            card.layer.add(animation, forKey: animation.keyPath)
            card.layer.shadowOpacity = 1.0
            
        }
        
    }
    
    func openCardDetail() {
        
        let restaurant = self.restaurants[self.restaurantIndex]
        
        let vc = storyboard?.instantiateViewController(withIdentifier: "RestaurantDetailController") as! RestaurantDetailController
        vc.restaurant = restaurant
        vc.parentSource = .defaultController
        vc.modalPresentationStyle = .overCurrentContext
        vc.statusBarDelegate = self // for updating status bar in this view when dismiss modal
        
        // hide status bar with animation
        statusBarShouldBeHidden = true
        UIView.animate(withDuration: 0.25) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
        
        // present modal view
        present(vc, animated: true, completion: nil)
        
    }
    
    // MARK: - Status bar delegate
    
    func updateStatusBar() {
        
        statusBarShouldBeHidden = false
        UIView.animate(withDuration: 0.25) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
        
    }
    
    // MARK: - Settings Delegate
    
    func dataChanged() {
        
        searchRestaurants(.settings)
        
    }
    
    // MARK: - Table view
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if shouldSelectCell {
            
            if tableView == categoriesTableView && indexPath.row == 0 {
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! CategoryTableViewCell
                cell.setSelected(true, animated: true)
                
            }
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        didSelectCell = true
        
        if categoriesSearchBar.alpha == 1 {
            self.selectedCategory = self.filteredRestaurantCategories[indexPath.row].alias
            self.currentCategory.text = self.filteredRestaurantCategories[indexPath.row].title
        } else {
            self.selectedCategory = self.restaurantCategories[indexPath.row].alias
            self.currentCategory.text = self.restaurantCategories[indexPath.row].title
        }
        
        self.shouldSelectCell = false
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if categoriesSearchBar.alpha == 1 {
            return filteredRestaurantCategories.count
        } else {
            return restaurantCategories.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CategoryTableViewCell
        
        if categoriesSearchBar.alpha == 1 {
            cell.categoryLabel.text = filteredRestaurantCategories[indexPath.row].title
        } else {
            cell.categoryLabel.text = restaurantCategories[indexPath.row].title
        }
        
        return cell
        
    }
    
    // MARK: - Collection view
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sortByItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        var sortBy = sortByItems[indexPath.row]
        self.sortedBy.text = "Sorting by " + sortBy
        sortBy = sortBy.replacingOccurrences(of: " ", with: "_")
        sortBy = sortBy.lowercased()
        self.selectedSortBy = sortBy
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "sortByCell", for: indexPath) as! SortByCollectionCell
        
        let sortTitle = sortByItems[indexPath.row]
        cell.sortByLabel.text = sortTitle
        cell.sortByLabel.textColor = UIColor.white
        
        let newSelectionView = UIView(frame: cell.bounds)
        newSelectionView.backgroundColor = UIColor.darkGray.darken(byPercentage: 0.2)
        cell.selectedBackgroundView = newSelectionView
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = collectionView.bounds.size.width
        let height = collectionView.bounds.size.height
        
        return CGSize(width: width / 2, height: height / 2)
        
    }
    
    // MARK: - UISearchBar Functions
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        filterResults(searchText)
        
    }
    
    func filterResults(_ searchText: String) {
        
        filteredRestaurantCategories = restaurantCategories.filter({ (category) -> Bool in
            return category.title.lowercased().contains(searchText.lowercased())
        })
        self.categoriesTableView.reloadData()
        
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        openSearchBar()
        categoriesSearchBar.text = "" // clears potential remaining text
        categoriesTableView.reloadData() // get rid of potential filtered searches remaining in table view
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        openSearchBar()
        self.categoriesSearchBar.text = "" // clears potential remaining text
        // self.categoriesTableView.reloadData() // get rid of potential filtered searches remaining in table view
        
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "settingsSegue" {
            
            self.updateDislikes()
            
            let destVC = (segue.destination as! UINavigationController).topViewController as? SettingsTableViewController
            destVC?.modalPresentationStyle = .overCurrentContext
            destVC?.delegate = self
            
        } else if segue.identifier == "favouritesSegue" {
            
            self.updateDislikes()
            
            let destVC = (segue.destination as! UINavigationController).topViewController as? FavouritesContainerController
            destVC?.likes = self.likes
            destVC?.modalPresentationStyle = .overCurrentContext
            destVC?.removeDelegate = self
            
        }
        
    }

}
