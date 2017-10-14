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
import SDWebImage
import Hero

protocol OpenDetailView {
    
    func showDetailView()
    
}

protocol ShowReviewView {
    
    func openReviewView()
    
}

protocol ShowAlert {
    
    func showAlertController(_ title: String, _ message: String, _ url: String?)
    
}

class RestaurantCardALT: UIView, UITableViewDelegate, UITableViewDataSource {
    
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
    var feedbackGenerator = UIImpactFeedbackGenerator()
    
    var defaults = UserDefaults.standard
    
    var reviewDelegate: ShowReviewView?
    var showAlertDelegate: ShowAlert?
    var openDetailView: OpenDetailView?
    
    var panGesture = UIPanGestureRecognizer()
    var tapGesture = UITapGestureRecognizer()
    
    var animator: UIViewPropertyAnimator!
    var gradient = CAGradientLayer()
    
    let phoneNumberKit = PhoneNumberKit()
    let device = Device()
    var information = [String]()
    var headers = ["ADDRESS", "PHONE", "TRANSACTIONS"]
    var distanceToMoveBy = CGFloat()
    var photos = [UIImage]()
    
    var restaurant: Restaurant! {
        
        didSet {
            
            let restID = restaurant.id
            
            mainTableView.register(UINib(nibName: "PhotosCell", bundle: nil), forCellReuseIdentifier: "PhotosCell")
            
            alertView.effect = nil
            
            alertView.layer.cornerRadius = 10
            alertView.clipsToBounds = true
            
            let img = restaurant.image
            
            featuredImageView.image = img
            featuredImageView.contentMode = .scaleAspectFill
            featuredImageView.layer.cornerRadius = 8
            featuredImageView.clipsToBounds = true
            featuredImageView.heroID = "\(restID)_image"
            featuredImageView.heroModifiers = [.zPosition(2)]
            
            let image1 = #imageLiteral(resourceName: "btn_addToFavourites").withRenderingMode(.alwaysTemplate)
            let image1S = #imageLiteral(resourceName: "btn_addToFavourites_selected").withRenderingMode(.alwaysTemplate)
            let image2 = #imageLiteral(resourceName: "btn_openWebsite").withRenderingMode(.alwaysTemplate)
            let image2S = #imageLiteral(resourceName: "btn_openWebsite_selected").withRenderingMode(.alwaysTemplate)
            let image3 = #imageLiteral(resourceName: "btn_reviews").withRenderingMode(.alwaysTemplate)
            let image3S = #imageLiteral(resourceName: "btn_reviews_selected").withRenderingMode(.alwaysTemplate)
            let image4 = #imageLiteral(resourceName: "btn_directions").withRenderingMode(.alwaysTemplate)
            let image4S = #imageLiteral(resourceName: "btn_directions_selected").withRenderingMode(.alwaysTemplate)
            let image5 = #imageLiteral(resourceName: "btn_call").withRenderingMode(.alwaysTemplate)
            let image5S = #imageLiteral(resourceName: "btn_call_selected").withRenderingMode(.alwaysTemplate)
            
            addToFavouritesButton.setImage(image1, for: .normal)
            addToFavouritesButton.setImage(image1S, for: .highlighted)
            addToFavouritesButton.imageView?.tintColor = UIColor.white
            addToFavouritesButton.imageView?.contentMode = .scaleAspectFit
            
            websiteButton.setImage(image2, for: .normal)
            websiteButton.setImage(image2S, for: .highlighted)
            websiteButton.imageView?.tintColor = UIColor.white
            websiteButton.imageView?.contentMode = .scaleAspectFit
            
            reviewsButton.setImage(image3, for: .normal)
            reviewsButton.setImage(image3S, for: .highlighted)
            reviewsButton.imageView?.tintColor = UIColor.white
            reviewsButton.imageView?.contentMode = .scaleAspectFit
            
            directionsButton.setImage(image4, for: .normal)
            directionsButton.setImage(image4S, for: .highlighted)
            directionsButton.imageView?.tintColor = UIColor.white
            directionsButton.imageView?.contentMode = .scaleAspectFit
            
            callButton.setImage(image5, for: .normal)
            callButton.setImage(image5S, for: .highlighted)
            callButton.imageView?.tintColor = UIColor.white
            callButton.imageView?.contentMode = .scaleAspectFit
            
            addToFavouritesButton.backgroundColor = UIColor.clear
            websiteButton.backgroundColor = UIColor.clear
            reviewsButton.backgroundColor = UIColor.clear
            directionsButton.backgroundColor = UIColor.clear
            callButton.backgroundColor = UIColor.clear
            
            if device.diagonal == 4 {
                
                setInsets(2)
                
            } else {
                
                setInsets(2)
                
            }
            
            restaurantName.text = restaurant.name
            restaurantName.heroID = "\(restID)_name"
            restaurantName.heroModifiers = [.zPosition(4)]
            
            // start attributed label
            
            // get range of text to colour
            let textColorRange = NSRange(location: 0, length: restaurant.priceRange.count)
            // get location of text to have a darker colour (4 is highest price)
            let nonColor = 4 - restaurant.priceRange.count
            // get range of text to have a darker colour
            let nonTextColorRange = NSRange(location: restaurant.priceRange.count, length: nonColor)
            let multipleText = "$$$$ · " + convert(restaurant.distance)
            
            let attributedString = NSMutableAttributedString(string: multipleText)
            attributedString.setColorForRange(textColorRange, with: UIColor.green)
            attributedString.setColorForRange(nonTextColorRange, with: UIColor.green.withAlphaComponent(0.3))
            
            restaurantPriceAndDistance.attributedText = attributedString
            restaurantPriceAndDistance.heroID = "\(restID)_priceDistance"
            restaurantPriceAndDistance.heroModifiers = [.zPosition(4)]
            
            // end attributed label
            
            restaurantCategory.text = restaurant.category
            restaurantCategory.heroID = "\(restID)_category"
            restaurantCategory.heroModifiers = [.zPosition(4)]
            
            restaurantStars.contentMode = .right
            restaurantStars.rating = Double(restaurant.rating)
            restaurantStars.settings.emptyBorderWidth = 0
            restaurantStars.settings.emptyBorderColor = UIColor.clear
            restaurantStars.settings.emptyColor = UIColor.lightText
            restaurantStars.settings.updateOnTouch = false
            restaurantStars.settings.starSize = 23
            restaurantStars.heroID = "\(restID)_rating"
            restaurantStars.heroModifiers = [.zPosition(2)]
            
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
            gradient.colors = [UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor, UIColor(red: 0, green: 0, blue: 0, alpha: 0.9).cgColor]
            gradient.locations = [0.5, 1.0] // halfway point to endpoint
            gradientView.layer.insertSublayer(gradient, at: 0)
            
            mainBlurView.effect = nil
            
            self.gradientView.layoutSubviews()
            
            gradientView.heroModifiers = [.fade]
            gradientView.layer.cornerRadius = 8
            gradientView.heroID = "\(restID)_gradient"
            self.heroID = "\(restID)_view"
            
            websiteButton.addTarget(self, action: #selector(self.openWebsite), for: UIControlEvents.touchUpInside)
            addToFavouritesButton.addTarget(self, action: #selector(self.addToFavourites), for: UIControlEvents.touchUpInside)
            reviewsButton.addTarget(self, action: #selector(self.openReviewsThatCallsAnotherFunction), for: UIControlEvents.touchUpInside)
            directionsButton.addTarget(self, action: #selector(self.openMaps), for: UIControlEvents.touchUpInside)
            callButton.addTarget(self, action: #selector(self.callBusiness), for: UIControlEvents.touchUpInside)

            checkIfInFavourites()
            
            tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap2(_:)))
            containerView.addGestureRecognizer(tapGesture)
            
            if device.diagonal == 4 {
                
                // restaurantName.font
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
            
            // self.stackViewBlur.frame = self.stackViewBlur.frame.offsetBy(dx: 0, dy: (self.stackViewBlur.bounds.size.height) * 1)
            self.stackViewBlur.alpha = 0.0
            self.stackViewBlur.effect = nil
            
        }
        
        let mainComponents = self.restaurantName.bounds.height + self.restaurantCategory.bounds.height
        let mainConstraints = CGFloat(19 ) // constraints of title and category
        self.mainView.bounds.origin.y = (mainComponents + mainConstraints) - self.bounds.height
        self.distanceToMoveBy = self.mainView.bounds.origin.y
        
    }
    
    func commonInit() {
        
        Bundle.main.loadNibNamed("RestaurantCardALT", owner: self, options: nil)
        
        self.clipsToBounds = true
        self.layer.cornerRadius = 8
        
        addSubview(contentView)
        
    }
    
    func setInsets(_ number: CGFloat) {
        
        addToFavouritesButton.imageEdgeInsets = UIEdgeInsets(top: number, left: 0, bottom: number, right: 0)
        websiteButton.imageEdgeInsets = UIEdgeInsets(top: number, left: 0, bottom: number, right: 0)
        reviewsButton.imageEdgeInsets = UIEdgeInsets(top: number, left: 0, bottom: number, right: 0)
        directionsButton.imageEdgeInsets = UIEdgeInsets(top: number, left: 0, bottom: number, right: 0)
        callButton.imageEdgeInsets = UIEdgeInsets(top: number, left: 0, bottom: number, right: 0)
        
        addToFavouritesButton.backgroundColor = UIColor.clear
        websiteButton.backgroundColor = UIColor.clear
        reviewsButton.backgroundColor = UIColor.clear
        directionsButton.backgroundColor = UIColor.clear
        callButton.backgroundColor = UIColor.clear
        
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
    
    func getBusinessPhotos(_ id: String, completionHandler: @escaping ([URL]) -> ()) {
        
        let headers = ["Authorization": "Bearer Y43yqZUkj6vah5sgOHU-1PFN2qpapJsSwXZYScYTo0-nK9w5Y3lDvrdRJeG1IpQAADep0GrRL5ZDv6ybln03nIVzP7BL_IzAf_s7Wj5_QLPOO6oXns-nJe3-kIPiWHYx"]
        
        Alamofire.request("https://api.yelp.com/v3/businesses/\(id)", headers: headers).responseJSON { (Response) in
            
            if let value = Response.result.value {
                
                let json = JSON(value)
                
                var photoURL = [URL]()
                
                for link in json["photos"].arrayValue {
                    
                    let photoLink = link.stringValue
                    let url = URL(string: photoLink)
                    photoURL.append(url!)
                    
                }
                
                completionHandler(photoURL)
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
            break
            
        }
        
    }
    
    func handleTap2(_ recognizer: UITapGestureRecognizer) {
        
        if let del = openDetailView {
            del.showDetailView()
        }
        
    }
    
    func handleTap(_ recognizer: UITapGestureRecognizer) {
        
        feedbackGenerator = UIImpactFeedbackGenerator()
        feedbackGenerator.prepare()
        
        if didAnimateView {
            
            animator = UIViewPropertyAnimator(duration: 0.4, curve: .easeInOut, animations: {
                self.gradientView.alpha = 1
                self.mainBlurView.effect = nil
                self.mainView.frame = self.mainView.frame.offsetBy(dx: 0, dy: (self.distanceToMoveBy * -1))
                // self.stackViewBlur.frame = self.stackViewBlur.frame.offsetBy(dx: 0, dy: (self.stackViewBlur.bounds.size.height) * 1)
                self.stackViewBlur.alpha = 0.0
                self.stackViewBlur.effect = nil
            })
            animator.addCompletion({ (position) in
                
              self.feedbackGenerator.impactOccurred()
                
            })
            animator.startAnimation()
            didAnimateView = false
            
            checkIfInFavourites()
            
            // view just closed
            
        } else {
            
            animator = UIViewPropertyAnimator(duration: 0.4, curve: .easeInOut, animations: {
                self.gradientView.alpha = 0
                self.mainBlurView.effect = UIBlurEffect(style: UIBlurEffectStyle.dark)
                self.mainView.frame = self.mainView.frame.offsetBy(dx: 0, dy: (self.distanceToMoveBy * 1))
                // self.stackViewBlur.frame = self.stackViewBlur.frame.offsetBy(dx: 0, dy: (self.stackViewBlur.bounds.size.height) * -1)
                self.stackViewBlur.alpha = 1.0
                self.stackViewBlur.effect = UIBlurEffect(style: .dark)
            })
            animator.addCompletion({ (position) in
                
                self.feedbackGenerator.impactOccurred()
                
            })
            animator.startAnimation()
            didAnimateView = true
            
            checkIfInFavourites()
            
            // view just opened
            
        }
        
    }
    
    func attributeText(_ text: String, _ textToAttribute: String, _ attributes: [Attributes], _ color: UIColor?) -> NSMutableAttributedString {
        
        let attributedString = NSMutableAttributedString(string: text)
        
        if attributes.contains(.bold) && attributes.contains(.color) {
            
            // attributes has both bold and color
            attributedString.setBoldForText(textToAttribute)
            attributedString.setColorForText(textToAttribute, with: color!)
            
        } else if attributes.contains(.bold) {
            
            // attributes only has bold
            attributedString.setBoldForText(textToAttribute)
            
        } else {
            
            // attributes only has color
            attributedString.setColorForText(textToAttribute, with: color!)
            
        }
        
        return attributedString
        
    }
    
    func checkIfInFavourites() {
        
        if let decodedArr = defaults.object(forKey: "favourites") as? Data {
            
            if let decodedRestaurants = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [Restaurant] {
                
                if !(decodedRestaurants.contains(where: { $0.id == restaurant.id } )) {
                    
                    // not in favourites -> show add button
                    let image1 = #imageLiteral(resourceName: "btn_addToFavourites").withRenderingMode(.alwaysTemplate)
                    let image1S = #imageLiteral(resourceName: "btn_addToFavourites_selected").withRenderingMode(.alwaysTemplate)
                    
                    // change button image
                    addToFavouritesButton.setImage(image1, for: .normal)
                    addToFavouritesButton.setImage(image1S, for: .highlighted)
                    addToFavouritesButton.imageView?.tintColor = UIColor.white
                    
                    
                } else {
                    
                    // already in favourites -> show remove button
                    
                    let image1 = #imageLiteral(resourceName: "btn_removeFavourites").withRenderingMode(.alwaysTemplate)
                    let image1S = #imageLiteral(resourceName: "btn_removeFavourites_selected").withRenderingMode(.alwaysTemplate)
                    
                    // change button image
                    addToFavouritesButton.setImage(image1, for: .normal)
                    addToFavouritesButton.setImage(image1S, for: .highlighted)
                    addToFavouritesButton.imageView?.tintColor = UIColor.white

                    
                }
                
            }
            
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
            
            showAlertView(false)
            
        } else {
            
            if let decodedArr = defaults.object(forKey: "favourites") as? Data {
                
                if var decodedRestaurants = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [Restaurant] {
                    
                    if !(decodedRestaurants.contains(where: { $0.id == restaurant.id } )) {
                        
                        // not in favourites -> add to favourites
                        decodedRestaurants.append(restaurant)
                        
                        showAlertView(false)
                        
                        let image1 = #imageLiteral(resourceName: "btn_removeFavourites").withRenderingMode(.alwaysTemplate)
                        let image1S = #imageLiteral(resourceName: "btn_removeFavourites_selected").withRenderingMode(.alwaysTemplate)
                        
                        // change button image
                        addToFavouritesButton.setImage(image1, for: .normal)
                        addToFavouritesButton.setImage(image1S, for: .highlighted)
                        addToFavouritesButton.imageView?.tintColor = UIColor.white
                        
                    } else {
                        
                        // already in favourites -> remove from favourites
                        
                        let indexToRemove = decodedRestaurants.index(where: { $0.id == restaurant.id } )
                        
                        decodedRestaurants.remove(at: indexToRemove!)
                        
                        showAlertView(true)
                        
                        let image1 = #imageLiteral(resourceName: "btn_addToFavourites").withRenderingMode(.alwaysTemplate)
                        let image1S = #imageLiteral(resourceName: "btn_addToFavourites_selected").withRenderingMode(.alwaysTemplate)
                        
                        // change button image
                        addToFavouritesButton.setImage(image1, for: .normal)
                        addToFavouritesButton.setImage(image1S, for: .highlighted)
                        addToFavouritesButton.imageView?.tintColor = UIColor.white
                        
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
                    
                    if let del = self.showAlertDelegate {
                        del.showAlertController("Failed To Call", "There's been a slight complication. The call cannot be made, make sure you are using an iPhone or a compatible device.", nil)
                    }
                    
                }
                
            })
            
        }
        
    }
    
    func openMaps() {
        
        let string = "\(restaurant.address),\(restaurant.city),\(restaurant.country)"
        let addressString = string.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        
        if defaults.object(forKey: "defaultMaps") == nil {
            
            // if defaults is nothing, Apple Maps
            
            if let url = URL(string: "http://maps.apple.com/?address=\(addressString!)") {
                
                UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                    
                    if !success {
                        
                        if let del = self.showAlertDelegate {
                            del.showAlertController("Failed To Open Maps", "There's been a slight complication. Make sure you have Maps installed on your iPhone.", nil)
                        }
                        
                    }
                    
                })
            }
            
        } else if let appName = defaults.object(forKey: "defaultMaps") as? String {
            
            switch appName {
                
            case "Apple Maps":
                
                if let url = URL(string: "http://maps.apple.com/?address=\(addressString!)") {
                    
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                        
                        if !success {
                            
                            if let del = self.showAlertDelegate {
                                del.showAlertController("Failed To Open Maps", "There's been a slight complication. Make sure you have Maps installed on your iPhone.", nil)
                            }
                        }
                        
                    })
                }
            
            case "Google Maps":
                
                if let url = URL(string: "comgooglemaps://?q=\(addressString!)") {
                    
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                        
                        if !success {
                            
                            if let del = self.showAlertDelegate {
                                del.showAlertController("Failed To Open Google Maps", "There's been a slight complication. Make sure you have Google Maps installed on your iPhone.", "https://itunes.apple.com/ca/app/google-maps/id585027354?mt=8")
                            }
                        }
                        
                    })
                    
                }
                
            case "Waze":
                
                if let url = URL(string: "waze://?q=\(addressString!)") {
                    
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                        
                        if !success {
                            
                            if let del = self.showAlertDelegate {
                                del.showAlertController("Failed To Open Waze", "There's been a slight complication. Make sure you have Waze installed on your iPhone.", "https://itunes.apple.com/us/app/waze-social-gps-maps-traffic/id323229106?mt=8")
                            }
                            
                        }
                        
                    })
                    
                }
                
            default:
                
                // default is Apple Maps
                
                if let url = URL(string: "http://maps.apple.com/?address=\(addressString!)") {
                    
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                        
                        if !success {
                            
                            if let del = self.showAlertDelegate {
                                del.showAlertController("Failed To Open Maps", "There's been a slight complication. Make sure you have Maps installed on your iPhone.", nil)
                            }
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
                        
                        if let del = self.showAlertDelegate {
                            del.showAlertController("Failed To Open Safari", "There's been a slight complication. Make sure you have Safari installed on your iPhone.", nil)
                        }
                        
                    }
                    
                })
                
            }
            
        } else if let browserName = defaults.object(forKey: "defaultBrowser") as? String {
            
            if browserName == "Safari" {
                
                if let url = URL(string: restaurant.website) {
                    
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                        
                        if !success {
                            
                            if let del = self.showAlertDelegate {
                                del.showAlertController("Failed To Open Safari", "There's been a slight complication. Make sure you have Safari installed on your iPhone.", nil)
                            }
                            
                        }
                        
                    })
                    
                }
                
            } else if browserName == "Google Chrome" {
                
                // use everything after the "https" as url because Google Chrome ¯\_(ツ)_/¯
                let rangeOfScheme = (restaurant.website as NSString).range(of: ":")
                let urlNoScheme = (restaurant.website as NSString).substring(from: rangeOfScheme.location)
                let chromeURLString = "googlechromes" + (urlNoScheme)
                let chromeURL = URL(string: chromeURLString)
                
                if let url = chromeURL {
                    
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                        
                        if !success {
                            
                            if let del = self.showAlertDelegate {
                                del.showAlertController("Failed To Open Google Chrome", "There's been a slight complication. Make sure you have Google Chrome installed on your iPhone.", "https://itunes.apple.com/us/app/google-chrome/id535886823?mt=8")
                            }
                            
                        }
                        
                    })
                    
                }
                
            }
            
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
                self.addToFavouritesButton.isUserInteractionEnabled = true
                
            })
            
        }
        
        if alreadyInFav {
            
            addToFavouritesButton.isUserInteractionEnabled = false
            alertViewImage.image = UIImage(named: "favouritesAlreadyIn")?.withRenderingMode(.alwaysTemplate)
            alertViewLabel.text = "Removed From Favourites"
            blurAnimator.startAnimation()
            
        } else {
            
            addToFavouritesButton.isUserInteractionEnabled = false
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        if device.diagonal > 4.0 || device.diagonal < 0 {
            
            return 2
            
        } else {
            
            return 1
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 0
        
    }
    
    /*
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        if section == 1 {
            
            let blurEffect = UIBlurEffect(style: .dark)
            let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
            let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
            vibrancyEffectView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 20)
            vibrancyEffectView.autoresizingMask = .flexibleWidth
            
            // Create header label
            let vibrantLabel = UILabel()
            vibrantLabel.frame = CGRect(x: 15, y: 30, width: tableView.bounds.size.width, height: 20)
            vibrantLabel.autoresizingMask = .flexibleWidth
            vibrantLabel.text = "PHOTOS"
            vibrantLabel.font = UIFont.systemFont(ofSize: 13)
            vibrantLabel.textColor = UIColor(white: 0.64, alpha: 1)
            
            vibrancyEffectView.contentView.addSubview(vibrantLabel)
            
            return vibrancyEffectView
            
        } else {
            
            return UIView()
            
        }
        
    }
 
     */
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return headers.count
        } else {
            return 1
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "RestaurantTableViewCell", for: indexPath) as! RestaurantTableViewCell
            
            cell.backgroundColor = UIColor.clear
            cell.contentLabel?.text = "\(information[indexPath.row])"
            cell.headerLabel?.text = "\(headers[indexPath.row])"
            cell.selectionStyle = .none
            
            if cell.headerLabel.text == "TRANSACTIONS" && cell.contentLabel.text == "" {
                
                let indexThing = self.headers.index(of: "TRANSACTIONS")
                self.headers.remove(at: indexThing as! Int)
                
                DispatchQueue.main.async {
                    self.mainTableView.reloadData()
                }
                
            }
            
            return cell
            
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "PhotosCell", for: indexPath) as! PhotosTableViewCell
            
            self.getBusinessPhotos(restaurant.id) { (urlArr) in
                
                switch urlArr.count {
                    
                case 1:
                    cell.photo1.sd_setImage(with: urlArr[0], completed: nil)
                    cell.photo2.isHidden = true
                    cell.photo3.isHidden = true
                    
                case 2:
                    cell.photo1.sd_setImage(with: urlArr[0], completed: nil)
                    cell.photo2.sd_setImage(with: urlArr[1], completed: nil)
                    cell.photo3.isHidden = true
                    
                case 3:
                    cell.photo1.sd_setImage(with: urlArr[0], completed: nil)
                    cell.photo2.sd_setImage(with: urlArr[1], completed: nil)
                    cell.photo3.sd_setImage(with: urlArr[2], completed: nil)
                
                default:
                    cell.isHidden = true
                    break
                
                }
                
            }
            
            return cell
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableViewAutomaticDimension
        
    }

}
