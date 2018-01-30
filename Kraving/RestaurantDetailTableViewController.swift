//
//  RestaurantDetailTableViewController.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-10-07.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit
import Alamofire
import Cosmos
import SwiftyJSON
import ChameleonFramework
import PhoneNumberKit
import SimpleImageViewer

protocol TimingsView {
    
    func openTimingsView()
    
}

extension UIImageView {
    
    func addBlurEffect(_ style: UIBlurEffectStyle) {
        let blurEffect = UIBlurEffect(style: style)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = CGRect(x: 0, y: 219, width: self.bounds.size.width, height: self.bounds.size.height - 219)
        
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight] // for supporting device rotation
        self.addSubview(blurEffectView)
    }
    
}

class RestaurantDetailTableViewController: UITableViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet var restaurantPhoto: UIImageView!
    @IBOutlet var restaurantName: UILabel!
    @IBOutlet var restaurantCategory: UILabel!
    @IBOutlet var restaurantRating: CosmosView!
    @IBOutlet var restaurantPriceDistance: UILabel!
    
    @IBOutlet var restaurantAddressTitle: UILabel!
    @IBOutlet var restaurantAddress: UILabel!
    
    @IBOutlet var restaurantPhoneTitle: UILabel!
    @IBOutlet var restaurantPhone: UILabel!
    
    @IBOutlet var restaurantTimingsTitle: UILabel!
    @IBOutlet var restaurantOpenOrCloseButton: UIButton!
    @IBOutlet var restaurantOpenOrCloseButtonConstraint: NSLayoutConstraint!
    @IBOutlet var restaurantTimings: UILabel!
    
    @IBOutlet var restaurantPhotosTitle: UILabel!
    @IBOutlet var photosCollectionView: UICollectionView!
    
    var timingDelegate: TimingsView?
    var restaurant: Restaurant?
    var phoneNumberKit = PhoneNumberKit()
    var photos = [URL]()
    var isRestaurantOpen = Bool()
    
    typealias TimeOfDay = (hour: Int, minute: Int)
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - Default Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setNeedsStatusBarAppearanceUpdate()
        self.photosCollectionView.delegate = self
        self.photosCollectionView.dataSource = self
        
        let restaurantToUse = restaurant
        
        if let restaurant = restaurantToUse {
            
            let avgColor = UIColor(averageColorFrom: restaurant.image!)
            let contrastColor = UIColor(contrastingBlackOrWhiteColorOn: avgColor, isFlat: true)
            
            restaurantName.text = restaurant.name
            restaurantName.textColor = contrastColor
            
            restaurantPhoto.image = restaurant.image
            restaurantPhoto.clipsToBounds = true
            restaurantPhoto.contentMode = .scaleAspectFill
            
            restaurantCategory.text = restaurant.category
            setOtherCategories()
            restaurantCategory.textColor = contrastColor
            restaurantCategory.numberOfLines = 0
            
            restaurantRating.contentMode = .right
            restaurantRating.rating = Double(restaurant.rating)
            restaurantRating.text = "\(restaurant.reviewCount) VOTES"
            restaurantRating.settings.textColor = contrastColor
            restaurantRating.settings.emptyBorderWidth = 0
            restaurantRating.settings.filledBorderColor = UIColor.clear
            restaurantRating.settings.emptyBorderColor = UIColor.clear
            restaurantRating.settings.filledColor = contrastColor
            restaurantRating.settings.emptyColor = contrastColor.withAlphaComponent(0.3)
            restaurantRating.settings.updateOnTouch = false
            restaurantRating.settings.starSize = 23
            
            // start attributed label
            
            restaurantPriceDistance.textColor = contrastColor
            
            // get range of text to colour
            let textColorRange = NSRange(location: 0, length: restaurant.priceRange.count)
            // get location of text to have a darker colour (4 is highest price)
            let nonColor = 4 - restaurant.priceRange.count
            // get range of text to have a darker colour
            let nonTextColorRange = NSRange(location: restaurant.priceRange.count, length: nonColor)
            let multipleText = "$$$$ · " + convert(restaurant.distance)
            
            let attributedString = NSMutableAttributedString(string: multipleText)
            attributedString.setColorForRange(textColorRange, with: contrastColor)
            attributedString.setColorForRange(nonTextColorRange, with: contrastColor.withAlphaComponent(0.3))
            restaurantPriceDistance.attributedText = attributedString
            
            // end attributed label
            
            restaurantAddressTitle.textColor = contrastColor.withAlphaComponent(0.7)
            let address = "\(restaurant.address) \n\(restaurant.city), \(restaurant.state) \n\(restaurant.country)"
            restaurantAddress.text = address
            restaurantAddress.textColor = contrastColor
            
            restaurantPhoneTitle.textColor = contrastColor.withAlphaComponent(0.7)
            let phoneNumber = returnFormatted(restaurant.phone)
            restaurantPhone.text = phoneNumber
            restaurantPhone.textColor = contrastColor
            
            // does timings and sets everything
            doTimings()
            restaurantTimingsTitle.textColor = contrastColor.withAlphaComponent(0.7)
            restaurantTimings.textColor = contrastColor
            restaurantTimings.text = "Loading..."
            
            restaurantOpenOrCloseButton.backgroundColor = contrastColor
            restaurantOpenOrCloseButton.setTitleColor(avgColor, for: .normal)
            restaurantOpenOrCloseButton.layer.cornerRadius = 6
            restaurantOpenOrCloseButton.clipsToBounds = true
            restaurantOpenOrCloseButton.setTitle("LOADING...", for: .normal)
            updateOpenCloseButton()
            
            restaurantPhotosTitle.textColor = contrastColor.withAlphaComponent(0.7)
            loadPhotos()
            
            self.tableView.backgroundColor = UIColor.clear
            self.tableView.separatorColor = UIColor.clear
            self.tableView.tableFooterView = UIView()
 
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Functions
    
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
        
        if distance.value < 0.5 {
            
            numberFormatter.numberStyle = .decimal
            numberFormatter.maximumFractionDigits = 2
            numberFormatter.minimumFractionDigits = 1
            measurementFormatter.numberFormatter = numberFormatter
            finalString = measurementFormatter.string(from: distance)
            
        } else if distance.value < 1 {
            
            numberFormatter.numberStyle = .decimal
            numberFormatter.maximumFractionDigits = 1
            finalString = measurementFormatter.string(from: distance)
            
        } else {
            
            numberFormatter.maximumFractionDigits = 1
            finalString = measurementFormatter.string(from: distance)
            
        }
        
        return finalString + " away"
        
    }
    
    func returnFormatted(_ phoneNumber: String) -> String {
        
        do {
            
            let parsedPhoneNumber = try phoneNumberKit.parse(phoneNumber)
            let formattedNumber = phoneNumberKit.format(parsedPhoneNumber, toType: .international)
            return formattedNumber
            
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
    
    func doTimings() {
        
        guard let restaurant = restaurant else { return }
        
        var i = 0 // checks if multiple timings for a single day (The Maharaja is an example)
        
        showBusinessDetails(restaurant.id) { (arr, _, _) in
            
            if !(arr.isEmpty) {
                
                self.restaurantOpenOrCloseButton.setTitle(self.isRestaurantOpen ? "OPEN NOW" : "CLOSED NOW", for: .normal)
                self.restaurantOpenOrCloseButton.addTarget(self, action: #selector(self.callTimingsDelegate), for: .touchUpInside)
                self.updateOpenCloseButton()
                
                let daysCount = arr.count
                
                if daysCount > 7 {
                    
                    // Multiple Timings Per Day
                    
                    var sameDays = 0
                    
                    self.numberOfDays(completionHandler: { (number) in
                        sameDays = number
                    })
                    
                    let today = self.getCurrentDay()
                    
                    self.restaurantTimings.text = ""
                    
                    for day in arr {
                        
                        if day.day == today {
                            
                            if i == sameDays {
                                self.restaurantTimings.text = self.restaurantTimings.text! + "\(day.startTime) to " + "\(day.endTime) \n"
                            } else {
                                self.restaurantTimings.text = self.restaurantTimings.text! + "\(day.startTime) to " + "\(day.endTime)"
                            }
                            
                            i += 1
                        }
                        
                    }
                    
                    
                } else {
                    
                    // a full week (or less)
                    
                    for operationDay in arr {
                        
                        if operationDay.day == self.getCurrentDay() {
                            
                            self.restaurantTimings.text = "\(operationDay.startTime) to " + "\(operationDay.endTime)"
                            break // break when restaurant timing is found
                            
                        } else if operationDay.day != self.getCurrentDay() {
                            
                            // if day is not found, therefore it is closed
                            
                            self.restaurantTimings.text = "Closed Today"
                            
                        } else {
                            
                            self.restaurantTimings.text = "Timings Unknown"
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
    }
    
    func numberOfDays(completionHandler: @escaping (Int) -> ()) {
        
        guard let restaurant = restaurant else { return }
        
        var i = 0
        
        showBusinessDetails(restaurant.id) { (arr, _, _) in
            
            for operationDay in arr {
                
                if operationDay.day == self.getCurrentDay() { i += 1 }
                
            }
            
            completionHandler(i)
            
        }
    }
    
    func setOtherCategories() {
        
        guard let restaurant = restaurant else { return }
        
        showBusinessDetails(restaurant.id) { (_, arr, _) in
            
            let filteredArr = arr.filter( { $0 != restaurant.category } )
            // only return categories that don't match the already given category
            
            var arrString = String()
            
            if filteredArr.count == 1 {
                arrString = filteredArr.joined(separator: "")
            } else if filteredArr.count > 1 {
                arrString = filteredArr.joined(separator: " / ")
            }
            
            if !filteredArr.isEmpty {
                // run only if filtered categories is not empty
                self.restaurantCategory.text = self.restaurantCategory.text! + " / \(arrString)"
            }
            
        }
        
    }
    
    func loadPhotos() {

        guard let restaurant = restaurant else { return }
        
        showBusinessDetails(restaurant.id) { (_, _, photosEmbedded) in
            
            self.photos = photosEmbedded
            
            DispatchQueue.main.async {
                self.photosCollectionView.reloadData()
            }
            
        }
        
    }
    
    func loadImage(url: URL) -> UIImage {
        
        var finalImage = UIImage()
        
        Alamofire.request(url).responseData { (response) in
            
            guard let result = response.result.value else { return }
            guard let image = UIImage(data: result) else { return }
            finalImage = image
            
        }
        
        return finalImage
        
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
            break
            
        }
        
        return weekDay
        
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
    
    func updateOpenCloseButton() {
        
        restaurantOpenOrCloseButton.sizeToFit()
        restaurantOpenOrCloseButtonConstraint.constant = restaurantOpenOrCloseButton.bounds.size.width + 10
        
    }
    
    func callTimingsDelegate() {
        
        guard let del = timingDelegate else { return }
        del.openTimingsView()
        
    }
    
    // MARK: - API Functions
    
    func showBusinessDetails(_ id: String, completionHandler: @escaping ([RestaurantHours], [String], [URL]) -> ()) {
        
        let headers = ["Authorization": "Bearer Y43yqZUkj6vah5sgOHU-1PFN2qpapJsSwXZYScYTo0-nK9w5Y3lDvrdRJeG1IpQAADep0GrRL5ZDv6ybln03nIVzP7BL_IzAf_s7Wj5_QLPOO6oXns-nJe3-kIPiWHYx"]
        
        Alamofire.request("https://api.yelp.com/v3/businesses/\(id)", headers: headers).responseJSON { (Response) in
            
            if let value = Response.result.value {
                
                let json = JSON(value)
                                
                // Restaurant Hours Of Operation
                
                var restaurantHoursEmbedded = [RestaurantHours]()
                
                for day in json["hours"].arrayValue {
                    
                    let isOpenNow = day["is_open_now"].boolValue
                    self.isRestaurantOpen = isOpenNow
                    
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
                            break
                            
                        }
                        
                        let dayToUse = RestaurantHours(day: weekDay, isOvernight: isOvernight, startTime: openTime, endTime: endTime)
                        restaurantHoursEmbedded.append(dayToUse)
                        
                    }
                    
                }
                
                // More Categories
                
                var categoriesEmbedded = [String]()
                
                for category in json["categories"].arrayValue {
                    
                    let cat = category["title"].stringValue
                    categoriesEmbedded.append(cat)
                    
                }
                
                // More Photos
                
                var photosEmbedded = [URL]()
                
                for string in json["photos"].arrayValue {
                    
                    let urlString = string.url
                    guard let url = urlString else { return }
                    
                    photosEmbedded.append(url)
                    
                }
                
                completionHandler(restaurantHoursEmbedded, categoriesEmbedded, photosEmbedded)
            }
            
        }
        
    }
    
    // MARK: - Table View Delegate
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 8
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    // MARK: - Collection View Delegate
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCell
        guard let imageView = cell.imageView else { return }
        
        if !(imageView.image == #imageLiteral(resourceName: "placeholderImage")) {
            // if button image isn't placeholder image
            
            let configuration = ImageViewerConfiguration(configurationClosure: { (config) in
                
                config.imageView = imageView
                
            })
            
            let controller = ImageViewerController(configuration: configuration)
            
            present(controller, animated: true, completion: nil)
            
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PhotoCell
        
        let photoURL = photos[indexPath.row]
        
        cell.imageView.downloadedFrom(url: photoURL)
        cell.imageView.contentMode = .scaleAspectFill
        
        cell.layer.cornerRadius = 8
        cell.clipsToBounds = true
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: collectionView.bounds.size.height, height: collectionView.bounds.size.height)
        
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
