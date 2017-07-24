//
//  FavouritesDetailTableViewController.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-07-12.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit
import Cosmos
import PhoneNumberKit
import Alamofire
import SwiftyJSON

class FavouritesDetailTableViewController: UITableViewController {
    
    @IBOutlet var cellImage: UIImageView!
    @IBOutlet var restaurantTitle: UILabel!
    @IBOutlet var restaurantCategory: UILabel!
    @IBOutlet var restaurantStars: CosmosView!
    @IBOutlet var restaurantPriceRange: UILabel!
    @IBOutlet var restaurantDistance: UILabel!
    @IBOutlet var restaurantAddress: UILabel!
    @IBOutlet var restaurantPhoneNumber: UILabel!
    @IBOutlet var restaurantTimings: UILabel!
    
    let defaults = UserDefaults.standard
    var phoneNumberKit = PhoneNumberKit()
    var blurView = UIVisualEffectView()
    
    typealias TimeOfDay = (hour: Int, minute: Int)
    
    var restaurant: Restaurant! {
        
        didSet {
            
            setupView()
            
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.tableView.estimatedRowHeight = 400
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.setNeedsLayout()
        self.tableView.layoutIfNeeded()
        self.tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupView() {
        
        if let url = URL(string: restaurant.imageURL) {
            
            let backgroundImage = UIImageView()
            backgroundImage.sd_setImage(with: url)
            // self.tableView.backgroundView = backgroundImage
            
            tableView.tableFooterView = UIView()
            
            tableView.backgroundColor = UIColor.clear
            
            let blurEffect = UIBlurEffect(style: .dark)
            blurView = UIVisualEffectView(effect: blurEffect)
            blurView.frame = backgroundImage.bounds
            // backgroundImage.addSubview(blurView)
            
            cellImage.sd_setImage(with: url)
            
            restaurantTitle.text = restaurant.name
            restaurantCategory.text = restaurant.category
            restaurantStars.rating = Double(restaurant.rating)
            restaurantStars.text = "\(restaurant.reviewCount) VOTES"
            restaurantStars.settings.textColor = UIColor.lightGray
            restaurantAddress.text = "\(restaurant.address) \n\(restaurant.city), \(restaurant.state) \n\(restaurant.country)"
            restaurantPhoneNumber.text = returnFormatted(restaurant.phone)
            restaurantPriceRange.text = checkPrice(restaurant.priceRange)
            restaurantDistance.text = convert(restaurant.distance)
            doTimings()
            
            setColor(UIColor.white)
            
            
        }
        
        if defaults.object(forKey: "defaultMaps") == nil {
            
            defaults.set("Apple Maps", forKey: "defaultMaps")
            
        }
        
        if defaults.object(forKey: "defaultBrowser") == nil {
            
            defaults.set("Safari", forKey: "defaultBrowser")
            
        }
        
    }
    
    func setColor(_ color: UIColor) {
        
        restaurantTitle.textColor = color
        restaurantCategory.textColor = color
        restaurantAddress.textColor = color
        restaurantDistance.textColor = color
        restaurantTimings.textColor = color
        restaurantPhoneNumber.textColor = color
        restaurantStars.settings.emptyColor = UIColor.lightText
        
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
    
    func doTimings() {
        
        showBusinessDetails(restaurant.id) { (arr) in
            
            if !(arr.isEmpty) {
                
                for operationDay in arr {
                    
                    if operationDay.day == self.getCurrentDay() {
                        
                        self.restaurantTimings.text = "\(operationDay.startTime) to " + "\(operationDay.endTime)"
                        
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
    
    func compareDates(_ time: String) {
        
        let calendar = Calendar.autoupdatingCurrent
        
        var timeToUse = time
        timeToUse.insert(":", at: time.index(time.startIndex, offsetBy: 2))
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let dateToUse = timeFormatter.date(from: timeToUse)
        
        let components = calendar.dateComponents([.hour, .minute], from: dateToUse!)
        let hourToUse = components.hour
        let minuteToUse = components.minute
        
        let components2 = calendar.dateComponents([.hour, .minute], from: Date())
        let hourToUse2 = components2.hour
        let minuteToUse2 = components2.minute
        
        var timeOfDay = [TimeOfDay]()
        timeOfDay.append((hourToUse!, minuteToUse!))
        timeOfDay.append((hourToUse2!, minuteToUse2!))
        
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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableViewAutomaticDimension
        
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
