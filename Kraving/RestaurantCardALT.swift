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

class Alert {
    
    func msg(title: String, message: String) {
        
        let alertView = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        UIApplication.shared.keyWindow?.rootViewController?.show(alertView, sender: self)
        
    }
    
}

class RestaurantCardALT: UIView, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var mainTableView: UITableView!
    @IBOutlet var containerMainView: UIView!
    @IBOutlet var mainView: UIView!
    @IBOutlet var mainBlurView: UIVisualEffectView!
    @IBOutlet var gradientView: UIView!
    
    @IBOutlet var featuredImageView: UIImageView!
    @IBOutlet var restaurantName: UILabel!
    @IBOutlet var restaurantCategory: UILabel!
    @IBOutlet var restaurantStars: CosmosView!
    @IBOutlet var restaurantPriceRange: UILabel!
    @IBOutlet var restaurantDistance: UILabel!
    
    @IBOutlet var buttonsBlurBackground: UIVisualEffectView!
    @IBOutlet var restaurantPhoneButton: UIButton!
    @IBOutlet var restaurantMapsButton: UIButton!
    @IBOutlet var restaurantWebsiteButton: UIButton!
    @IBOutlet var restaurantReviewsButton: UIButton!
    
    var didAnimateView = false
    
    var defaults = UserDefaults.standard
    
    var panGesture = UIPanGestureRecognizer()
    var tapGesture = UITapGestureRecognizer()
    
    var animator: UIViewPropertyAnimator!
    var gradient = CAGradientLayer()
    
    let phoneNumberKit = PhoneNumberKit()
    var information = [String]()
    var headers = ["ADDRESS", "CONTACT", "TRANSACTIONS"]
    var distanceToMoveBy = CGFloat()
    
    var restaurant: Restaurant! {
        
        didSet {
            
            featuredImageView.sd_setImage(with: URL(string: restaurant.imageURL))
            featuredImageView.contentMode = .scaleAspectFill
            
            restaurantName.text = restaurant.name
            restaurantCategory.text = restaurant.category
            restaurantStars.rating = Double(restaurant.rating)
            restaurantStars.settings.emptyBorderWidth = 0
            restaurantStars.settings.emptyBorderColor = UIColor.clear
            restaurantStars.settings.emptyColor = UIColor.lightText
            restaurantStars.settings.updateOnTouch = false
            restaurantPriceRange.text = checkPrice(restaurant.priceRange)
            restaurantDistance.text = convert(restaurant.distance)
            
            let address = "\(restaurant.address) \n\(restaurant.city), \(restaurant.state) \n\(restaurant.country)"
            let phoneNumber = returnFormatted(restaurant.phone)
            let transactions = returnTransactions(restaurant.transactions)
            information.append(address)
            information.append(phoneNumber)
            information.append(transactions)
            returnTimings() // appends timings
            
            self.mainTableView.register(UINib(nibName: "RestaurantTableViewCell", bundle: nil), forCellReuseIdentifier: "RestaurantTableViewCell")
            self.mainTableView.estimatedRowHeight = 400
            self.mainTableView.rowHeight = UITableViewAutomaticDimension
            self.mainTableView.setNeedsLayout()
            self.mainTableView.layoutIfNeeded()
            self.mainTableView.tableFooterView = UIView()
            self.mainTableView.separatorColor = UIColor.clear
            
            self.mainTableView.delegate = self
            self.mainTableView.dataSource = self
            
            self.mainTableView.backgroundColor = UIColor.clear
            self.buttonsBlurBackground.alpha = 0.0
            
            DispatchQueue.main.async {
             
                self.mainTableView.reloadData()
                
            }
            
            gradient.frame = gradientView.bounds
            gradient.colors = [UIColor(red: 0, green: 0, blue: 0, alpha: 0.0).cgColor, UIColor(red: 0, green: 0, blue: 0, alpha: 0.9).cgColor]
            gradient.locations = [0, 1.0]
            gradientView.layer.insertSublayer(gradient, at: 0)
            
            mainBlurView.effect = nil
            
            self.gradientView.layoutSubviews()
            
            restaurantPhoneButton.addTarget(self, action: #selector(self.callBusiness), for: .touchUpInside)
            
            tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            // panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            // mainView.addGestureRecognizer(panGesture)
            containerMainView.addGestureRecognizer(tapGesture)
            
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
        
        let mainComponents = self.restaurantName.bounds.height + self.restaurantCategory.bounds.height + restaurantPriceRange.bounds.height + restaurantDistance.bounds.height
        let mainConstraints = CGFloat(34)
        self.mainView.bounds.origin.y = (mainComponents + mainConstraints) - self.bounds.height
        self.distanceToMoveBy = self.mainView.bounds.origin.y
        
    }
    
    func commonInit() {
        
        Bundle.main.loadNibNamed("RestaurantCardALT", owner: self, options: nil)
        
        self.clipsToBounds = true
        self.layer.cornerRadius = 15.0
        
        addSubview(contentView)
        
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
        
        if distance.value < 1 {
            
            numberFormatter.maximumFractionDigits = 2
            finalString = "0" + measurementFormatter.string(from: distance)
            
        } else {
            
            numberFormatter.maximumFractionDigits = 1
            finalString = measurementFormatter.string(from: distance)
            
        }
        
        return finalString + " away from you"
        
    }
    
    func checkPrice(_ range: String) -> String {
        
        if range.characters.count == 1 {
            
            return "\(range) - Relatively Cheap"
            
        } else if range.characters.count == 2 {
            
            return "\(range) - Not That Expensive"
            
        } else if range.characters.count == 3 {
            
            return "\(range) - Quite Expensive"
            
        } else {
            
            return "Price Range Is Unknown"
            
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
            return "Phone: \(formattedNumber)"
            
        } catch {
            
            return "Phone Number Unknown"
            
        }
        
    }
    
    func returnTransactions(_ transactions: [String]) -> String {
    
        var restaurantTransactions = ""
        
        for transaction in transactions {
            
            if transaction == "restaurant_reservation" {
                
                restaurantTransactions = restaurantTransactions + "Restaurant Reservation ✓ \n"
                
            } else {
                
                restaurantTransactions = restaurantTransactions + "\(transaction.uppercaseFirst) ✓ \n"
                
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
                    self.buttonsBlurBackground.alpha = 0.0
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
                self.buttonsBlurBackground.alpha = 0.0
                self.mainBlurView.effect = nil
                self.mainView.frame = self.mainView.frame.offsetBy(dx: 0, dy: (self.distanceToMoveBy * -1))
            })
            animator.startAnimation()
            didAnimateView = false
            
        } else {
            
            animator = UIViewPropertyAnimator(duration: 0.4, curve: .easeOut, animations: {
                self.gradient.opacity = 0
                self.buttonsBlurBackground.alpha = 1.0
                self.mainBlurView.effect = UIBlurEffect(style: UIBlurEffectStyle.dark)
                self.mainView.frame = self.mainView.frame.offsetBy(dx: 0, dy: (self.distanceToMoveBy * 1))
            })
            animator.startAnimation()
            didAnimateView = true
            
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return headers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "RestaurantTableViewCell", for: indexPath) as! RestaurantTableViewCell
        
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

}
