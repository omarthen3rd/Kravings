//
//  RestaurantCard.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-07-07.
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

class RestaurantCard: UIView {

    @IBOutlet var contentView: UIView!
    
    @IBOutlet var mainVibrancyView: UIVisualEffectView!
    @IBOutlet var mainBlurView: UIVisualEffectView!
    @IBOutlet var mainView: UIView!
    @IBOutlet var featuredImage: UIImageView!
    @IBOutlet var restaurantNameLabel: UILabel!
    @IBOutlet var restaurantCategory: UILabel!
    @IBOutlet var restaurantStars: CosmosView!
    @IBOutlet var restaurantPriceRange: UILabel!
    @IBOutlet var restaurantDistance: UILabel!
    @IBOutlet var restaurantLocation: UILabel!
    @IBOutlet var restaurantPhone: UILabel!
    @IBOutlet var restaurantTimings: UILabel!
    @IBOutlet var restaurantTransactions: UILabel!
   
    @IBOutlet var vibrancyAddress: UILabel!
    @IBOutlet var vibrancyContact: UILabel!
    @IBOutlet var vibrancyTimings: UILabel!
    @IBOutlet var vibrancyTransactions: UILabel!
    
    var panGesture = UIPanGestureRecognizer()
    var tapGesture = UITapGestureRecognizer()
    
    var animator: UIViewPropertyAnimator!
    var gradient = CAGradientLayer()
    
    let phoneNumberKit = PhoneNumberKit()
    
    var didAnimateView = false
    
    var restaurant: Restaurant! {
        
        didSet {
            
            let backgroundURL = URL(string: restaurant.imageURL)
            featuredImage.sd_setImage(with: backgroundURL!)
            featuredImage.contentMode = .scaleAspectFill
            
            restaurantNameLabel.text = restaurant.name
            restaurantCategory.text = restaurant.category
            restaurantStars.rating = Double(restaurant.rating)
            restaurantStars.isUserInteractionEnabled = false
            restaurantPriceRange.text = checkPrice(restaurant.priceRange)
            restaurantDistance.text = convert(restaurant.distance)
            restaurantLocation.text = "\(restaurant.address) \n\(restaurant.city), \(restaurant.state) \n\(restaurant.country)"
            
            do {
                
                let phoneNumber = try phoneNumberKit.parse(restaurant.phone)
                let formattedNumber = phoneNumberKit.format(phoneNumber, toType: .international)
                restaurantPhone.text = "Phone: \(formattedNumber)"
                
            } catch {
                
                restaurantPhone.text = "Phone: \(restaurant.phone)"
                
            }
            
            restaurantTransactions.text = ""
            
            for transaction in restaurant.transactions {
                
                if transaction == "restaurant_reservation" {
                    
                    restaurantTransactions.text = restaurantTransactions.text! + "Restaurant Reservation ✓ \n"
                    
                } else {
                    
                    restaurantTransactions.text = restaurantTransactions.text! + "\(transaction.uppercaseFirst) ✓ \n"
                    
                }
                
            }
            
            if restaurant.transactions.isEmpty {
                
                restaurantTransactions.isHidden = true
                vibrancyTransactions.isHidden = true
                
            }
            
            gradient.frame = featuredImage.bounds
            gradient.colors = [UIColor(red: 0, green: 0, blue: 0, alpha: 0.0).cgColor, UIColor(red: 0, green: 0, blue: 0, alpha: 0.6).cgColor]
            gradient.locations = [0.0, 1.0]
            featuredImage.layer.insertSublayer(gradient, at: 0)
            
            tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            // mainView.addGestureRecognizer(panGesture)
            mainView.addGestureRecognizer(tapGesture)
            
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
    
    func commonInit() {
        
        Bundle.main.loadNibNamed("RestaurantCard", owner: self, options: nil)
        
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
            
            return "\(range) - Expensive"
            
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
                    self.mainVibrancyView.frame = self.mainVibrancyView.frame.offsetBy(dx: 0, dy: -335)
                    self.mainBlurView.effect = UIBlurEffect(style: UIBlurEffectStyle.dark)
                    self.mainView.frame = self.mainView.frame.offsetBy(dx: 0, dy: -335)
                })
                animator.pauseAnimation()
                didAnimateView = false
                
            } else {
                
                animator = UIViewPropertyAnimator(duration: 0.8, curve: .linear, animations: {
                    self.gradient.opacity = 1
                    self.mainVibrancyView.frame = self.mainVibrancyView.frame.offsetBy(dx: 0, dy: 335)
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
                self.gradient.opacity = 0
                self.mainVibrancyView.frame = self.mainVibrancyView.frame.offsetBy(dx: 0, dy: -335)
                self.mainBlurView.effect = UIBlurEffect(style: UIBlurEffectStyle.dark)
                self.mainView.frame = self.mainView.frame.offsetBy(dx: 0, dy: -335)
            })
            animator.startAnimation()
            didAnimateView = false
            
        } else {
            
            animator = UIViewPropertyAnimator(duration: 0.4, curve: .easeOut, animations: {
                self.gradient.opacity = 1
                self.mainVibrancyView.frame = self.mainVibrancyView.frame.offsetBy(dx: 0, dy: 335)
                self.mainBlurView.effect = nil
                self.mainView.frame = self.mainView.frame.offsetBy(dx: 0, dy: 335)
            })
            animator.startAnimation()
            didAnimateView = true
            
        }
        
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
