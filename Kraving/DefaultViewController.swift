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

extension Notification.Name {
    static let applicationWillResignActive = Notification.Name(rawValue: "applicationWillResignActive")
}

extension UIBarButtonSystemItem {
    
    func image() -> UIImage? {
        let tempItem = UIBarButtonItem(barButtonSystemItem: self, target: nil, action: nil)
        
        // add to toolbar and render it
        let bar = UIToolbar()
        bar.setItems([tempItem],
                     animated: false)
        bar.snapshotView(afterScreenUpdates: true)
        
        // got image from real uibutton
        let itemView = tempItem.value(forKey: "view") as! UIView
        for view in itemView.subviews {
            if let button = view as? UIButton,
                let image = button.imageView?.image {
                return image.withRenderingMode(.alwaysTemplate)
            }
        }
        
        return nil
    }
}

extension UIView {
    
    func applyGradient(colours: [UIColor]) -> Void {
        self.applyGradient(colours: colours, locations: nil)
    }
    
    func applyGradient(colours: [UIColor], locations: [NSNumber]?) -> Void {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = colours.map { $0.cgColor }
        gradient.locations = locations
        self.layer.insertSublayer(gradient, at: 0)
    }
    
}

extension NSMutableAttributedString {
    
    func setColorForText(_ textToFind: String, with color: UIColor) {
        let range = self.mutableString.range(of: textToFind, options: .caseInsensitive)
        if range.location != NSNotFound {
            addAttribute(NSForegroundColorAttributeName, value: color, range: range)
        }
    }
    
    func setColorForRange(_ range: NSRange, with color: UIColor) {
        if range.location != NSNotFound {
            addAttribute(NSForegroundColorAttributeName, value: color, range: range)
        }
    }
    
    func setBoldForText(_ textToFind: String) {
        let range = self.mutableString.range(of: textToFind, options: .caseInsensitive)
        if range.location != NSNotFound {
            let attrs = [NSFontAttributeName : UIFont.boldSystemFont(ofSize: 18)]
            addAttributes(attrs, range: range)
        }
        
    }
    
    func setSizeForText(_ textToFind: String, with size: CGFloat) {
        let range = self.mutableString.range(of: textToFind, options: .caseInsensitive)
        if range.location != NSNotFound {
            let attrs = [NSFontAttributeName : UIFont.systemFont(ofSize: size)]
            addAttributes(attrs, range: range)
        }
        
    }
    
}

extension String {
    
    init(htmlEncodedString: String) {
        do {
            let encodedData = htmlEncodedString.data(using: String.Encoding.utf8)!
            let attributedOptions : [String: AnyObject] = [
                NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType as AnyObject,
                NSCharacterEncodingDocumentAttribute: NSNumber(value: String.Encoding.utf8.rawValue)
            ]
            let attributedString = try NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil)
            self.init(attributedString.string)!
        } catch {
            fatalError("Unhandled error: \(error)")
        }
    }
    
    var first: String {
        return String(self.prefix(1))
    }
    
    var last: String {
        return String(self.suffix(1))
    }
    
    var uppercaseFirst: String {
        return first.uppercased() + String(self.dropFirst())
    }
    
}

class DefaultViewController: UIViewController, CLLocationManagerDelegate, SettingsDelegate, UITableViewDelegate, UITableViewDataSource, RemoveFromMainArray, UISearchBarDelegate {
    
    @IBOutlet var thatsAllFolks: UILabel!
    @IBOutlet var loadingView: UIView!
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet var loadingText: UILabel!
    
    @IBOutlet var categoryAndSortByContainerView: UIView!
    @IBOutlet var categoriesTableView: UITableView!
    @IBOutlet var categoriesHeaderView: UIVisualEffectView!
    @IBOutlet var categoriesTitle: UILabel!
    @IBOutlet var categoriesDoneButton: UIButton!
    @IBOutlet var categoriesSearchBar: UISearchBar!
    @IBOutlet var categoriesSearchButton: UIButton!
    @IBOutlet var sortByHeaderView: UIVisualEffectView!
    @IBOutlet var sortByTableView: UITableView!
    
    @IBOutlet var buttonsStackView: UIStackView!
    @IBOutlet var settingsBtn: UIButton!
    @IBOutlet var categoriesBtn: UIButton!
    @IBOutlet var favouritesBtn: UIButton!
    @IBOutlet var dislikeBtn: UIButton!
    @IBOutlet var likeBtn: UIButton!
    
    @IBAction func unwindToMainController(segue: UIStoryboardSegue) {}
    
    var feedbackGenerator = UIImpactFeedbackGenerator()
    var defaults = UserDefaults.standard
        
    var divisor: CGFloat!
    var categories = [String]()
    var filteredCategories = [String]()
    var sortByItems = ["Best Match", "Rating", "Review Count", "Distance"]
    var selectedCategory = String() // initialized in getCategories()
    var selectedSortBy = String() // initialized in setupView()
    var shouldSelectCell = false
    
    var accessToken = String()
    
    var restaurants = [Restaurant]()
    var likes = [Restaurant]()
    var dislikes = [Restaurant]()
    var restaurantIndex = 0
    
    var locationManager = CLLocationManager()
    var locationToUse = String()
    var lat = Double()
    var long = Double()
    
    var cards = [RestaurantCard]()
    let device = Device()
    var plusDevices = [Device]()
        
    // UIKit dynamics variables for card animation
    var dynamicAnimator: UIDynamicAnimator!
    var cardAttachmentBehavior: UIAttachmentBehavior!
    var cardIntersectsWithStatusBar = false
    
    var statusBarShouldBeHidden = false
    
    override var prefersStatusBarHidden: Bool {
        return statusBarShouldBeHidden
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide // animation when opening/closing carDetail
    }

    // MARK: - Default Functions
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        statusBarShouldBeHidden = false
        UIView.animate(withDuration: 0.25) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        divisor = (view.frame.width / 2) / 0.61
        dynamicAnimator = UIDynamicAnimator(referenceView: self.view)
        setDefaults()
        setupView()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
                
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
            
            self.searchRestaurants()
            
        }
    }
    
    // MARK: - Functions
    
    func setupView() {
        
        // notification observer
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateDislikes), name: .applicationWillResignActive, object: nil)
        
        plusDevices = [.iPhone6Plus, .iPhone7Plus, .iPhone8Plus, .iPhoneX]
        
        self.thatsAllFolks.text = "That's All Folks!"
        self.selectedSortBy = "best_match"
        self.loadingIndicator.hidesWhenStopped = true
        loadingAnimator(.unhide)
        
        self.categoriesTableView.dataSource = self
        self.categoriesTableView.delegate = self
        
        self.sortByTableView.dataSource = self
        self.sortByTableView.delegate = self
        
        if device.isOneOf(plusDevices) {
            
            setInsets(22) // insets for main 3 buttons, increase number to make them smaller
            likeBtn.layer.cornerRadius = 30
            dislikeBtn.layer.cornerRadius = 30
            
        } else {
            
            setInsets(18) // insets for main 3 buttons, increase number to make them smaller
            likeBtn.layer.cornerRadius = 20
            dislikeBtn.layer.cornerRadius = 20
            
        }
        
        let image1S = #imageLiteral(resourceName: "btn_categories_selected").withRenderingMode(.alwaysTemplate)
        let image2S = #imageLiteral(resourceName: "btn_openFavourites_selected").withRenderingMode(.alwaysTemplate)
        let image3S = #imageLiteral(resourceName: "btn_settings_selected").withRenderingMode(.alwaysTemplate)
        let image4S = #imageLiteral(resourceName: "btn_addToFavourites_selected").withRenderingMode(.alwaysTemplate)
        let image5S = #imageLiteral(resourceName: "btn_removeFavourites_selected").withRenderingMode(.alwaysTemplate)
        
        categoriesBtn.setImage(image1S, for: .normal)
        categoriesBtn.setImage(image1S, for: UIControlState.highlighted)
        categoriesBtn.imageView?.tintColor = UIColor.flatGray
        categoriesBtn.imageView?.contentMode = .scaleAspectFit
        categoriesBtn.tintColor = UIColor.flatGray
        
        favouritesBtn.setImage(image2S, for: .normal)
        favouritesBtn.setImage(image2S, for: UIControlState.highlighted)
        favouritesBtn.imageView?.tintColor = UIColor.flatGray
        favouritesBtn.imageView?.contentMode = .scaleAspectFit
        favouritesBtn.tintColor = UIColor.flatGray
        
        settingsBtn.setImage(image3S, for: .normal)
        settingsBtn.setImage(image3S, for: UIControlState.highlighted)
        settingsBtn.imageView?.tintColor = UIColor.flatGray
        settingsBtn.imageView?.contentMode = .scaleAspectFit
        settingsBtn.tintColor = UIColor.flatGray
        
        likeBtn.setImage(image4S, for: .normal)
        likeBtn.setImage(image4S, for: UIControlState.highlighted)
        likeBtn.imageView?.tintColor = UIColor.white
        likeBtn.imageView?.contentMode = .scaleAspectFit
        likeBtn.tintColor = UIColor.white
        likeBtn.clipsToBounds = true
        likeBtn.backgroundColor = UIColor.flatGreen
        
        dislikeBtn.setImage(image5S, for: .normal)
        dislikeBtn.setImage(image5S, for: UIControlState.highlighted)
        dislikeBtn.imageView?.tintColor = UIColor.white
        dislikeBtn.imageView?.contentMode = .scaleAspectFit
        dislikeBtn.tintColor = UIColor.white
        dislikeBtn.clipsToBounds = true
        dislikeBtn.backgroundColor = UIColor.flatRed
        
        categoriesDoneButton.alpha = 0 // for animation stuff
        
        // search bar
        
        categoriesSearchButton.tintColor = UIColor.white
        categoriesSearchButton.setImage(UIBarButtonSystemItem.search.image(), for: .normal)
        categoriesSearchButton.addTarget(self, action: #selector(openSearchBar), for: .touchUpInside)
        
        categoriesSearchBar.delegate = self
        categoriesSearchBar.showsCancelButton = true
        categoriesSearchBar.alpha = 0 // used to animate it to open and close
        categoriesSearchBar.searchBarStyle = .minimal
        categoriesSearchBar.barStyle = .blackTranslucent
        categoriesSearchBar.tintColor = UIColor.white
        
        likeBtn.addTarget(self, action: #selector(self.popButton(button:_:)), for: .touchUpInside)
        dislikeBtn.addTarget(self, action: #selector(self.popButton(button:_:)), for: .touchUpInside)
        
        categoriesBtn.addTarget(self, action: #selector(self.openCategories), for: .touchUpInside)
        categoriesDoneButton.addTarget(self, action: #selector(self.openCategories), for: .touchUpInside)
        
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
            searchRestaurants()
            
        }
        
        // 3D Touch shortcut
        let icon = UIApplicationShortcutIcon(type: .love)
        let favouritesShortcutItem = UIApplicationShortcutItem(type: "com.omar.kravings.openfavourites", localizedTitle: "Favourites", localizedSubtitle: "", icon: icon, userInfo: nil)
        UIApplication.shared.shortcutItems = [favouritesShortcutItem]
        
        // table views
        
        categoriesTableView.backgroundColor = UIColor.darkGray
        sortByTableView.backgroundColor = UIColor.darkGray
        
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
        
    }
    
    func setInsets(_ number: CGFloat) {
        
        settingsBtn.imageEdgeInsets = UIEdgeInsets(top: number, left: 0, bottom: number, right: 0)
        categoriesBtn.imageEdgeInsets = UIEdgeInsets(top: number, left: 0, bottom: number, right: 0)
        favouritesBtn.imageEdgeInsets = UIEdgeInsets(top: number, left: 0, bottom: number, right: 0)
        
        if device.isOneOf(plusDevices) {
            
            likeBtn.imageEdgeInsets = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
            dislikeBtn.imageEdgeInsets = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
            
        } else {
            
            likeBtn.imageEdgeInsets = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
            dislikeBtn.imageEdgeInsets = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
            
        }
        
    }
    
    func shouldHideCards(_ bool: Bool) {
        
        if bool {
            
            if self.cards.isEmpty {
                
                self.thatsAllFolks.alpha = 0
                
            } else if self.cards.count <= 4 {
                
                self.thatsAllFolks.alpha = 0
                
                for i in 0...self.cards.count - 1 {
                    
                    self.cards[i].alpha = 0
                    self.cards[i].isUserInteractionEnabled = false
                    self.cards[i].transform = CGAffineTransform(scaleX: 0.5, y: 0.5)

                }
                
            } else {
                
                self.thatsAllFolks.alpha = 0
                
                for i in 0...4 {
                    
                    self.cards[i].alpha = 0
                    self.cards[i].isUserInteractionEnabled = false
                    self.cards[i].transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                    
                }
                
            }
            
        } else {
            
            if self.cards.isEmpty {
                
                self.thatsAllFolks.alpha = 1
                
            } else if self.cards.count <= 4 {
                
                self.thatsAllFolks.alpha = 1
                
                for i in 0...self.cards.count - 1 {
                    
                    self.cards[i].alpha = 1
                    self.cards[i].isUserInteractionEnabled = true
                    self.cards[i].transform = CGAffineTransform.identity
                    self.layoutCards()
                    
                }
                
            } else {
                
                self.thatsAllFolks.alpha = 1
                
                for i in 0...4 {
                    
                    self.cards[i].alpha = 1
                    self.cards[i].isUserInteractionEnabled = true
                    self.cards[i].transform = CGAffineTransform.identity
                    self.layoutCards()
                    
                }
                
            }
            
        }
        
    }
    
    func openCategories() {
        
        let openView = UIViewPropertyAnimator(duration: 0.2, curve: .easeOut) {
            
            self.categoryAndSortByContainerView.transform = CGAffineTransform.identity
            self.categoryAndSortByContainerView.alpha = 1
            
            self.buttonsStackView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            self.buttonsStackView.alpha = 0
            
            self.categoriesDoneButton.transform = CGAffineTransform.identity
            self.categoriesDoneButton.alpha = 1
            
            self.shouldHideCards(true)
            
        }
        
        let closeView = UIViewPropertyAnimator(duration: 0.2, curve: .easeIn) {
            
            self.categoryAndSortByContainerView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            self.categoryAndSortByContainerView.alpha = 0
            
            self.buttonsStackView.transform = CGAffineTransform.identity
            self.buttonsStackView.alpha = 1
            
            self.categoriesDoneButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            self.categoriesDoneButton.alpha = 0
            
            self.shouldHideCards(false)
            
        }
        closeView.addCompletion { (position) in
            
            self.categoryAndSortByContainerView.isHidden = true
            self.categoriesDoneButton.isHidden = true
            
        }
        
        if categoryAndSortByContainerView.isHidden == true {
            
            self.categoryAndSortByContainerView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            self.categoryAndSortByContainerView.isHidden = false
            
            self.categoriesDoneButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            self.categoriesDoneButton.isHidden = false
            
            openView.startAnimation()
            
        } else {
            
            closeView.startAnimation()
            
        }
        
    }
    
    func handleTableViewTap() {
        
        self.updateDislikes()
        self.restaurantIndex = 0
        self.restaurants.removeAll()
        self.cards.removeAll()
        categoriesSearchBar.resignFirstResponder() // get rid of keyboard
        openCategories()
        loadingAnimator(.unhide)
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
                        
                        DispatchQueue.main.async {
                            self.resetCards()
                            self.loadingAnimator(.hide)
                        }
                        
                    })
                    
                })
                
            } else {
                
                print("ran else in handleTap (no results)")
                self.loadingText.text = "There's been an error which is not our fault. Please try again later."
                
                let text = "No Results With Your Chosen Criteria \n \nTry Changing The Radius In Settings"
                let attributedString = NSMutableAttributedString(string: text)
                attributedString.setSizeForText("Try Changing The Radius In Settings", with: 21)
                self.thatsAllFolks.attributedText = attributedString
                
                self.thatsAllFolks.numberOfLines = 0
                self.loadingAnimator(.hide)
                
            }
            
        })
        
    }
    
    func loadingAnimator(_ attribute: LoadingOpener) {
        
        if attribute == .hide {
            
            // hide view
            UIView.animate(withDuration: 0.3, animations: {
                
                self.loadingView.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
                self.loadingView.alpha = 0.0
                
            }, completion: { (success) in
                self.loadingView.isHidden = true
                self.loadingIndicator.stopAnimating()
            })
            
        } else {
            
            // open view
            self.view.bringSubview(toFront: loadingView)
            self.loadingView.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
            self.loadingView.alpha = 0.0
            
            UIView.animate(withDuration: 0.3, animations: {
                
                self.loadingView.transform = CGAffineTransform.identity
                self.loadingView.alpha = 1.0
                
            }, completion: { (success) in
                self.loadingView.isHidden = false
                self.loadingText.text = self.getLoadingLines()
                self.loadingIndicator.startAnimating()
            })
            
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
            
            let velocity = CGPoint(x: 980, y: 320) // sample taken from pan gesture
            
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
        var encountered = Set<Restaurant>()
        var result: [Restaurant] = []
        for value in array {
            if encountered.contains(value) {
                // Do not add a duplicate element.
            }
            else {
                // Add value to the set.
                encountered.insert(value)
                // ... Append the value.
                result.append(value)
            }
        }
        return result
    }
    
    func updateDislikes() {
        
        print("ran updateDislikes")
        
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
    
    func removeWith(_ indexToRemove: Int) {
        
        // func for protocol RemoveFromMainArray
        // for removing likes in main view when removed in FavouritesViewController
        self.likes.remove(at: indexToRemove)
        
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
    
    func searchRestaurants() {
        
        // address is primary input for location
        
        self.restaurants.removeAll()
        self.cards.removeAll()
        self.restaurantIndex = 0
        self.getCategories { (success) in
            
            if success {
                
                self.shouldSelectCell = true // will be accessed in willDisplayCell to select first cell of categoriesTableView and sortByTableView
                
                DispatchQueue.main.async {
                    
                    self.categoriesTableView.reloadData()
                    self.sortByTableView.reloadData()
                    
                }
                
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
                                    
                                    print("dislikes exist")
                                    
                                    let mapped = Set(arr.map( {$0.id} )) // map out only id of longTermFavourites
                                    let filteredRestaurants = self.restaurants.filter{ !mapped.contains($0.id) } // only return restaurants that don't match the mapped id
                                    
                                    self.restaurants = filteredRestaurants // replace restaurants with the filtered ones
                                    
                                } else {
                                    
                                    print("dislikes do not exist")
                                    
                                }
                                
                            })
                            
                            self.filterOutNonRestaurants(completetionHandler: { (newArr) in
                                
                                if let newArr = newArr {
                                    self.restaurants = newArr
                                }
                                
                                DispatchQueue.main.async {
                                    self.resetCards()
                                    self.loadingAnimator(.hide)
                                }
                                
                            })
                            
                        })
                        
                    } else {
                        
                        print("ran else in addressThingy (probably)")
                        self.loadingText.text = "There's been an error which is not our fault. Please try again later."
                        
                    }
                    
                })
                
            } else {
                
                self.loadingText.text = "There's been an error which is not our fault. Please try again later."
                
            }
            
        }
        
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
                            self.categories.append(item["title"].stringValue)
                        }
                    }
                    
                }
                self.categories.insert("All Types", at: 0)
                DispatchQueue.main.async {
                    self.categoriesTableView.reloadData()
                    self.sortByTableView.reloadData()
                }
                self.selectedCategory = "All Types"
                
                completionHandler(true)
                
            } else {
                
                completionHandler(false)
                
            }
            
        }
        
    }
    
    func searchBusinesses(_ lat: Double, _ long: Double, completetionHandler: @escaping (Bool) -> Void) {
        
        let headers: HTTPHeaders = ["Authorization": "Bearer Y43yqZUkj6vah5sgOHU-1PFN2qpapJsSwXZYScYTo0-nK9w5Y3lDvrdRJeG1IpQAADep0GrRL5ZDv6ybln03nIVzP7BL_IzAf_s7Wj5_QLPOO6oXns-nJe3-kIPiWHYx"]
        
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
        case "All Types":
            
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
    
    func showBusinessDetails(_ id: String, completionHandler: @escaping ([RestaurantHours]) -> ()) {
        
        let headers = ["Authorization": "Bearer Y43yqZUkj6vah5sgOHU-1PFN2qpapJsSwXZYScYTo0-nK9w5Y3lDvrdRJeG1IpQAADep0GrRL5ZDv6ybln03nIVzP7BL_IzAf_s7Wj5_QLPOO6oXns-nJe3-kIPiWHYx"]
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
        
        for i in 0...self.restaurants.count - 1 {
            
            let card = RestaurantCard(frame: CGRect(x: 0, y: 0, width: self.view.frame.width - 32, height: self.categoryAndSortByContainerView.bounds.size.height - 40))
            card.restaurant = self.restaurants[i]
            self.cards.append(card)
            
        }
        
        self.likeBtn.isEnabled = true
        self.dislikeBtn.isEnabled = true
        
        self.layoutCards()
        
    }
    
    /// Scale and alpha of successive cards visible to the user
    let cardAttributes: [(downscale: CGFloat, alpha: CGFloat)] = [(1, 1), (0.92, 0.8), (0.84, 0.6), (0.76, 0.4)]
    let cardInteritemSpacing: CGFloat = 10
    
    func layoutCards() {
        
        let firstCard = cards[0]
        self.view.addSubview(firstCard)
        firstCard.layer.zPosition = CGFloat(cards.count)
        firstCard.center = self.categoryAndSortByContainerView.center
        firstCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openCardDetail)))
        firstCard.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleCardPan)))
        
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
            card.center.x = self.categoryAndSortByContainerView.center.x
            card.frame.origin.y = cards[0].frame.origin.y - (CGFloat(i))
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
                    card.center = self.categoryAndSortByContainerView.center
                } else {
                    card.center.x = self.categoryAndSortByContainerView.center.x
                    card.frame.origin.y = self.cards[1].frame.origin.y - (CGFloat(i - 1) * self.cardInteritemSpacing)
                }
            }, completion: { (_) in
                if i == 1 {
                    // increase index for current restaurant everytime new card shows up
                    self.restaurantIndex += 1
                    card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.openCardDetail)))
                    card.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.handleCardPan)))
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
        newCard.center.x = self.categoryAndSortByContainerView.center.x
        newCard.frame.origin.y = cards[1].frame.origin.y - (4 * cardInteritemSpacing)
        self.view.addSubview(newCard)
        
        // animate to end state of new card
        UIView.animate(withDuration: animationDuration, delay: (3 * (animationDuration / 2)), usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: [], animations: {
            newCard.transform = CGAffineTransform(scaleX: downscale, y: downscale)
            newCard.alpha = alpha
            newCard.center.x = self.categoryAndSortByContainerView.center.x
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
    
    func openCardDetail() {
        
        let restaurant = self.restaurants[self.restaurantIndex]
        
        let vc = storyboard?.instantiateViewController(withIdentifier: "RestaurantDetailContainerController") as! RestaurantDetailContainerController
        vc.restaurant = restaurant
        vc.shouldHideStatus = true
        
        statusBarShouldBeHidden = true
        UIView.animate(withDuration: 0.25) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
        
        self.present(vc, animated: true, completion: nil)
        
    }
    
    func handleCardPan(sender: UIPanGestureRecognizer) {
        
        // if we're in the process of hiding a card, don't let the user interace with the cards yet
        if cardIsHiding { return }
        // distance user must pan right or left to trigger an option
        let requiredOffsetFromCenter: CGFloat = 15
        
        guard let card = sender.view else { return }
        let statusBar = UIApplication.shared.statusBarFrame
        
        let panLocationInView = sender.location(in: view)
        let panLocationInCard = sender.location(in: cards[0])
        
        switch sender.state {
        case .began:
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
            
        case .ended:
            
            dynamicAnimator.removeAllBehaviors()
            
            if statusBarShouldBeHidden && !card.frame.intersects(statusBar) {
                statusBarShouldBeHidden = false
                UIView.animate(withDuration: 0.25) {
                    self.setNeedsStatusBarAppearanceUpdate()
                }
            }
            
            if !(cards[0].center.x > (self.categoryAndSortByContainerView.center.x + requiredOffsetFromCenter) || cards[0].center.x < (self.view.center.x - requiredOffsetFromCenter)) {
                // snap to center
                let snapBehavior = UISnapBehavior(item: cards[0], snapTo: self.categoryAndSortByContainerView.center)
                dynamicAnimator.addBehavior(snapBehavior)
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
                
                if cards[0].center.x > (self.categoryAndSortByContainerView.center.x + requiredOffsetFromCenter) {
                    // like
                    popButton(button: self.likeBtn, true)
                } else if cards[0].center.x < (self.view.center.x - requiredOffsetFromCenter) {
                    // dislike
                    popButton(button: self.dislikeBtn, true)
                }
                
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
                            let text = "That's All Folks \n \nTry Changing The Radius In Settings"
                            let attributedString = NSMutableAttributedString(string: text)
                            attributedString.setSizeForText("Try Changing The Radius In Settings", with: 21)
                            self?.thatsAllFolks.attributedText = attributedString
                            self?.likeBtn.isEnabled = false
                            self?.dislikeBtn.isEnabled = false
                        }
                        // re-enable buttons after addToLikes() is run to prevent rapid tapping
                        self?.likeBtn.isUserInteractionEnabled = true
                        self?.dislikeBtn.isUserInteractionEnabled = true
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
                    self.likeBtn.isEnabled = false
                    self.dislikeBtn.isEnabled = false
                }
                // re-enable buttons after addToLikes() is run to prevent rapid tapping
                self.likeBtn.isUserInteractionEnabled = true
                self.dislikeBtn.isUserInteractionEnabled = true
            })
        }
    }
    
    func popButton(button: UIButton, _ isFromPanGesture: Bool = false) {
        
        button.isUserInteractionEnabled = false
        
        let buttonAnimator = UIViewPropertyAnimator(duration: 0.15, curve: .easeOut, animations: {
            
            button.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            self.settingsBtn.alpha = 0
            self.categoriesBtn.alpha = 0
            self.favouritesBtn.alpha = 0
            
        })
        buttonAnimator.addCompletion({ (_) in
            
            UIViewPropertyAnimator(duration: 0.2, curve: .easeIn, animations: {
                button.transform = CGAffineTransform.identity
                self.settingsBtn.alpha = 1
                self.categoriesBtn.alpha = 1
                self.favouritesBtn.alpha = 1
                self.dislikeBtn.alpha = 1
                self.likeBtn.alpha = 1
                
            }).startAnimation()
            
            if button == self.likeBtn {
                self.addToLikes(isFromPanGesture)
            } else {
                self.addToDislikes(isFromPanGesture)
            }
            
        })
        
        buttonAnimator.startAnimation()
        
    }
    
    // MARK: - Settings Delegate
    
    func dataChanged() {
        
        UIView.animate(withDuration: 0.5) {
            self.shouldHideCards(true)
        }
        self.restaurantIndex = 0
        self.restaurants.removeAll()
        self.cards.removeAll()
        loadingAnimator(.unhide)
        self.searchBusinesses(self.lat, self.long, completetionHandler: { (success) in
            
            if success {
                
                self.loadLongTermFavourites(completetionHandler: { (arr) in
                    
                    let mapped = Set(arr.map( {$0.id} )) // map out only id of longTermFavourites
                    let filteredRestaurants = self.restaurants.filter{ !mapped.contains($0.id) } // only return restaurants that don't match the mapped id
                    
                    self.restaurants = filteredRestaurants // replace restaurants with the filtered ones
                    
                    DispatchQueue.main.async {
                        self.resetCards()
                        self.loadingAnimator(.hide)
                    }
                    
                })
                
            } else {
                
                print("ran else in handleTap (no results)")
                self.loadingText.text = "There's been an error which is not our fault. Please try again later."
                self.loadingAnimator(.hide)
                
            }
            
        })
        
    }
    
    // MARK: - Table view
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if shouldSelectCell {
            
            if tableView == categoriesTableView && indexPath.row == 0 {
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! CategoryTableViewCell
                cell.setSelected(true, animated: true)
                
            } else if tableView == sortByTableView && indexPath.row == 0 {
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "sortCell") as! CategoryTableViewCell
                cell.setSelected(true, animated: true)
                
            }
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == categoriesTableView {
            
            if categoriesSearchBar.alpha == 1 {
                self.selectedCategory = self.filteredCategories[indexPath.row]
            } else {
                self.selectedCategory = self.categories[indexPath.row]
            }
            
            self.handleTableViewTap()
            self.shouldSelectCell = false
            
        } else {
            
            var sortBy = sortByItems[indexPath.row]
            sortBy = sortBy.replacingOccurrences(of: " ", with: "_")
            sortBy = sortBy.lowercased()
            self.selectedSortBy = sortBy
            
            self.handleTableViewTap()
            self.shouldSelectCell = false
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == categoriesTableView {
            
            if categoriesSearchBar.alpha == 1 {
                return filteredCategories.count
            } else {
                return self.categories.count
            }
            
        } else {
            
            return self.sortByItems.count
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == categoriesTableView {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CategoryTableViewCell
            
            if categoriesSearchBar.alpha == 1 {
                cell.categoryLabel.text = filteredCategories[indexPath.row]
            } else {
                cell.categoryLabel.text = categories[indexPath.row]
            }
            
            return cell
            
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "sortCell", for: indexPath) as! CategoryTableViewCell
            
            cell.categoryLabel.text = sortByItems[indexPath.row]
            
            let newSelectionView = UIView(frame: cell.bounds)
            newSelectionView.backgroundColor = UIColor.darkGray.darken(byPercentage: 0.2)
            
            cell.selectedBackgroundView = newSelectionView
            
            return cell
        }
        
    }
    
    // MARK: - UISearchBar Functions
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        filterResults(searchText)
        
    }
    
    func filterResults(_ searchText: String) {
        
        filteredCategories = categories.filter({ (category) -> Bool in
            return category.lowercased().contains(searchText.lowercased())
        })
        self.categoriesTableView.reloadData()
        
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        openSearchBar()
        self.categoriesSearchBar.text = "" // clears potential remaining text
        self.categoriesTableView.reloadData() // get rid of potential filtered searches remaining in table view
        
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "settingsSegue" {
            
            self.updateDislikes()
            
            let destVC = (segue.destination as! UINavigationController).topViewController as? SettingsTableViewController
            destVC?.delegate = self
            
        } else if segue.identifier == "favouritesSegue" {
            
            self.updateDislikes()
            
            let destVC = (segue.destination as! UINavigationController).topViewController as? FavouritesViewController
            destVC?.likes = self.likes
            destVC?.removeDelegate = self
            
        }
        
    }

}
