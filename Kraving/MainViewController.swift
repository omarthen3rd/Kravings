//
//  MainViewController.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-10-14.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SDWebImage
import SystemConfiguration
import CoreLocation

class MainViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, CLLocationManagerDelegate, UICollectionViewDelegateFlowLayout {
    
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
    var restaurantIndex = 0
    
    var locationManager = CLLocationManager()
    var locationToUse = String()
    var lat = Double()
    var long = Double()
    var cardCenter = CGPoint()
    
    @IBOutlet var cardCollectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        setDefaults()
        setupView()
        
        cardCollectionView.delegate = self
        cardCollectionView.dataSource = self
        
        
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
        
        guard !didPerformGeocode else { return }
        
        didPerformGeocode = true
        locationManager.stopUpdatingLocation()
        
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
            
            let coord = location.coordinate
            self.lat = coord.latitude
            self.long = coord.longitude
            
            self.restaurants.removeAll()
            
            self.getCategories { (success) in
                
                if success {
                    
                    self.searchBusinesses(self.lat, self.long, completetionHandler: { (success) in
                        
                        if success {
                            
                            DispatchQueue.main.async {
                                self.cardCollectionView.reloadData()
                            }
                            
                        } else {
                            
                            
                        }
                        
                    })
                    
                }
                
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
                        
                        let thingy = things.stringValue
                        if thingy == "restaurants" {
                            self.categories.append(item["title"].stringValue)
                        }
                    }
                    
                }
                self.categories.insert("All Types", at: 0)
                DispatchQueue.main.async {
                    // self.categoriesTableView.reloadData()
                    // self.sortByTableView.reloadData()
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
    
    // MARK: - Functions
    
    func setupView() {
        
        self.selectedSortBy = "best_match"
        
        if CLLocationManager.locationServicesEnabled() && CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            
            locationManager.delegate = self
            locationManager.distanceFilter = 100
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            locationManager.requestLocation() // this is when requestLocation delegate function runs and user location is used for 'searchBusinesses' func
            
        } else {
            
            self.getCategories { (success) in
                
                if success {
                    
                    self.searchBusinesses(self.lat, self.long, completetionHandler: { (success) in
                        
                        if success {
                            
                            DispatchQueue.main.async {
                                self.cardCollectionView.reloadData()
                            }
                            
                        }
                        
                    })
                    
                }
                
            }
            
        }
        
    }
    
    func setDefaults() {
        
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
    
    // MARK: - Collection view
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return restaurants.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CardCell", for: indexPath) as! RestaurantCell
        
        cell.restaurant = self.restaurants[indexPath.row]
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return collectionView.frame.size
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
