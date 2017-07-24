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
import MapKit

extension UIColor {
    
    static let silverBlue = UIColor(red:0.96, green:0.96, blue:0.98, alpha:1.0)
    static let darkSilverBlue = UIColor(red:0.89, green:0.92, blue:0.95, alpha:1.0)
    static let blue2 = UIColor(red:0.13, green:0.53, blue:1.00, alpha:1.0)
    
}

protocol CallAlert {
    
    func showAlertView(_ alreadyInFav: Bool)
    
}

class ReviewsCell: UITableViewCell {
    
    @IBOutlet var name: UILabel!
    @IBOutlet var rating: UILabel!
    @IBOutlet var timeOfReview: UILabel!
    @IBOutlet var textReview: UILabel!
    @IBOutlet var userImage: UIImageView!
    
}

class ViewController: UIViewController, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate, SettingsDelegate {
    
    @IBOutlet var mainBackgroundImage: UIImageView!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var categoriesButton: UIButton!
    @IBOutlet var forwardButton: UIButton!
    @IBOutlet var settingsButton: UIButton!
    @IBOutlet var favouritesButton: UIButton!
    @IBOutlet var noresultsLabel: UILabel!
    @IBOutlet var spinningView: UIActivityIndicatorView!
    
    @IBOutlet var statusBarBlur: UIVisualEffectView!
    @IBOutlet var buttonsBlurBackground: UIVisualEffectView!
    @IBOutlet var restaurantPhoneButton: UIButton!
    @IBOutlet var restaurantMapsButton: UIButton!
    @IBOutlet var restaurantWebsiteButton: UIButton!
    @IBOutlet var restaurantReviewsButton: UIButton!
    @IBOutlet var restaurantFavouritesButton: UIButton!
    
    @IBOutlet var bottomStackView: UIStackView!
    @IBOutlet var reviewsHeaderView: UIVisualEffectView!
    @IBOutlet var reviewsHeaderLabel: UILabel!
    @IBOutlet var categoryContainerView: UIView!
    @IBOutlet var reviewsContainerView: UIView!
    @IBOutlet var categoriesTableView: UITableView!
    @IBOutlet var reviewsTableView: UITableView!
    @IBAction func unwindToMenu(segue: UIStoryboardSegue) {}
    
    var delegate: CallAlert?
    
    var card = RestaurantCardALT()
    var panGesture = UIPanGestureRecognizer()
    var defaults = UserDefaults.standard
    
    var divisor: CGFloat!
    var selectedId = -100
    var categories = [String]()
    var selectedCategory = String()

    var accessToken = String()
    var viewIsOpen = false
    var isReviewsOpen = false
    
    var restaurants = [Restaurant]()
    var favouriteRestaurants = [Restaurant]()
    var currentReviews = [RestaurantReviews]()
    var restaurantIndex = 0
    
    var locationManager = CLLocationManager()
    var locationToUse = String()
    var lat = Double()
    var long = Double()
    var cardCenter = CGPoint()
    
    var restaurant: Restaurant!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // self.navigationController?.isNavigationBarHidden = false
        self.reviewsTableView.estimatedRowHeight = 400
        self.reviewsTableView.rowHeight = UITableViewAutomaticDimension
        self.reviewsTableView.setNeedsLayout()
        self.reviewsTableView.layoutIfNeeded()
        self.reviewsTableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
                
        divisor = (view.frame.width / 2) / 0.61
        
        if defaults.integer(forKey: "searchRadius") == 0 {
            
            // searchRadius is in meters
            defaults.set(5000, forKey: "searchRadius")
            
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
            
            locationManager.delegate = self
            locationManager.distanceFilter = 100
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            locationManager.requestLocation()
            
        }
        
    }
    
    func loadCard(_ button: UIButton) {
    
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
        
        self.card = RestaurantCardALT(frame: CGRect(x: 16, y: 93, width: 343, height: 481))
        self.card.restaurant = self.restaurants[self.restaurantIndex]
        self.card.setDelegate(controller: self)
        self.getReviews()
        
        let imgURL = URL(string: self.restaurants[self.restaurantIndex].imageURL)
        
        UIView.transition(with: self.mainBackgroundImage, duration: 0.5, options: UIViewAnimationOptions.transitionCrossDissolve, animations: {
            self.mainBackgroundImage.sd_setImage(with: imgURL!)
        }, completion: nil)
        
        self.card.translatesAutoresizingMaskIntoConstraints = false
        self.card.addGestureRecognizer(panGesture)

        if button.tag == 1 {
            
            // like / right button
            
            self.card.alpha = 0.0
            self.card.frame.origin.y = 80
            self.card.frame.origin.x += 400
            UIView.animate(withDuration: 0.3, animations: {
                
                self.card.frame.origin.x -= 400
                self.card.alpha = 1.0
                self.view.addSubview(self.card)
                
                let margins = self.view.layoutMarginsGuide
                
                self.card.bottomAnchor.constraint(equalTo: self.bottomStackView.topAnchor, constant: -1).isActive = true
                self.card.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 0).isActive = true
                self.card.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: 0).isActive = true
                self.card.topAnchor.constraint(equalTo: margins.topAnchor, constant: 30).isActive = true
                // self.card.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: -156).isActive = true
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
                button.isUserInteractionEnabled = true
                self.categoriesButton.isUserInteractionEnabled = true
                self.backButton.isUserInteractionEnabled = true
                
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
                
                self.card.bottomAnchor.constraint(equalTo: self.bottomStackView.topAnchor, constant: -1).isActive = true
                self.card.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 0).isActive = true
                self.card.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: 0).isActive = true
                self.card.topAnchor.constraint(equalTo: margins.topAnchor, constant: 30).isActive = true
                // self.card.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: -156).isActive = true
                self.card.centerXAnchor.constraint(equalTo: margins.centerXAnchor, constant: 16)
                self.card.centerYAnchor.constraint(equalTo: margins.centerYAnchor, constant: 0)
                
                self.view.layoutIfNeeded()
                self.card.layoutIfNeeded()
                
            }, completion: { (success) in
                
                button.isUserInteractionEnabled = true
                self.categoriesButton.isUserInteractionEnabled = true
                self.forwardButton.isUserInteractionEnabled = true
                
            })
            
        }
        
        self.cardCenter = self.card.center
        self.view.bringSubview(toFront: self.buttonsBlurBackground)
        self.view.bringSubview(toFront: self.statusBarBlur)
        
        if self.restaurantIndex == 0 {
            self.spinningView.stopAnimating()
            self.noresultsLabel.isHidden = true
            self.forwardButton.isEnabled = true
            self.backButton.isEnabled = false
        } else {
            self.spinningView.stopAnimating()
            self.noresultsLabel.isHidden = true
            self.forwardButton.isEnabled = true
            self.backButton.isEnabled = true
        }
        
        
    }
    
    func loadInterface(completionHandler: @escaping (Bool) -> ()) {
        
        self.statusBarBlur.effect = nil
        self.buttonsBlurBackground.effect = nil
        
        self.spinningView.hidesWhenStopped = true
        
        self.view.backgroundColor = UIColor.silverBlue
        
        self.backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        self.categoriesButton.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        self.forwardButton.addTarget(self, action: #selector(goForward), for: .touchUpInside)
        
        restaurantPhoneButton.addTarget(self, action: #selector(self.callBusiness), for: .touchUpInside)
        restaurantMapsButton.addTarget(self, action: #selector(self.openMaps), for: .touchUpInside)
        restaurantWebsiteButton.addTarget(self, action: #selector(self.openWebsite), for: .touchUpInside)
        restaurantFavouritesButton.addTarget(self, action: #selector(self.addToFavourites), for: .touchUpInside)
        restaurantReviewsButton.addTarget(self, action: #selector(self.openReviews), for: .touchUpInside)
        
        forwardButton.tag = 1
        backButton.tag = 0
        
        reviewsContainerView.layer.cornerRadius = 15
        reviewsContainerView.clipsToBounds = true
        reviewsContainerView.isHidden = true
        
        // tableView
        
        categoriesTableView.tableFooterView = UIView(frame: .zero)
        categoriesTableView.backgroundColor = UIColor.clear
        
        reviewsTableView.tableFooterView = UIView(frame: .zero)
        reviewsTableView.backgroundColor = UIColor.clear
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = categoriesTableView.bounds
        categoriesTableView.backgroundView = blurEffectView
        categoriesTableView.separatorEffect = UIBlurEffect(style: UIBlurEffectStyle.prominent)
        
        let blurEffectView2 = UIVisualEffectView(effect: blurEffect)
        blurEffectView2.frame = reviewsTableView.bounds
        reviewsTableView.backgroundView = blurEffectView2
        reviewsTableView.separatorEffect = UIBlurEffect(style: UIBlurEffectStyle.prominent)
        
        let indexPath = IndexPath(row: 0, section: 0)
        self.categoriesTableView.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
        
        completionHandler(true)
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        // add some kind of error view telling user to allow location
        
        if error != nil {
            
            let alrt = UIAlertController(title: "Please Enable Location Services", message: "This application cannot work without enabling Location Services.", preferredStyle: .alert)
            let alrtAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
            alrt.addAction(alrtAction)
            self.present(alrt, animated: true, completion: nil)
            
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
            self.getCategories()
            self.searchBusinesses(self.lat, self.long, completetionHandler: { (success) in
                
                if success {
                    
                    self.loadInterface(completionHandler: { (success) in
                        
                        self.loadCard(self.forwardButton)
                        
                    })
                    
                } else {
                    
                    self.loadInterface(completionHandler: { (success) in
                        
                        self.spinningView.stopAnimating()
                        self.noresultsLabel.text = "No Results In Your Search Radius"
                        self.noresultsLabel.isHidden = false
                        
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
    
    func getCategories() {
        
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
                }
                self.selectedCategory = "All Types"
            }
            
        }
        
    }

    func searchBusinesses(_ lat: Double, _ long: Double, completetionHandler: @escaping (Bool) -> Void) {
        
        let headers: HTTPHeaders = ["Authorization": "Bearer Y43yqZUkj6vah5sgOHU-1PFN2qpapJsSwXZYScYTo0-nK9w5Y3lDvrdRJeG1IpQAADep0GrRL5ZDv6ybln03nIVzP7BL_IzAf_s7Wj5_QLPOO6oXns-nJe3-kIPiWHYx"]
        
        let searchRadius = defaults.integer(forKey: "searchRadius")
        
        var url = ""
        
        switch self.selectedCategory {
        case "All Types":
            
            url = "https://api.yelp.com/v3/businesses/search?radius=\(searchRadius)&latitude=\(lat)&longitude=\(long)&limit=50"
            
        default:
            
            url = "https://api.yelp.com/v3/businesses/search?radius=\(searchRadius)&latitude=\(lat)&longitude=\(long)&limit=50&categories=\(selectedCategory.lowercased())"
            
        }
        
        var name = String()
        var website = String()
        var imageURL = String()
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
                        imageURL = business["image_url"].stringValue
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
                        
                        restaurantHoursToAppend = [RestaurantHours]()
                        
                        self.showBusinessDetails(id, completionHandler: { (arr) in
                            
                            if !(arr.isEmpty) {
                                
                                restaurantHoursToAppend = arr
                                
                            }
                        })
                        
                        for category in business["categories"].arrayValue {
                            
                            restaurantCategory = category["title"].stringValue
                            
                        }
                        
                        let newRestaurant = Restaurant(name: name, website: website, imageURL: imageURL, rating: rating, priceRange: priceRange, phone: phone, id: id, isClosed: closedBool, category: restaurantCategory, reviewCount: reviewCount, distance: distance, city: city, country: country, state: state, address: address, zipCode: zipCode, transactions: transactions)
                        self.restaurants.append(newRestaurant)
                        
                    }
                    
                    completetionHandler(true)
                    
                }
                
            } else {
                
                print("search failed")
                
                // TODO:
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
                
                print(json)
                
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
        
        self.reviewsHeaderLabel.text = "\(self.restaurants[self.restaurantIndex].reviewCount) VOTES"
        
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
    
    func handleSelectedRestaurant(_ category: String, onlySelect: Bool = false) {
        
        self.spinningView.startAnimating()
        self.backButton.isEnabled = false
        self.forwardButton.isEnabled = false
        
        if onlySelect {
            
        } else {
            
            self.card.removeFromSuperview()
            self.restaurants.removeAll()
            self.restaurantIndex = 0
            self.handleTap()
            self.searchBusinesses(self.lat, self.long, completetionHandler: { (success) in
                
                self.noresultsLabel.text = "Loading"
                self.noresultsLabel.isHidden = false
                
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
                                self.noresultsLabel.isHidden = true
                                self.loadCard(self.forwardButton)
                            }
                        }
                        
                    }
                    
                } else {
                    
                    self.noresultsLabel.text = "No Results"
                    self.noresultsLabel.isHidden = false
                    self.spinningView.stopAnimating()
                    self.backButton.isEnabled = false
                    self.forwardButton.isEnabled = false
                    
                }
                
            })
            
        }
        
        
    }
    
    func handleTap() {
        
        if categoryContainerView.isHidden == true {
            
            self.categoryContainerView.isHidden = false
            self.card.isHidden = true
            self.backButton.isEnabled = false
            self.forwardButton.isEnabled = false
            
        } else {
            
            self.categoryContainerView.isHidden = true
            self.card.isHidden = false
            self.backButton.isEnabled = true
            self.forwardButton.isEnabled = true
            
        }
        
        /*
        
        if viewIsOpen {
            
            UIView.animate(withDuration: 0.3, animations: { 
                
                self.categoryContainerView.isHidden = true
                self.forwardButton.isEnabled = true
                
                if self.restaurantIndex == 0 || self.restaurants.isEmpty {
                    
                    self.backButton.isEnabled = false
                    if self.restaurants.isEmpty {
                       self.forwardButton.isEnabled = false
                    }
                    
                } else if self.restaurants.endIndex == self.restaurantIndex {
                    
                    self.backButton.isEnabled = true
                    self.forwardButton.isEnabled = false
                    
                } else {
                    
                    self.backButton.isEnabled = true
                    
                }
                self.card.isHidden = false
                
            })
            
            self.viewIsOpen = false
            
        } else {
            
            UIView.animate(withDuration: 0.3, animations: { 
                
                self.categoryContainerView.isHidden = false
                
            }, completion: { (success) in
                
                self.view.bringSubview(toFront: self.card)
                self.card.isHidden = true
                self.backButton.isEnabled = false
                self.backButton.isEnabled = false
                
            })
            
            self.viewIsOpen = true
            
        }
         */
        
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
            
            self.card.center = CGPoint(x: 300, y: self.card.center.y)
            self.card.alpha = 0
            
        }
        animator.addCompletion { (postion) in
            
            self.card.removeFromSuperview()
            self.restaurantIndex -= 1
            
            if self.restaurants.endIndex == self.restaurantIndex {
                
                self.noresultsLabel.text = "No More Results"
                self.noresultsLabel.isHidden = false
                
                self.backButton.isEnabled = true
                self.forwardButton.isEnabled = false
                
            } else {
                
                DispatchQueue.global(qos: .userInitiated).async {
                    DispatchQueue.main.async {
                        self.loadCard(self.backButton)
                    }
                }
                
            }
            
        }
        animator.startAnimation()
        
        
    }
    
    func goForward() {
        
        self.backButton.isUserInteractionEnabled = false
        
        let animator = UIViewPropertyAnimator(duration: 0.2, curve: .easeOut) {
            
            self.card.center = CGPoint(x: -300, y: self.card.center.y)
            self.card.alpha = 0
            
        }
        
        animator.addCompletion { (postion) in
            
            self.card.removeFromSuperview()
            self.restaurantIndex += 1
            
            if self.restaurants.endIndex == self.restaurantIndex {
                
                self.noresultsLabel.text = "No More Results"
                self.noresultsLabel.isHidden = false
                
                self.backButton.isEnabled = true
                self.forwardButton.isEnabled = false
                
            } else {
                
                DispatchQueue.global(qos: .userInitiated).async {
                    DispatchQueue.main.async {
                        self.loadCard(self.forwardButton)
                    }
                }
                
            }
            
        }
        animator.startAnimation()
        
    }
    
    func handlePan(_ recognizer: UIPanGestureRecognizer) {
        
        let viewCard = recognizer.view!
        let point = recognizer.translation(in: view)
        let xFromCenter = viewCard.center.x - view.center.x
        
        viewCard.center = CGPoint(x: view.center.x + point.x, y: view.center.x + point.y)
        
        let scale = min(100/abs(xFromCenter), 1)
        viewCard.transform = CGAffineTransform(rotationAngle: xFromCenter/divisor).scaledBy(x: scale, y: scale)
        
        let cardAnimator = UIViewPropertyAnimator(duration: 0.3, curve: .easeOut, animations: {
            
            viewCard.center = self.cardCenter
            viewCard.transform = CGAffineTransform.identity
            
        })
        
        if viewCard.frame.intersects(self.statusBarBlur.frame) {
            UIView.animate(withDuration: 0.3, animations: { 
                self.statusBarBlur.effect = UIBlurEffect(style: UIBlurEffectStyle.light)
            })
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.statusBarBlur.effect = nil
            })
        }
        
        if viewCard.frame.intersects(self.buttonsBlurBackground.frame) {
            UIView.animate(withDuration: 0.3, animations: {
                self.buttonsBlurBackground.effect = UIBlurEffect(style: UIBlurEffectStyle.light)
            })
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.buttonsBlurBackground.effect = nil
            })
        }
        
        if xFromCenter > 0 {
            // right
        } else {
            // left
        }
        
        if recognizer.state == UIGestureRecognizerState.ended {
            
            UIView.animate(withDuration: 0.3, animations: {
                self.statusBarBlur.effect = nil
                self.buttonsBlurBackground.effect = nil
            })
            
            if viewCard.center.x < 16 {
                // move to left, go forward
                if self.restaurants.endIndex == self.restaurantIndex {
                    
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
                            self.noresultsLabel.isHidden = false
                            
                            self.backButton.isEnabled = true
                            self.forwardButton.isEnabled = false
                            
                        } else {
                            
                            DispatchQueue.global(qos: .userInitiated).async {
                                DispatchQueue.main.async {
                                    self.loadCard(self.forwardButton)
                                }
                            }
                            
                        }
                        
                    })
                    
                }
                
            } else if viewCard.center.x > (view.frame.width - 16) {
                // move to right side, go back
                
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
                            self.noresultsLabel.isHidden = false
                            
                            self.backButton.isEnabled = true
                            self.forwardButton.isEnabled = false
                            
                        } else {
                            
                            DispatchQueue.global(qos: .userInitiated).async {
                                DispatchQueue.main.async {
                                    self.loadCard(self.backButton)
                                }
                            }
                            
                        }
                        
                    })
                    
                }
                
            }
            
            cardAnimator.startAnimation()
            
        }
        
        
    }
    
    func dataChanged() {
        
        self.spinningView.startAnimating()
        self.noresultsLabel.text = "Loading New Results"
        self.noresultsLabel.isHidden = false
        
        self.card.removeFromSuperview()
        self.restaurants.removeAll()
        self.restaurantIndex = 0
        self.searchBusinesses(self.lat, self.long) { (success) in
            
            self.noresultsLabel.text = "Loading"
            self.noresultsLabel.isHidden = false
            
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
                            self.noresultsLabel.isHidden = true
                            self.loadCard(self.forwardButton)
                        }
                    }
                    
                }
                
            } else {
                
                self.noresultsLabel.text = "No Results"
                self.noresultsLabel.isHidden = false
                self.spinningView.stopAnimating()
                self.backButton.isEnabled = false
                self.forwardButton.isEnabled = false
                
            }
            
        }
        
    }
    
    func addToFavourites() {
        
        restaurant = self.restaurants[self.restaurantIndex]
        
        if defaults.object(forKey: "favourites") == nil {
            
            // no favs, create arr, encode and replace
            
            var favouriteRestaurants = [Restaurant]()
            favouriteRestaurants.append(restaurant)
            
            let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: favouriteRestaurants)
            defaults.set(encodedData, forKey: "favourites")
            defaults.synchronize()
            
        } else {
            
            if let decodedArr = defaults.object(forKey: "favourites") as? Data {
                
                if var decodedRestaurants = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [Restaurant] {
                    
                    if !(decodedRestaurants.contains(where: { $0.id == restaurant.id } )) {
                        
                        // not in favourites
                        decodedRestaurants.append(restaurant)
                        if let del = delegate {
                            del.showAlertView(false)
                        }
                        
                    } else {
                        
                        // already in favourites
                        
                        if let del = delegate {
                            del.showAlertView(true)
                        }
                        
                        // let alert = Alert()
                        // alert.msg(title: "Already In Favourites", message: "The restaurant you favourited is already in your favourites.")
                        
                    }
                    
                    let encode: Data = NSKeyedArchiver.archivedData(withRootObject: decodedRestaurants)
                    defaults.set(encode, forKey: "favourites")
                    defaults.synchronize()
                    
                }
                
            }
            
        }
        
    }
    
    func openReviews() {
        
        if reviewsContainerView.isHidden == true {
            
            self.reviewsContainerView.isHidden = false
            self.card.isHidden = true
            self.backButton.isEnabled = false
            self.forwardButton.isEnabled = false
            
        } else {
            
            self.reviewsContainerView.isHidden = true
            self.card.isHidden = false
            self.backButton.isEnabled = true
            self.forwardButton.isEnabled = true
            
        }
        
    }
    
    func callBusiness() {
        
        restaurant = self.restaurants[self.restaurantIndex]
        
        if let url = URL(string: "tel://\(restaurant.phone)") {
            UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                
                if !success {
                    
                    let alert = Alert()
                    alert.msg(title: "Failed To Call", message: "There's been a slight complication. The call cannot be made, make sure you are using an iPhone or a compatible device.")
                }
                
            })
            
        }
        
    }
    
    func openMaps() {
        
        restaurant = self.restaurants[self.restaurantIndex]
        
        let string = "\(restaurant.address),\(restaurant.city),\(restaurant.country)"
        let addressString = string.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        
        if defaults.object(forKey: "defaultMaps") == nil {
            
            if let url = URL(string: "http://maps.apple.com/?address=\(addressString!)") {
                
                UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                    
                    if !success {
                        
                        let alert = Alert()
                        alert.msg(title: "Failed To Open Maps", message: "There's been a slight complication. Make sure you have Maps installed on your iPhone.")
                        
                    }
                    
                })
            }
            
        } else if let appName = defaults.object(forKey: "defaultMaps") as? String {
            
            if appName == "Apple Maps" {
                
                if let url = URL(string: "http://maps.apple.com/?address=\(addressString!)") {
                    
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                        
                        if !success {
                            
                            let alert = Alert()
                            alert.msg(title: "Failed To Open Maps", message: "There's been a slight complication. Make sure you have Maps installed on your iPhone.")
                        }
                        
                    })
                }
                
            } else if appName == "Waze" {
                
                if let url = URL(string: "waze://?q=\(addressString!)") {
                    
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                        
                        if !success {
                            
                            let alert = Alert()
                            alert.msg(title: "Failed To Open Waze", message: "There's been a slight complication. Waze isn't installed on your iPhone.")
                            
                        }
                        
                    })
                    
                }
                
            } else if appName == "Google Maps" {
                
                if let url = URL(string: "comgooglemaps://?q=\(addressString!)") {
                    
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                        
                        if !success {
                            
                            let alert = Alert()
                            alert.msg(title: "Failed To Open Google Maps", message: "There's been a slight complication. Google Maps isn't installed on your iPhone.")
                        }
                        
                    })
                    
                    
                }
                
            }
            
        }
        
    }
    
    func openWebsite() {
        
        restaurant = self.restaurants[self.restaurantIndex]
        
        if defaults.object(forKey: "defaultBrowser") == nil {
            
            if let url = URL(string: restaurant.website) {
                
                UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                    
                    if !success {
                        
                        let alert = Alert()
                        alert.msg(title: "Failed To Open Safari", message: "There's been a slight complication. This shouldn't be happening.")
                        
                    }
                    
                })
                
            }
            
        } else if let browserName = defaults.object(forKey: "defaultBrowser") as? String {
            
            if browserName == "Safari" {
                
                if let url = URL(string: restaurant.website) {
                    
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                        
                        if !success {
                            
                            let alert = Alert()
                            alert.msg(title: "Failed To Open Safari", message: "There's been a slight complication. This shouldn't be happening.")
                            
                        }
                        
                    })
                    
                }
                
            } else if browserName == "Google Chrome" {
                
                if let url = URL(string: "googlechromes://\(restaurant.website)") {
                    
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                        
                        if !success {
                            
                            let alert = Alert()
                            alert.msg(title: "Failed To Open Google Chrome", message: "There's been a slight complication. Google Chrome isn't installed on your iPhone.")
                            
                        }
                        
                    })
                    
                }
                
            }
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == categoriesTableView {
            
            return self.categories.count
            
        } else {
         
            return self.currentReviews.count
            
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
            
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "ReviewsCell", for: indexPath) as! ReviewsCell
            
            let currentReview = currentReviews[indexPath.row]
            let imageURL = URL(string: currentReview.imageURL)
            
            if let urlThing = imageURL {
                cell.userImage.sd_setImage(with: urlThing, placeholderImage: UIImage(named: "maps"))
            } else {
                cell.userImage.image = #imageLiteral(resourceName: "maps")
            }
            
            cell.userImage.layer.cornerRadius = 6
            cell.userImage.clipsToBounds = true
            
            cell.name.text = currentReview.name
            cell.rating.text = "\(currentReview.rating)"
            cell.textReview.text = currentReview.reviewText
            cell.timeOfReview.text = currentReview.reviewTime
            
            return cell
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == categoriesTableView {
            
            let cell = tableView.cellForRow(at: indexPath) as! CategoryTableViewCell
            
            self.selectedCategory = cell.categoryLabel.text!
            self.handleSelectedRestaurant(self.selectedCategory)
            
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

