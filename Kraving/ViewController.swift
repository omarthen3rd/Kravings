//
//  ViewController.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-07-07.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire
import SDWebImage
import SystemConfiguration
import CoreLocation
import Cosmos

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

extension UIColor {
    
    static let aquafina = UIColor(red:0.03, green:0.93, blue:0.84, alpha:1.0)
    static let hotPonk = UIColor(red:1.00, green:0.38, blue:0.68, alpha:1.0)
    static let grayTwoPointO = UIColor(red:0.44, green:0.44, blue:0.44, alpha:1.0)
    
    static let websiteBlue = UIColor(red:0.00, green:0.48, blue:1.00, alpha:1.0)
    static let favouritesPink = UIColor(red:1.00, green:0.20, blue:0.61, alpha:1.0)
    static let reviewsYellow = UIColor(red:1.00, green:0.58, blue:0.00, alpha:1.0)
    static let directionsRed = UIColor(red:1.00, green:0.24, blue:0.24, alpha:1.0)
    static let callGreen = UIColor(red:0.09, green:0.86, blue:0.07, alpha:1.0)
    
    static let silverBlue = UIColor(red:0.96, green:0.96, blue:0.98, alpha:1.0)
    static let darkSilverBlue = UIColor(red:0.89, green:0.92, blue:0.95, alpha:1.0)
    static let blue2 = UIColor(red:0.13, green:0.53, blue:1.00, alpha:1.0)
    
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
        return String(characters.prefix(1))
    }
    
    var last: String {
        return String(characters.suffix(1))
    }
    
    var uppercaseFirst: String {
        return first.uppercased() + String(characters.dropFirst())
    }
    
}

class ReviewsCell: UITableViewCell {
    
    @IBOutlet var name: UILabel!
    @IBOutlet var rating: UILabel!
    @IBOutlet var timeOfReview: UILabel!
    @IBOutlet var textReview: UILabel!
    @IBOutlet var userImage: UIImageView!
    
}

class ViewController: UIViewController, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate, SettingsDelegate, ShowReviewView, ShowAlert, OpenDetailView {
    
    @IBOutlet var mainBackgroundImage: UIImageView!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var categoriesButton: UIButton!
    @IBOutlet var forwardButton: UIButton!
    @IBOutlet var settingsButton: UIButton!
    @IBOutlet var favouritesButton: UIButton!
    
    @IBOutlet var noresultsLabel: UILabel!
    @IBOutlet var spinningView: UIActivityIndicatorView!
    
    @IBOutlet var statusBarBlur: UIVisualEffectView!
    
    @IBOutlet var bottomStackView: UIStackView!
    @IBOutlet var reviewsHeaderView: UIVisualEffectView!
    @IBOutlet var reviewsDoneButton: UIButton!
    @IBOutlet var reviewsStarView: CosmosView!
    @IBOutlet var categoryContainerView: UIView!
    @IBOutlet var reviewsContainerView: UIView!
    @IBOutlet var categoriesTableView: UITableView!
    @IBOutlet var sortByHeaderView: UIVisualEffectView!
    @IBOutlet var sortByTableView: UITableView!
    @IBOutlet var reviewsTableView: UITableView!
    @IBAction func backToAddressAction(_ sender: UIButton) {
        
        self.dismiss(animated: true) {
            
        }
        
    }
    
    @IBAction func unwindToMenu(segue: UIStoryboardSegue) {}
        
    var animator: UIViewPropertyAnimator!
    var card = RestaurantCardALT()
    var panGesture = UIPanGestureRecognizer()
    var feedbackGenerator = UIImpactFeedbackGenerator()
    var defaults = UserDefaults.standard
    
    var divisor: CGFloat!
    var selectedId = -100
    var categories = [String]()
    var selectedCategory = String()
    var selectedSortBy = String()

    var accessToken = String()
    var viewIsOpen = false
    var isReviewsOpen = false
    
    var restaurants = [Restaurant]()
    var favouriteRestaurants = [Restaurant]()
    var currentReviews = [RestaurantReviews]()
    var sortByItems = ["Best Match", "Rating", "Review Count", "Distance"]
    var restaurantIndex = 0
    
    var locationManager = CLLocationManager()
    var locationToUse = String()
    var lat = Double()
    var long = Double()
    var cardCenter = CGPoint()
    
    var restaurant: Restaurant!
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.default
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // self.navigationController?.isNavigationBarHidden = false
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        isHeroEnabled = true
        
        self.selectedSortBy = "best_match"
        self.spinningView.startAnimating()
        self.noresultsLabel.text = self.getLoadingLines()
        self.noresultsLabel.alpha = 1.0
        
        DispatchQueue.main.async {
            
            self.categoriesTableView.contentOffset = CGPoint(x: 0, y: -50)
            self.sortByTableView.contentOffset = CGPoint(x: 0, y: -50)
            
            self.categoriesTableView.reloadData()
            self.sortByTableView.reloadData()
            
        }
                
        divisor = (view.frame.width / 2) / 0.61
        
        let locale = Locale.current
        let isMetric = locale.usesMetricSystem
        
        if defaults.integer(forKey: "searchRadius") == 0 {
            
            if isMetric {
                
                // searchRadius is in meters because metric (duh doi)
                defaults.set(5000, forKey: "searchRadius")
                
            } else {
                
                // searchRadius is in miles because screw the got damn freedom country equivalents
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
        
        let internetIsAvailable = isInternetAvailable()
        
        if internetIsAvailable {
            
            if CLLocationManager.locationServicesEnabled() && CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
                
                locationManager.delegate = self
                locationManager.distanceFilter = 100
                locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
                locationManager.requestWhenInUseAuthorization()
                locationManager.startUpdatingLocation()
                locationManager.requestLocation()
                
            } else {
                
                self.restaurants.removeAll()
                self.restaurantIndex = 0
                self.getCategories(completionHandler: { (success) in
                    
                    if success {
                        
                        self.searchBusinesses(self.lat, self.long, completetionHandler: { (success) in
                            
                            if success {
                                
                                self.loadInterface(completionHandler: { (success) in
                                    
                                    self.loadCard(1)
                                    
                                })
                                
                            } else {
                                
                                self.loadInterface(completionHandler: { (success) in
                                    
                                    self.spinningView.stopAnimating()
                                    self.noresultsLabel.text = "No Results In Your Search Radius"
                                    self.noresultsLabel.alpha = 1.0
                                    
                                })
                                
                            }
                        })
                        
                        
                    }
                    
                })
                
            }
            
            
            
        } else {
            
            self.noresultsLabel.text = "No Internet Connection"
            self.noresultsLabel.alpha = 1.0
            
        }
        
    }
    
    func getLoadingLines() -> String {
        
        if let filePath = Bundle.main.url(forResource: "loadingLines", withExtension: "json") {
            
            do {
                
                let jsonData = try Data(contentsOf: filePath)
                let json = JSON(data: jsonData)
                let randomIndex = Int(arc4random_uniform(UInt32(json["lines"].arrayValue.count)))
                
                let loadingLine = json["lines"][randomIndex].stringValue
                
                return loadingLine
                
            } catch {
                return "Loading..."
            }
            
        } else {
            return "Loading..."
        }
        
    }
    
    func loadCard(_ button: Int) {
    
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
        
        self.card = RestaurantCardALT(frame: CGRect(x: 16, y: 93, width: 343, height: 481))
        self.card.restaurant = self.restaurants[self.restaurantIndex]
        self.card.reviewDelegate = self
        self.card.showAlertDelegate = self
        self.card.openDetailView = self
        self.getReviews()
        
        let img = self.restaurants[self.restaurantIndex].image
        
        UIView.transition(with: self.mainBackgroundImage, duration: 0.5, options: UIViewAnimationOptions.transitionCrossDissolve, animations: {
            self.mainBackgroundImage.image = img
        }, completion: nil)
        
        self.card.translatesAutoresizingMaskIntoConstraints = false
        self.card.addGestureRecognizer(panGesture)
        
        if self.categoryContainerView.isHidden == false {
            handleTap()
        }

        if button == 1 {
            
            // like / right button
            
            self.card.alpha = 0.0
            self.card.frame.origin.y = 80
            self.card.frame.origin.x += 400
            UIView.animate(withDuration: 0.3, animations: {
                
                self.card.frame.origin.x -= 400
                self.card.alpha = 1.0
                self.view.addSubview(self.card)
                
                let margins = self.view.layoutMarginsGuide
                
                self.card.bottomAnchor.constraint(equalTo: self.bottomStackView.topAnchor, constant: -16).isActive = true
                self.card.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 0).isActive = true
                self.card.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: 0).isActive = true
                self.card.topAnchor.constraint(equalTo: margins.topAnchor, constant: 30).isActive = true
                self.card.centerXAnchor.constraint(equalTo: margins.centerXAnchor, constant: 16)
                self.card.centerYAnchor.constraint(equalTo: margins.centerYAnchor, constant: 0)
                
                self.view.layoutIfNeeded()
                self.card.layoutIfNeeded()
                
            }, completion: { (success) in
                
                if self.viewIsOpen {
                    
                    // self.handleTap(self.middleButton)
                    self.backButton.isUserInteractionEnabled = false
                    
                }
                
                self.spinningView.stopAnimating()
                // button.isUserInteractionEnabled = true
                self.categoriesButton.isUserInteractionEnabled = true
                self.backButton.isUserInteractionEnabled = true
                self.spinningView.stopAnimating()
                
            })
            
        } else {
            
            // dislike / left
            
            self.card.alpha = 0.0
            self.card.frame.origin.y = 80
            self.card.frame.origin.x -= 900
            UIView.animate(withDuration: 0.3, animations: {
                
                self.card.frame.origin.x += 900
                self.card.alpha = 1.0
                self.view.addSubview(self.card)
                
                let margins = self.view.layoutMarginsGuide
                
                self.card.bottomAnchor.constraint(equalTo: self.bottomStackView.topAnchor, constant: -16).isActive = true
                self.card.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 0).isActive = true
                self.card.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: 0).isActive = true
                self.card.topAnchor.constraint(equalTo: margins.topAnchor, constant: 30).isActive = true
                // self.card.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: -156).isActive = true
                self.card.centerXAnchor.constraint(equalTo: margins.centerXAnchor, constant: 16)
                self.card.centerYAnchor.constraint(equalTo: margins.centerYAnchor, constant: 0)
                
                self.view.layoutIfNeeded()
                self.card.layoutIfNeeded()
                
            }, completion: { (success) in
                
                // button.isUserInteractionEnabled = true
                self.categoriesButton.isUserInteractionEnabled = true
                self.forwardButton.isUserInteractionEnabled = true
                self.spinningView.stopAnimating()
                
            })
            
        }
        
        self.cardCenter = self.card.center
        self.view.bringSubview(toFront: self.statusBarBlur)
        
        if self.restaurantIndex == 0 {
            self.noresultsLabel.alpha = 0.0
            self.forwardButton.isEnabled = true
            self.backButton.isEnabled = false
        } else {
            self.noresultsLabel.alpha = 0.0
            self.forwardButton.isEnabled = true
            self.backButton.isEnabled = true
        }
        
        
    }
    
    func loadInterface(completionHandler: @escaping (Bool) -> ()) {
        
        self.reviewsTableView.estimatedRowHeight = 400
        self.reviewsTableView.rowHeight = UITableViewAutomaticDimension
        self.reviewsTableView.setNeedsLayout()
        self.reviewsTableView.layoutIfNeeded()
        self.reviewsTableView.reloadData()
        
        self.statusBarBlur.effect = nil
        
        self.spinningView.hidesWhenStopped = true
        
        self.view.backgroundColor = UIColor.silverBlue
        
        self.backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        self.categoriesButton.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        self.forwardButton.addTarget(self, action: #selector(goForward), for: .touchUpInside)
        
        self.categoriesButton.backgroundColor = UIColor.clear
        self.favouritesButton.backgroundColor = UIColor.clear
        self.settingsButton.backgroundColor = UIColor.clear
        
        self.mainBackgroundImage.contentMode = .scaleAspectFill
        
        setInsets(0)
        
        let image1 = #imageLiteral(resourceName: "btn_categories").withRenderingMode(.alwaysTemplate)
        let image1S = #imageLiteral(resourceName: "btn_categories_selected").withRenderingMode(.alwaysTemplate)
        let image2 = #imageLiteral(resourceName: "btn_openFavourites").withRenderingMode(.alwaysTemplate)
        let image2S = #imageLiteral(resourceName: "btn_openFavourites_selected").withRenderingMode(.alwaysTemplate)
        let image3 = #imageLiteral(resourceName: "btn_settings").withRenderingMode(.alwaysTemplate)
        let image3S = #imageLiteral(resourceName: "btn_settings_selected").withRenderingMode(.alwaysTemplate)
        
        categoriesButton.setImage(image1, for: .normal)
        categoriesButton.setImage(image1S, for: UIControlState.highlighted)
        categoriesButton.imageView?.tintColor = UIColor.black
        categoriesButton.imageView?.contentMode = .scaleAspectFit
        categoriesButton.tintColor = UIColor.black

        favouritesButton.setImage(image2, for: .normal)
        favouritesButton.setImage(image2S, for: UIControlState.highlighted)
        favouritesButton.imageView?.tintColor = UIColor.black
        favouritesButton.imageView?.contentMode = .scaleAspectFit
        favouritesButton.tintColor = UIColor.black
        
        settingsButton.setImage(image3, for: .normal)
        settingsButton.setImage(image3S, for: UIControlState.highlighted)
        settingsButton.imageView?.tintColor = UIColor.black
        settingsButton.imageView?.contentMode = .scaleAspectFit
        settingsButton.tintColor = UIColor.black
        
        self.reviewsDoneButton.addTarget(self, action: #selector(self.openReviewView), for: .touchUpInside)
        
        forwardButton.tag = 1
        backButton.tag = 0
        
        reviewsContainerView.layer.cornerRadius = 15
        reviewsContainerView.clipsToBounds = true
        reviewsContainerView.isHidden = true
        
        // tableView
        
        categoriesTableView.tableFooterView = UIView(frame: .zero)
        categoriesTableView.backgroundColor = UIColor.clear
        categoriesTableView.layer.cornerRadius = 15
        
        reviewsTableView.tableFooterView = UIView(frame: .zero)
        reviewsTableView.backgroundColor = UIColor.clear
        
        sortByTableView.tableFooterView = UIView(frame: .zero)
        sortByTableView.backgroundColor = UIColor.clear
        sortByTableView.layer.cornerRadius = 15
        
        let indexPath = IndexPath(row: 0, section: 0)
        self.categoriesTableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
        self.sortByTableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = categoriesTableView.bounds
        categoriesTableView.backgroundView = blurEffectView
        categoriesTableView.separatorEffect = UIBlurEffect(style: UIBlurEffectStyle.prominent)
        
        let blurEffect2 = UIBlurEffect(style: UIBlurEffectStyle.extraLight)
        let blurEffectView2 = UIVisualEffectView(effect: blurEffect2)
        blurEffectView2.frame = reviewsTableView.bounds
        reviewsTableView.backgroundView = blurEffectView2
        reviewsTableView.separatorEffect = UIBlurEffect(style: UIBlurEffectStyle.prominent)
        
        let blurEffectView3 = UIVisualEffectView(effect: blurEffect)
        blurEffectView3.frame = sortByTableView.bounds
        sortByTableView.backgroundView = blurEffectView3
        sortByTableView.separatorEffect = UIBlurEffect(style: UIBlurEffectStyle.prominent)
        
        // since app has run and been setup, setup 3D Touch Quick Actions
        // Todo: fix when opening 3D touch shortcut when address choosing is there
        
        let icon = UIApplicationShortcutIcon(type: .love)
        let shortcut = UIApplicationShortcutItem(type: "com.omar.kravings.openfavourites", localizedTitle: "Favourites", localizedSubtitle: "", icon: icon, userInfo: nil)
        // UIApplication.shared.shortcutItems = [shortcut]
        
        completionHandler(true)
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        // add some kind of error view telling user to allow location
        
        self.dismiss(animated: true) {
            
        }
        
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
            self.lat = coord.latitude
            self.long = coord.longitude
            
            self.restaurants.removeAll()
            self.restaurantIndex = 0
            self.getCategories(completionHandler: { (success) in
                
                if success {
                    
                    self.searchBusinesses(self.lat, self.long, completetionHandler: { (success) in
                        
                        if success {
                            
                            self.loadInterface(completionHandler: { (success) in
                                
                                self.loadCard(1)
                                
                            })
                            
                        } else {
                            
                            self.loadInterface(completionHandler: { (success) in
                                
                                self.spinningView.stopAnimating()
                                self.noresultsLabel.text = "No Results In Your Search Radius"
                                self.noresultsLabel.alpha = 1.0
                                
                            })
                            
                        }
                    })
                    
                    
                }
                
            })
        }
    }
    
    func displayLocationInfo(_ placemark: CLPlacemark?) {
        if let containsPlacemark = placemark {
            locationManager.stopUpdatingLocation()
            let locality = (containsPlacemark.locality != nil) ? containsPlacemark.locality : ""
            self.locationToUse = locality!
        }
    }
    
    func setInsets(_ number: CGFloat) {
        
        settingsButton.imageEdgeInsets = UIEdgeInsets(top: number, left: 0, bottom: number, right: 0)
        categoriesButton.imageEdgeInsets = UIEdgeInsets(top: number, left: 0, bottom: number, right: 0)
        favouritesButton.imageEdgeInsets = UIEdgeInsets(top: number, left: 0, bottom: number, right: 0)
        
    }
    
    func getAccessToken() {
        
        let url = "https://api.yelp.com/oauth2/token?grant_type=client_credentials&client_id=6KSy_u1GxOmUyYEBgHBlkw&client_secret=dqmoQtAoUIt0XJf2lgBGu14xhtEHGkqAaN3MfG50v38eJ53shrFB3s8COC1snddB"
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "content-type")
        
        Alamofire.request(request).responseJSON { (response) in
            
            if let value = response.result.value {
                
                let json = JSON(value)
                self.accessToken = json["access_token"].stringValue
                
            }
            
        }
        
    }
    
    func getCategories(completionHandler: @escaping (Bool) -> ()) {
        
        let url = "https://www.yelp.com/developers/documentation/v3/all_category_list/categories.json"
        
        Alamofire.request(url).responseJSON { (response) in
            
            if let value = response.result.value {
                
                let json = JSON(value)
                
                for item in json.arrayValue {
                    
                    let thing = item["parents"].arrayValue
                    for things in thing {
                        
                        let thingy = things.stringValue
                        if thingy == "restaurants" {
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
            
            // convert searchRadius to meteres here
            
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
        
        var restaurantHoursToAppend = [RestaurantHours]()
        
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
                        
                        let imageFinalURL = URL(string: imageURL)
                        let posterData = try? Data(contentsOf: imageFinalURL!)
                        if let pData = posterData {
                            
                            image = UIImage(data: pData)!
                            
                        } else {
                            
                            image = #imageLiteral(resourceName: "placeholderImage")
                            
                        }
                        
                        restaurantHoursToAppend = [RestaurantHours]()
                        
                        self.showBusinessDetails(id, completionHandler: { (arr) in
                            
                            if !(arr.isEmpty) {
                                
                                restaurantHoursToAppend = arr
                                
                            }
                        })
                        
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
    
    func getReviews() {
        
        self.currentReviews.removeAll()
        
        let headers: HTTPHeaders = ["Authorization": "Bearer Y43yqZUkj6vah5sgOHU-1PFN2qpapJsSwXZYScYTo0-nK9w5Y3lDvrdRJeG1IpQAADep0GrRL5ZDv6ybln03nIVzP7BL_IzAf_s7Wj5_QLPOO6oXns-nJe3-kIPiWHYx"]
        
        Alamofire.request("https://api.yelp.com/v3/businesses/\(self.restaurants[self.restaurantIndex].id)/reviews", headers: headers).responseJSON { (Response) in
            
            if let value = Response.result.value {
                
                let json = JSON(value)
                
                for review in json["reviews"].arrayValue {
                    
                    let rating = review["rating"].intValue
                    let name = review["user"]["name"].stringValue
                    let imageUrl = review["user"]["image_url"].stringValue
                    let reviewText = review["text"].stringValue
                    let timeCreated = review["time_created"].stringValue
                    
                    let goodDate = self.formatDate(timeCreated)
                    
                    let newReview = RestaurantReviews(name: name, rating: rating, imageURL: imageUrl, reviewText: reviewText, reviewTime: goodDate)
                    self.currentReviews.append(newReview)
                    
                }
                
                DispatchQueue.main.async {
                    
                    self.reviewsTableView.reloadData()
                    
                }
                
            }
            
        }
        
        self.reviewsStarView.rating = Double(self.restaurants[self.restaurantIndex].rating)
        self.reviewsStarView.text = "\(self.restaurants[self.restaurantIndex].reviewCount) VOTES"
        self.reviewsStarView.settings.emptyBorderWidth = 0
        self.reviewsStarView.settings.emptyBorderColor = UIColor.clear
        self.reviewsStarView.settings.emptyColor = UIColor.darkGray
        self.reviewsStarView.settings.updateOnTouch = false
        self.reviewsStarView.settings.starSize = 21
        self.reviewsStarView.contentMode = .right
        
    }
    
    func formatDate(_ OGdate: String) -> String {
        
        let inputFormatter = DateFormatter()
        let tempLocale = inputFormatter.locale
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        inputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateOutput = inputFormatter.date(from: OGdate)!
        inputFormatter.dateFormat = "MMM dd, yyyy"
        inputFormatter.locale = tempLocale
        let dateString = inputFormatter.string(from: dateOutput)
        
        return dateString
        
    }
    
    func handleSelectedRestaurant(_ onlySelect: Bool = false) {
        
        self.spinningView.startAnimating()
        self.backButton.isEnabled = false
        self.forwardButton.isEnabled = false
        
        if onlySelect {
            
        } else {
            
            self.card.removeFromSuperview()
            self.restaurants.removeAll()
            self.restaurantIndex = 0
            self.handleTap()
            
            self.noresultsLabel.text = self.getLoadingLines()
            
            self.searchBusinesses(self.lat, self.long, completetionHandler: { (success) in
                
                self.noresultsLabel.alpha = 1.0
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: {
                    
                    if success {
                        
                        if self.restaurants.isEmpty {
                            
                            self.noresultsLabel.text = "No Results \n \n Try Increasing The Search Radius In Settings"
                            self.spinningView.stopAnimating()
                            self.backButton.isEnabled = false
                            self.forwardButton.isEnabled = false
                            
                        } else {
                            
                            self.noresultsLabel.text = ""
                            
                            DispatchQueue.global(qos: .userInitiated).async {
                                DispatchQueue.main.async {
                                    self.noresultsLabel.alpha = 0.0
                                    self.loadCard(1)
                                }
                            }
                            
                        }
                        
                    } else {
                        
                        self.noresultsLabel.text = "No Results \n Try Increasing The Search Radius In Settings"
                        self.noresultsLabel.alpha = 1.0
                        self.spinningView.stopAnimating()
                        self.backButton.isEnabled = false
                        self.forwardButton.isEnabled = false
                        
                    }
                    
                    
                })
                
            })
            
        }
        
        
    }
    
    func handleTap() {
        
        let image1 = #imageLiteral(resourceName: "btn_categories").withRenderingMode(.alwaysTemplate)
        let image1S = #imageLiteral(resourceName: "btn_categories_selected").withRenderingMode(.alwaysTemplate)
        
        let resultHidden = noresultsLabel.isHidden
        
        if reviewsContainerView.isHidden == false && categoryContainerView.isHidden == true {
            
            // deal with it here
            self.reviewsContainerView.isHidden = true
            self.categoryContainerView.isHidden = false
            
            
        } else {
            
            if categoryContainerView.isHidden == true {
                
                self.categoryContainerView.isHidden = false
                self.card.isHidden = true
                self.backButton.isEnabled = false
                self.forwardButton.isEnabled = false
                self.noresultsLabel.alpha = 1.0
                
                self.noresultsLabel.alpha = 0.0
                
                self.categoriesButton.setImage(image1S, for: .normal)
                
            } else {
                
                self.categoryContainerView.isHidden = true
                self.card.isHidden = false
                self.backButton.isEnabled = true
                self.forwardButton.isEnabled = true
                self.noresultsLabel.isHidden = resultHidden
                
                if self.restaurants.isEmpty {
                    
                    self.noresultsLabel.alpha = 1.0
                    
                } else {
                    
                    self.noresultsLabel.alpha = 0.0
                    
                }
                
                self.categoriesButton.setImage(image1, for: .normal)
                
            }
            
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
    
    func goBack() {
        
        self.backButton.isUserInteractionEnabled = false
        
        let animator = UIViewPropertyAnimator(duration: 0.2, curve: .easeOut) { 
            
            self.card.frame = self.card.frame.offsetBy(dx: 300, dy: 500)
            // self.card.alpha = 0
            
        }
        animator.addCompletion { (postion) in
            
            self.card.removeFromSuperview()
            self.restaurantIndex -= 1
            
            if self.restaurants.endIndex == self.restaurantIndex {
                
                self.noresultsLabel.text = "No More Results"
                self.noresultsLabel.alpha = 1.0
                
                self.backButton.isEnabled = true
                self.forwardButton.isEnabled = false
                
            } else {
                
                DispatchQueue.global(qos: .userInitiated).async {
                    DispatchQueue.main.async {
                        self.loadCard(0)
                    }
                }
                
            }
            
        }
        animator.startAnimation()
        
        
    }
    
    func goForward() {
        
        self.backButton.isUserInteractionEnabled = false
        
        let animator = UIViewPropertyAnimator(duration: 0.2, curve: .easeOut) {
            
            self.card.center = CGPoint(x: -300, y: -500)
            // self.card.alpha = 0
            
        }
        
        animator.addCompletion { (postion) in
            
            self.card.removeFromSuperview()
            self.restaurantIndex += 1
            
            if self.restaurants.endIndex == self.restaurantIndex {
                
                self.noresultsLabel.text = "No More Results"
                self.noresultsLabel.alpha = 1.0
                
                self.backButton.isEnabled = true
                self.forwardButton.isEnabled = false
                
            } else {
                
                DispatchQueue.global(qos: .userInitiated).async {
                    DispatchQueue.main.async {
                        self.loadCard(1)
                    }
                }
                
            }
            
        }
        animator.startAnimation()
        
    }
    
    func handlePan(_ recognizer: UIPanGestureRecognizer) {
        
        feedbackGenerator.prepare()
        
        let xDistance = recognizer.translation(in: self.view).x
        let yDistance = recognizer.translation(in: self.view).y
        
        let viewCard = recognizer.view!
        
        let rotationStrength = min(xDistance / self.view.bounds.size.width, 1)
        let fullCircle = CGFloat(2 * CGFloat.pi)
        
        let rotationAngle: CGFloat = fullCircle * rotationStrength / 16
        let scaleStrength = CGFloat(1 - fabsf(Float(rotationStrength)) / 2)
        
        let scale2 = max(scaleStrength, 0.93)
        let transform = CGAffineTransform(rotationAngle: rotationAngle).scaledBy(x: scale2, y: scale2)
        
        let cardAnimator = UIViewPropertyAnimator(duration: 0.3, curve: .easeOut, animations: {
            
            viewCard.center = self.cardCenter
            viewCard.transform = CGAffineTransform.identity
            
        })
        cardAnimator.addCompletion { (position) in
            
            self.feedbackGenerator.impactOccurred()
            
        }
        
        switch recognizer.state {
            
        case .began:
            break
            
        case .changed:
            
            let newX = self.cardCenter.x + xDistance
            let newY = self.cardCenter.y + yDistance
            
            if self.cardCenter.y != newY {
                
                // only goes up, will be used for adding to favourites in future version
                // viewCard.center = CGPoint(x: self.cardCenter.x, y: newY)
                
            }
            
            // card will only move horizontally, no vertical movement
            viewCard.center = CGPoint(x: newX, y: self.cardCenter.y)
            viewCard.transform = transform
            
            if let restCard = viewCard as? RestaurantCardALT {
                
                if restCard.didAnimateView == true {
                    // prevent view from going crazy
                    restCard.handleTap(restCard.tapGesture)
                }
                
            }
            
            // status bar blur
            if viewCard.frame.intersects(self.statusBarBlur.frame) {
                UIView.animate(withDuration: 0.3, animations: {
                    self.statusBarBlur.effect = UIBlurEffect(style: UIBlurEffectStyle.extraLight)
                })
            } else {
                UIView.animate(withDuration: 0.3, animations: {
                    self.statusBarBlur.effect = nil
                })
            }
            
        case .ended:
            
            // status bar effect is nil
            UIView.animate(withDuration: 0.3, animations: {
                self.statusBarBlur.effect = nil
            })
            
            if viewCard.center.x < 150 {
                // move to left - go forward
                if self.restaurants.endIndex - 1 == self.restaurantIndex {
                    
                    cardAnimator.startAnimation()
                    
                } else {
                    
                    UIView.animate(withDuration: 0.3, animations: {
                        viewCard.center = CGPoint(x: viewCard.center.x - 200, y: viewCard.center.y)
                        viewCard.alpha = 0
                    }, completion: { (success) in
                        
                        self.card.removeFromSuperview()
                        self.restaurantIndex += 1
                        
                        if self.restaurants.endIndex == self.restaurantIndex {
                            
                            self.noresultsLabel.text = "No More Results"
                            self.noresultsLabel.alpha = 1.0
                            
                            self.backButton.isEnabled = true
                            self.forwardButton.isEnabled = false
                            
                        } else {
                            
                            DispatchQueue.global(qos: .userInitiated).async {
                                DispatchQueue.main.async {
                                    self.loadCard(1)
                                }
                            }
                            
                        }
                        
                    })
                    
                }
                
            } else if viewCard.center.x > (view.frame.width - 150) {
                // move to right - go back
                
                if self.restaurantIndex == 0 {
                    
                    cardAnimator.startAnimation()
                    
                } else {
                    
                    UIView.animate(withDuration: 0.3, animations: {
                        viewCard.center = CGPoint(x: viewCard.center.x + 200, y: viewCard.center.y)
                        viewCard.alpha = 0
                    }, completion: { (success) in
                        
                        self.card.removeFromSuperview()
                        self.restaurantIndex -= 1
                        
                        if self.restaurants.endIndex == self.restaurantIndex {
                            
                            self.noresultsLabel.text = "No More Results"
                            self.noresultsLabel.alpha = 1.0
                            
                            self.backButton.isEnabled = true
                            self.forwardButton.isEnabled = false
                            
                        } else {
                            
                            DispatchQueue.global(qos: .userInitiated).async {
                                DispatchQueue.main.async {
                                    self.loadCard(0)
                                }
                            }
                            
                        }
                        
                    })
                    
                }
                
            } else {
                
                cardAnimator.startAnimation()
                
            }
            
            break
        
        default:
            break
            
        }
        
    }
    
    func dataChanged() {
                
        self.spinningView.startAnimating()
        self.noresultsLabel.text = "Are we there yet?"
        self.noresultsLabel.alpha = 1.0
        
        self.card.removeFromSuperview()
        self.restaurants.removeAll()
        self.restaurantIndex = 0
        self.searchBusinesses(self.lat, self.long) { (success) in
            
            self.noresultsLabel.text = self.getLoadingLines()
            self.noresultsLabel.alpha = 1.0
            
            if success {
                
                if self.restaurants.isEmpty {
                    
                    self.noresultsLabel.text = "No Results"
                    self.spinningView.stopAnimating()
                    self.backButton.isEnabled = false
                    self.forwardButton.isEnabled = false
                    
                } else {
                    
                    self.noresultsLabel.text = ""
                    
                    DispatchQueue.global(qos: .userInitiated).async {
                        DispatchQueue.main.async {
                            self.noresultsLabel.alpha = 0.0
                            self.loadCard(1)
                        }
                    }
                    
                }
                
            } else {
                
                self.noresultsLabel.text = "No Results"
                self.noresultsLabel.alpha = 1.0
                self.spinningView.stopAnimating()
                self.backButton.isEnabled = false
                self.forwardButton.isEnabled = false
                
            }
            
        }
        
    }
    
    func openReviewView() {
        
        if reviewsContainerView.isHidden == true {
            
            self.reviewsContainerView.isHidden = false
            self.card.isHidden = true
            self.backButton.isEnabled = false
            self.forwardButton.isEnabled = false
            self.categoriesButton.isEnabled = false
            self.settingsButton.isEnabled = false
            self.favouritesButton.isEnabled = false
            
        } else {
            
            self.reviewsContainerView.isHidden = true
            self.card.isHidden = false
            self.backButton.isEnabled = true
            self.forwardButton.isEnabled = true
            self.categoriesButton.isEnabled = true
            self.settingsButton.isEnabled = true
            self.favouritesButton.isEnabled = true
            
        }
        
    }
    
    func showAlertController(_ title: String, _ message: String, _ url: String?) {
            
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let okayAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        let alertAction = UIAlertAction(title: "Download App", style: .default, handler: { (action) in
            
            let url = URL(string: url!)
            
            if let urlUnwrapped = url {
                
                UIApplication.shared.open(urlUnwrapped, options: [:], completionHandler: { (success) in
                    
                    // do something with !success bool here
                    
                })
                
            } else {
                
                let alertError = UIAlertController(title: "Error Opening", message: "Please try again.", preferredStyle: UIAlertControllerStyle.alert)
                let okayAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alertError.addAction(okayAction)
                self.present(alertError, animated: true, completion: nil)
                
            }
            
        })
        
        if url == nil {
            alert.addAction(okayAction)
        } else {
            alert.addAction(okayAction)
            alert.addAction(alertAction)
        }
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func showDetailView() {
        
        let currentRestaurant = self.restaurants[self.restaurantIndex]
        
        let vc = storyboard?.instantiateViewController(withIdentifier: "RestaurantDetailTableViewController") as! RestaurantDetailTableViewController
        vc.restaurant = currentRestaurant
        self.present(vc, animated: true, completion: {
            // self.feedbackGenerator.impactOccurred()
        })
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == categoriesTableView {
            
            return self.categories.count
            
        } else if tableView == reviewsTableView {
         
            return self.currentReviews.count
            
        } else {
            
            return self.sortByItems.count
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == categoriesTableView {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CategoryTableViewCell
            
            cell.categoryLabel.text = categories[indexPath.row]
            
            let newSelectionView = UIVisualEffectView(frame: cell.bounds)
            newSelectionView.effect = UIBlurEffect(style: UIBlurEffectStyle.regular)
            cell.selectedBackgroundView = newSelectionView
            
            return cell
            
        } else if tableView == reviewsTableView {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "ReviewsCell", for: indexPath) as! ReviewsCell
            
            let currentReview = currentReviews[indexPath.row]
            let imageURL = URL(string: currentReview.imageURL)
            
            if let urlThing = imageURL {
                cell.userImage.sd_setImage(with: urlThing, placeholderImage: UIImage(named: "emptyProfile"))
            } else {
                cell.userImage.image = #imageLiteral(resourceName: "emptyProfile")
            }
            
            cell.userImage.layer.cornerRadius = 6
            cell.userImage.clipsToBounds = true
            
            cell.name.text = currentReview.name
            cell.rating.text = "\(currentReview.rating)"
            cell.textReview.text = currentReview.reviewText
            cell.timeOfReview.text = currentReview.reviewTime
            
            return cell
            
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "sortCell", for: indexPath) as! CategoryTableViewCell
            
            cell.categoryLabel.text = sortByItems[indexPath.row]
            
            let newSelectionView = UIVisualEffectView(frame: cell.bounds)
            newSelectionView.effect = UIBlurEffect(style: UIBlurEffectStyle.regular)
            cell.selectedBackgroundView = newSelectionView
            
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == categoriesTableView {
            
            let cell = tableView.cellForRow(at: indexPath) as! CategoryTableViewCell
            
            // self.noresultsLabel.text = self.getLoadingLines()
            self.noresultsLabel.alpha = 1.0
            
            self.selectedCategory = cell.categoryLabel.text!
            self.handleSelectedRestaurant()
            
        } else if tableView == sortByTableView {
            
            let cell = tableView.cellForRow(at: indexPath) as! CategoryTableViewCell
            
            self.noresultsLabel.text = self.getLoadingLines()
            self.noresultsLabel.alpha = 1.0
            
            if cell.categoryLabel.text == "Best Match" {
                
                self.selectedSortBy = "best_match"
                
            } else if cell.categoryLabel.text == "Rating" {
                
                self.selectedSortBy = "rating"
                
            } else if cell.categoryLabel.text == "Review Count" {
                
                self.selectedSortBy = "review_count"
                
            } else {
                
                self.selectedSortBy = "distance"
                
            }
            
            self.handleSelectedRestaurant()
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableViewAutomaticDimension
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "settingsSegue" {
            
            let destVC = (segue.destination as! UINavigationController).topViewController as? SettingsTableViewController
            destVC?.delegate = self
            
        }
        
    }
}

