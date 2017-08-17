//
//  RestaurantCardALT.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-07-08.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import PhoneNumberKit
import Cosmos
import DeviceKit

class Alert {
    
    func msg(title: String, message: String) {
        
        let alertView = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        UIApplication.shared.keyWindow?.rootViewController?.show(alertView, sender: self)
        
    }
    
}

protocol ShowReviewView {
    
    func openReviewView()
    
}

class RestaurantCardALT: UIView, UITableViewDelegate, UITableViewDataSource, CallAlert {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var mainTableView: UITableView!
    @IBOutlet var containerView: UIView!
    @IBOutlet var mainView: UIView!
    @IBOutlet var mainBlurView: UIVisualEffectView!
    @IBOutlet var gradientView: UIView!
    
    @IBOutlet var featuredImageView: UIImageView!
    @IBOutlet var restaurantName: UILabel!
    @IBOutlet var restaurantCategory: UILabel!
    @IBOutlet var restaurantPriceAndDistance: UILabel!
    @IBOutlet var restaurantStars: CosmosView!
    
    @IBOutlet var addToFavouritesButton: UIButton!
    @IBOutlet var websiteButton: UIButton!
    @IBOutlet var reviewsButton: UIButton!
    @IBOutlet var directionsButton: UIButton!
    @IBOutlet var callButton: UIButton!
    @IBOutlet var bottomStackView: UIStackView!
    @IBOutlet var stackViewBlur: UIVisualEffectView!
    
    @IBOutlet var alertView: UIVisualEffectView!
    @IBOutlet var alertViewLabel: UILabel!
    @IBOutlet var alertViewImage: UIImageView!
    
    var didAnimateView = false
    
    var defaults = UserDefaults.standard
    
    var reviewDelegate: ShowReviewView?
    
    var panGesture = UIPanGestureRecognizer()
    var tapGesture = UITapGestureRecognizer()
    
    var animator: UIViewPropertyAnimator!
    var gradient = CAGradientLayer()
    
    let phoneNumberKit = PhoneNumberKit()
    let device = Device()
    var information = [String]()
    var headers = ["ADDRESS", "PHONE", "TRANSACTIONS"]
    var distanceToMoveBy = CGFloat()
    
    var restaurant: Restaurant! {
        
        didSet {
            
            alertView.effect = nil
            
            alertView.layer.cornerRadius = 10
            alertView.clipsToBounds = true
            
            featuredImageView.sd_setImage(with: URL(string: restaurant.imageURL))
            featuredImageView.contentMode = .scaleAspectFill
            
            let image1 = #imageLiteral(resourceName: "btn_addToFavourites").withRenderingMode(.alwaysTemplate)
            let image2 = #imageLiteral(resourceName: "btn_openWebsite").withRenderingMode(.alwaysTemplate)
            let image3 = #imageLiteral(resourceName: "btn_reviews").withRenderingMode(.alwaysTemplate)
            let image4 = #imageLiteral(resourceName: "btn_directions").withRenderingMode(.alwaysTemplate)
            let image5 = #imageLiteral(resourceName: "btn_call").withRenderingMode(.alwaysTemplate)
            
            addToFavouritesButton.setImage(image1, for: .normal)
            addToFavouritesButton.imageView?.tintColor = UIColor.white
            addToFavouritesButton.imageView?.contentMode = .scaleAspectFit
            
            websiteButton.setImage(image2, for: .normal)
            websiteButton.imageView?.tintColor = UIColor.white
            websiteButton.imageView?.contentMode = .scaleAspectFit
            
            reviewsButton.setImage(image3, for: .normal)
            reviewsButton.imageView?.tintColor = UIColor.white
            reviewsButton.imageView?.contentMode = .scaleAspectFit
            
            directionsButton.setImage(image4, for: .normal)
            directionsButton.imageView?.tintColor = UIColor.white
            directionsButton.imageView?.contentMode = .scaleAspectFit
            
            callButton.setImage(image5, for: .normal)
            callButton.imageView?.tintColor = UIColor.white
            callButton.imageView?.contentMode = .scaleAspectFit
            
            if device.diagonal == 4 {
                
                setInsets(5)
                
            } else {
                
                setInsets(3)
                
            }
            
            restaurantName.text = restaurant.name
            
            // start attributed label
            
            let priceText = checkPrice(restaurant.priceRange)
            let multipleText = checkPrice(restaurant.priceRange) + " · " + convert(restaurant.distance)
            
            let attributedString = NSMutableAttributedString(string: multipleText)
            attributedString.setColorForText(priceText, with: UIColor.green)
            
            restaurantPriceAndDistance.attributedText = attributedString
            
            // end attributed label
            
            restaurantCategory.text = restaurant.category
            
            restaurantStars.rating = Double(restaurant.rating)
            restaurantStars.settings.emptyBorderWidth = 0
            restaurantStars.settings.emptyBorderColor = UIColor.clear
            restaurantStars.settings.emptyColor = UIColor.lightText
            restaurantStars.settings.updateOnTouch = false
            restaurantStars.settings.starSize = 26
            
            let address = "\(restaurant.address) \n\(restaurant.city), \(restaurant.state) \n\(restaurant.country)"
            let phoneNumber = returnFormatted(restaurant.phone)
            let transactions = returnTransactions(restaurant.transactions)
            information.append(address)
            information.append(phoneNumber)
            information.append(transactions)
            returnTimings() // appends timings
            
            self.mainTableView.register(UINib(nibName: "RestaurantTableViewCell", bundle: nil), forCellReuseIdentifier: "RestaurantTableViewCell")
            self.mainTableView.estimatedRowHeight = 60
            self.mainTableView.rowHeight = UITableViewAutomaticDimension
            self.mainTableView.setNeedsLayout()
            self.mainTableView.layoutIfNeeded()
            self.mainTableView.tableFooterView = UIView()
            self.mainTableView.separatorColor = UIColor.clear
            
            self.mainTableView.delegate = self
            self.mainTableView.dataSource = self
            
            self.mainTableView.backgroundColor = UIColor.clear
            
            DispatchQueue.main.async {
             
                self.mainTableView.reloadData()
                
            }
            
            gradient.frame = gradientView.bounds
            gradient.colors = [UIColor(red: 0, green: 0, blue: 0, alpha: 0.0).cgColor, UIColor(red: 0, green: 0, blue: 0, alpha: 0.9).cgColor]
            gradient.locations = [0, 1.0]
            gradientView.layer.insertSublayer(gradient, at: 0)
            
            mainBlurView.effect = nil
            
            self.gradientView.layoutSubviews()
            
            websiteButton.addTarget(self, action: #selector(self.openWebsite), for: UIControlEvents.touchUpInside)
            addToFavouritesButton.addTarget(self, action: #selector(self.addToFavourites), for: UIControlEvents.touchUpInside)
            reviewsButton.addTarget(self, action: #selector(self.openReviewsThatCallsAnotherFunction), for: UIControlEvents.touchUpInside)
            directionsButton.addTarget(self, action: #selector(self.openMaps), for: UIControlEvents.touchUpInside)
            callButton.addTarget(self, action: #selector(self.callBusiness), for: UIControlEvents.touchUpInside)
            
            tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            // panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            // mainView.addGestureRecognizer(panGesture)
            containerView.addGestureRecognizer(tapGesture)
            
            if device.diagonal == 4 {
                
                restaurantName.numberOfLines = 1
                restaurantStars.settings.starSize = 22
                
            } else {
                
                restaurantName.numberOfLines = 0
                
            }
            
        }
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override func layoutSubviews() {
        
        self.gradient.frame = self.gradientView.bounds
        
        UIView.animate(withDuration: 0.3) {
            
            self.stackViewBlur.frame = self.stackViewBlur.frame.offsetBy(dx: 0, dy: (self.stackViewBlur.bounds.size.height) * 1)
            
        }
        
        let mainComponents = self.restaurantName.bounds.height + self.restaurantCategory.bounds.height
        let mainConstraints = CGFloat(21) // constraints of title and category
        self.mainView.bounds.origin.y = (mainComponents + mainConstraints) - self.bounds.height
        self.distanceToMoveBy = self.mainView.bounds.origin.y
        
    }
    
    func commonInit() {
        
        Bundle.main.loadNibNamed("RestaurantCardALT", owner: self, options: nil)
        
        self.clipsToBounds = true
        self.layer.cornerRadius = 15.0
        
        addSubview(contentView)
        
    }
    
    func setInsets(_ number: CGFloat) {
        
        addToFavouritesButton.imageEdgeInsets = UIEdgeInsets(top: number, left: 0, bottom: number, right: 0)
        websiteButton.imageEdgeInsets = UIEdgeInsets(top: number, left: 0, bottom: number, right: 0)
        reviewsButton.imageEdgeInsets = UIEdgeInsets(top: number, left: 0, bottom: number, right: 0)
        directionsButton.imageEdgeInsets = UIEdgeInsets(top: number, left: 0, bottom: number, right: 0)
        callButton.imageEdgeInsets = UIEdgeInsets(top: number, left: 0, bottom: number, right: 0)
        
    }
    
    func convert(_ originalDistance: Double) -> String {
        
        let locale = Locale.current
        let isMetric = locale.usesMetricSystem
        
        let distanceMeters = Measurement(value: originalDistance, unit: UnitLength.meters)
        var distance: Measurement<UnitLength>!
        
        if isMetric {
            
            distance = distanceMeters.converted(to: UnitLength.kilometers)
            
        } else {
            
            distance = distanceMeters.converted(to: UnitLength.miles)
            
        }
        
        let numberFormatter = NumberFormatter()
        let measurementFormatter = MeasurementFormatter()
        measurementFormatter.unitOptions = .providedUnit
        measurementFormatter.numberFormatter = numberFormatter
        
        var finalString = String()
        
        if distance.value == 0 {
            
            finalString = measurementFormatter.string(from: distance)
            
        } else if distance.value <= 1 {
            
            numberFormatter.maximumFractionDigits = 2
            finalString = "0" + measurementFormatter.string(from: distance)
            
        } else {
            
            numberFormatter.maximumFractionDigits = 1
            finalString = measurementFormatter.string(from: distance)
            
        }
        
        return finalString + " away"
        
    }
    
    func checkPrice(_ range: String) -> String {
        
        if range == "" {
            
            return "Price Unavailable"
            
        } else {
            
            return "\(range)"
            
        }
        
        /*
        if range.characters.count == 1 {
            
            return "\(range) - Relatively Cheap"
            
        } else if range.characters.count == 2 {
            
            return "\(range) - Not That Expensive"
            
        } else if range.characters.count == 3 {
            
            return "\(range) - Quite Expensive"
            
        } else {
            
            return "Price Range Is Unknown"
            
        } */
        
    }
    
    func returnTimings() {
        
        var timings = String()
        
        showBusinessDetails(restaurant.id) { (arr) in
            
            if !(arr.isEmpty) {
                
                for operationDay in arr {
                    
                    if operationDay.day == self.getCurrentDay() {
                                                
                        timings = "\(operationDay.startTime) to " + "\(operationDay.endTime)"
                        self.information.insert(timings, at: 2)
                        self.headers.insert("TIMINGS", at: 2)
                        
                        DispatchQueue.main.async {
                            
                            self.mainTableView.reloadData()
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func getCurrentDay() -> String {
        
        let date = Date()
        let calendar = Calendar.current
        
        let timeZoneAbbr = TimeZone.current.abbreviation()
        
        let day = calendar.component(.weekday, from: date)
        
        let f = DateFormatter()
        f.timeZone = TimeZone(abbreviation: timeZoneAbbr!)
        
        var weekDay = String()
        
        switch day {
            
        case 2:
            weekDay = "Monday"
        case 3:
            weekDay = "Tuesday"
        case 4:
            weekDay = "Wednesday"
        case 5:
            weekDay = "Thursday"
        case 6:
            weekDay = "Friday"
        case 7:
            weekDay = "Saturday"
        case 1:
            weekDay = "Sunday"
        default:
            weekDay = "Unknown"
            
        }
        
        return weekDay
        
    }
    
    func returnFormatted(_ phoneNumber: String) -> String {
        
        do {
            
            let parsedPhoneNumber = try phoneNumberKit.parse(phoneNumber)
            let formattedNumber = phoneNumberKit.format(parsedPhoneNumber, toType: .international)
            return "\(formattedNumber)"
            
        } catch {
            
            return "Phone Number Unknown"
            
        }
        
    }
    
    func returnTransactions(_ transactions: [String]) -> String {
    
        var restaurantTransactions = ""
        
        for transaction in transactions {
            
            if transaction == "restaurant_reservation" {
                
                restaurantTransactions = restaurantTransactions + "Restaurant Reservation ✓ "
                
            } else {
                
                restaurantTransactions = restaurantTransactions + "\(transaction.uppercaseFirst) ✓ "
                
            }
            
        }
        
        return restaurantTransactions
    
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
    
    func handlePan(_ recognizer: UIPanGestureRecognizer) {
        
        switch recognizer.state {
            
        case .began:
            
            if didAnimateView {
                
                animator = UIViewPropertyAnimator(duration: 0.8, curve: .linear, animations: {
                    self.gradient.opacity = 0
                    self.mainBlurView.effect = UIBlurEffect(style: UIBlurEffectStyle.dark)
                    self.mainView.frame = self.mainView.frame.offsetBy(dx: 0, dy: -335)
                })
                animator.pauseAnimation()
                didAnimateView = false
                
            } else {
                
                animator = UIViewPropertyAnimator(duration: 0.8, curve: .linear, animations: {
                    self.gradient.opacity = 1
                    self.mainBlurView.effect = nil
                    self.mainView.frame = self.mainView.frame.offsetBy(dx: 0, dy: 335)
                })
                animator.pauseAnimation()
                didAnimateView = true
                
            }
            
        case .changed:
            let translation = recognizer.translation(in: mainView)
            animator.fractionComplete = translation.y / 481
            
        case .ended:
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
            
        default:
            print("default")
            
        }
        
    }
    
    func handleTap(_ recognizer: UITapGestureRecognizer) {
        
        if didAnimateView {
            
            animator = UIViewPropertyAnimator(duration: 0.4, curve: .easeOut, animations: {
                self.gradient.opacity = 1
                self.mainBlurView.effect = nil
                self.mainView.frame = self.mainView.frame.offsetBy(dx: 0, dy: (self.distanceToMoveBy * -1))
                self.stackViewBlur.frame = self.stackViewBlur.frame.offsetBy(dx: 0, dy: (self.stackViewBlur.bounds.size.height) * 1)
            })
            animator.startAnimation()
            didAnimateView = false
            
            // view just closed
            
        } else {
            
            animator = UIViewPropertyAnimator(duration: 0.4, curve: .easeOut, animations: {
                self.gradient.opacity = 0
                self.mainBlurView.effect = UIBlurEffect(style: UIBlurEffectStyle.dark)
                self.mainView.frame = self.mainView.frame.offsetBy(dx: 0, dy: (self.distanceToMoveBy * 1))
                self.stackViewBlur.frame = self.stackViewBlur.frame.offsetBy(dx: 0, dy: (self.stackViewBlur.bounds.size.height) * -1)
            })
            animator.startAnimation()
            didAnimateView = true
            
            // view just opened
            
        }
        
    }
    
    func addToFavourites() {
        
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
                        
                    } else {
                        
                        // already in favourites
                        
                        let alert = Alert()
                        alert.msg(title: "Already In Favourites", message: "The restaurant you favourited is already in your favourites.")
                        
                    }
                    
                    let encode: Data = NSKeyedArchiver.archivedData(withRootObject: decodedRestaurants)
                    defaults.set(encode, forKey: "favourites")
                    defaults.synchronize()
                    
                }
                
            }
            
        }
        
    }
    
    func callBusiness() {
        
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
    
    func setDelegate(controller: UIViewController) {
        
        if let control = controller as? ViewController {
            control.delegate = self
        }
        
    }
    
    func showAlertView(_ alreadyInFav: Bool) {
        
        let blurAnimator = UIViewPropertyAnimator(duration: 0.3, curve: .linear) {
            
            self.alertView.isHidden = false
            self.alertViewLabel.alpha = 1
            self.alertViewImage.alpha = 1
            self.alertView.effect = UIBlurEffect(style: UIBlurEffectStyle.extraLight)
            
        }
        blurAnimator.addCompletion { (position) in
            
            UIView.animate(withDuration: 0.3, delay: 2, usingSpringWithDamping: 0.0, initialSpringVelocity: 0.0, options: [], animations: {
                
                self.alertView.effect = nil
                self.alertViewLabel.alpha = 0
                self.alertViewImage.alpha = 0
                
            }, completion: { (success) in
                
                self.alertView.isHidden = true
                
            })
            
        }
        
        if alreadyInFav {
            
            alertViewImage.image = UIImage(named: "favouritesAlreadyIn")?.withRenderingMode(.alwaysTemplate)
            alertViewLabel.text = "Already In Favourites"
            blurAnimator.startAnimation()

        } else {
            
            alertViewImage.image = UIImage(named: "favouritesAddedIn")?.withRenderingMode(.alwaysTemplate)
            alertViewLabel.text = "Added To Favourites"
            blurAnimator.startAnimation()
            
        }
        
    }
    
    func openReviewsThatCallsAnotherFunction() {
        
        if let del = reviewDelegate {
            del.openReviewView()
        }
        
    }
    
    /*
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        
        if (addToFavouritesButton.frame).contains(point) {
            
            print("touch in point")
            
            return false
            
        } else {
            
            return true
            
        }
        
        /*
        
        let touch = event?.allTouches?.first
        print(touch)

        let location = touch?.location(in: addToFavouritesButton)
        print(location)
        
        let inside = addToFavouritesButton.frame.contains(location!)
        
        if inside {
            print("is inside")
            return false
        } else {
            print("is not inside")
            return true
        }
        
        */
        
    }
    
    */
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return headers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "RestaurantTableViewCell", for: indexPath) as! RestaurantTableViewCell
        
        if headers[indexPath.row] == "ADDRESS" {
            
            cell.isUserInteractionEnabled = true
            
        } else if headers[indexPath.row] == "PHONE" {
            
            cell.isUserInteractionEnabled = true
            
        } else {
            
            cell.isUserInteractionEnabled = false
            
        }
        
        cell.backgroundColor = UIColor.clear
        cell.contentLabel?.text = "\(information[indexPath.row])"
        cell.headerLabel?.text = "\(headers[indexPath.row])"
        cell.selectionStyle = .none
        
        if cell.headerLabel.text == "TRANSACTIONS" && cell.contentLabel.text == "" {
            
            cell.isHidden = true
            
        }
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableViewAutomaticDimension
        
    }
    
    /*
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return false
    }
    */

}
