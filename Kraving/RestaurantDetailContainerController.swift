//
//  RestaurantDetailContainerController.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-12-05.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit
import Cosmos
import Alamofire
import SwiftyJSON
import DeviceKit

protocol RemoveFromArray {
    
    func removeFromArrayWith(_ restaurant: Restaurant)
    
}

extension UIImageView {
    
    func downloadedFrom(url: URL, contentMode mode: UIViewContentMode = .scaleAspectFill) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() {
                self.image = image
            }
            }.resume()
    }
    
    func downloadedFrom(link: String, contentMode mode: UIViewContentMode = .scaleAspectFill) {
        guard let url = URL(string: link) else { return }
        downloadedFrom(url: url, contentMode: mode)
    }
    
}

class RestaurantDetailContainerController: UIViewController, UITableViewDataSource, UITableViewDelegate, TimingsView {
    
    @IBOutlet var backgroundView: UIView!
    
    @IBOutlet var containerView: UIView!
    @IBOutlet var closeBtnView: UIView!
    @IBOutlet var closeBtn: UIButton!
    
    @IBOutlet var containerBackgroundBlur: UIVisualEffectView!
    
    @IBOutlet var reviewsHeaderView: VisualEffectView!
    @IBOutlet var reviewsTitleLabel: UILabel!
    @IBOutlet var reviewsDoneButton: UIButton!
    @IBOutlet var reviewsStarView: CosmosView!
    @IBOutlet var reviewsContainerView: UIView!
    @IBOutlet var reviewsTableView: UITableView!
    
    @IBOutlet var timingsHeaderView: VisualEffectView!
    @IBOutlet var timingsTitleLabel: UILabel!
    @IBOutlet var timingsOpenOrClose: UILabel!
    @IBOutlet var timingsOpenOrCloseView: UIView!
    @IBOutlet var timingsOpenOrCloseViewConstraint: NSLayoutConstraint!
    @IBOutlet var timingsDoneButton: UIButton!
    @IBOutlet var timingsContainerView: UIView!
    @IBOutlet var timingsTableView: UITableView!
    
    @IBOutlet var restaurantPhoneButton: UIButton!
    @IBOutlet var restaurantMapsButton: UIButton!
    @IBOutlet var restaurantWebsiteButton: UIButton!
    @IBOutlet var restaurantReviewsButton: UIButton!
    
    @IBOutlet var alertView: VisualEffectView!
    @IBOutlet var alertViewLabel: UILabel!
    @IBOutlet var alertViewImage: UIImageView!
    
    let defaults = UserDefaults.standard
    
    var avgColor = UIColor()
    
    var timingsDict = [String: String]()
    var currentReviews = [RestaurantReviews]()
    var currentTimings = [RestaurantHours]()
    var restaurantTimings = [(key: Int, value: [String: String])]()
    
    let device = Device()
    var olderDevices = [Device]()
    
    var shouldHideStatus: Bool = false
    var restaurantSource: RestaurantSource = .likes
    
    var removeDelegate: RemoveFromArray?
    var restaurant: Restaurant? {
        
        didSet {
            
            setupView()
            
        }
        
    }
    
    override var prefersStatusBarHidden: Bool {
        return shouldHideStatus
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // shouldHideStatus == false -> means that navigation bar will be used
        self.setNeedsStatusBarAppearanceUpdate()
        
        if #available(iOS 11.0, *) {
            // for favourites segue with navigation bar
            self.navigationItem.largeTitleDisplayMode = .never
        }
        
        setupView()
        
    }
    
    // MARK: - Functions
    
    func setupView() {
        
        olderDevices = [.iPhone5, .iPhone5c, .iPhone6, .iPhone6Plus]
        
        guard let restaurant = restaurant else { return }
        guard let container = containerView else { return }
        guard let closeContainer = closeBtnView else { return }
        guard let closeBtn = closeBtn else { return }
        
        // timings
        self.timingsTableView.estimatedRowHeight = 400
        self.timingsTableView.rowHeight = UITableViewAutomaticDimension
        self.timingsTableView.setNeedsLayout()
        self.timingsTableView.layoutIfNeeded()
        self.timingsTableView.reloadData()
        self.timingsTableView.delegate = self
        self.timingsTableView.dataSource = self
        timingsContainerView.isHidden = false // will now use blur effect == nil to open/close view
        timingsContainerView.alpha = 0
        
        // reviews
        self.reviewsTableView.estimatedRowHeight = 400
        self.reviewsTableView.rowHeight = UITableViewAutomaticDimension
        self.reviewsTableView.setNeedsLayout()
        self.reviewsTableView.layoutIfNeeded()
        self.reviewsTableView.reloadData()
        self.reviewsTableView.delegate = self
        self.reviewsTableView.dataSource = self
        if device.isOneOf(olderDevices) {
            // device is older, so use .alpha instead of .effect
            // to reduce CPU usage and lag
            containerBackgroundBlur.effect = UIBlurEffect(style: .extraLight)
            containerBackgroundBlur.alpha = 0
            
        } else {
            // device is newer and using .effect is fine
            containerBackgroundBlur.effect = nil
            
        }
        reviewsContainerView.isHidden = false // will now use blur effect == nil to open/close view
        reviewsContainerView.alpha = 0
        
        getReviews()
        getTimings()
        
        avgColor = UIColor(averageColorFrom: restaurant.image!)
        let contrastColor = UIColor(contrastingBlackOrWhiteColorOn: avgColor, isFlat: true)
        
        container.backgroundColor = contrastColor
        closeContainer.backgroundColor = avgColor.darken(byPercentage: 0.2)
        
        closeBtn.setImage(#imageLiteral(resourceName: "btn_closeView").withRenderingMode(.alwaysTemplate), for: .normal)
        if shouldHideStatus == false {
            // nav bar is used -> rotate button 90 degrees
            closeBtn.imageView?.transform = CGAffineTransform(rotationAngle: (CGFloat.pi / 2))
        }
        closeBtn.tintColor = contrastColor
        // closeBtn.imageEdgeInsets = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)
        closeBtn.imageView?.contentMode = .center
        closeBtn.imageView?.clipsToBounds = true
        closeBtn.addTarget(self, action: #selector(self.dismissViewThing), for: .touchUpInside)
        
        let image1 = #imageLiteral(resourceName: "btn_openWebsite_selected").withRenderingMode(.alwaysTemplate)
        let image1S = #imageLiteral(resourceName: "btn_openWebsite").withRenderingMode(.alwaysTemplate)
        let image2 = #imageLiteral(resourceName: "btn_reviews_selected").withRenderingMode(.alwaysTemplate)
        let image2S = #imageLiteral(resourceName: "btn_reviews").withRenderingMode(.alwaysTemplate)
        let image3 = #imageLiteral(resourceName: "btn_directions_selected").withRenderingMode(.alwaysTemplate)
        let image3S = #imageLiteral(resourceName: "btn_directions").withRenderingMode(.alwaysTemplate)
        let image4 = #imageLiteral(resourceName: "btn_call_selected").withRenderingMode(.alwaysTemplate)
        let image4S = #imageLiteral(resourceName: "btn_call").withRenderingMode(.alwaysTemplate)
        
        restaurantPhoneButton.setImage(image4S, for: .normal)
        restaurantPhoneButton.setImage(image4, for: .highlighted)
        restaurantPhoneButton.imageView?.tintColor = avgColor.darken(byPercentage: 0.2)
        restaurantPhoneButton.imageView?.contentMode = .scaleAspectFit
        
        restaurantWebsiteButton.setImage(image1S, for: .normal)
        restaurantWebsiteButton.setImage(image1, for: .highlighted)
        restaurantWebsiteButton.imageView?.tintColor = avgColor.darken(byPercentage: 0.2)
        restaurantWebsiteButton.imageView?.contentMode = .scaleAspectFit
        
        restaurantReviewsButton.setImage(image2S, for: .normal)
        restaurantReviewsButton.setImage(image2, for: .highlighted)
        restaurantReviewsButton.imageView?.tintColor = avgColor.darken(byPercentage: 0.2)
        restaurantReviewsButton.imageView?.contentMode = .scaleAspectFit
        
        restaurantMapsButton.setImage(image3S, for: .normal)
        restaurantMapsButton.setImage(image3, for: .highlighted)
        restaurantMapsButton.imageView?.tintColor = avgColor.darken(byPercentage: 0.2)
        restaurantMapsButton.imageView?.contentMode = .scaleAspectFit

        timingsDoneButton.addTarget(self, action: #selector(self.openTimingsView), for: .touchUpInside)
        reviewsDoneButton.addTarget(self, action: #selector(self.openReviewView), for: .touchUpInside)
        restaurantReviewsButton.addTarget(self, action: #selector(self.openReviewView), for: .touchUpInside)
        restaurantMapsButton.addTarget(self, action: #selector(self.openMaps), for: .touchUpInside)
        restaurantPhoneButton.addTarget(self, action: #selector(self.callBusiness), for: .touchUpInside)
        restaurantWebsiteButton.addTarget(self, action: #selector(self.openWebsite), for: .touchUpInside)
        
        backgroundView.backgroundColor = avgColor
        
        // timings view coloring
        timingsDoneButton.backgroundColor = avgColor.withAlphaComponent(0.8) // to match blur tint (CONSISTENCY IS KEEEEYYYYY)
        timingsDoneButton.setTitleColor(contrastColor, for: .normal)
        timingsHeaderView.colorTint = avgColor
        timingsHeaderView.colorTintAlpha = 0.8
        timingsHeaderView.blurRadius = 20
        timingsTitleLabel.textColor = contrastColor
        timingsOpenOrCloseView.backgroundColor = contrastColor
        timingsOpenOrCloseView.layer.cornerRadius = 5
        timingsOpenOrCloseView.clipsToBounds = true
        timingsOpenOrClose.textColor = avgColor.withAlphaComponent(0.8)
        
        timingsOpenOrClose.text = "LOADING..."
        updateOpenCloseLabel()
        
        // reviews view coloring
        reviewsDoneButton.backgroundColor = avgColor.withAlphaComponent(0.8) // to match blur tint (CONSISTENCY IS KEEEEYYYYY)
        reviewsDoneButton.setTitleColor(contrastColor, for: .normal)
        reviewsHeaderView.colorTint = avgColor
        reviewsHeaderView.colorTintAlpha = 0.8
        reviewsHeaderView.blurRadius = 20
        reviewsTitleLabel.textColor = contrastColor
        reviewsStarView.settings.textColor = contrastColor
        reviewsStarView.settings.filledBorderColor = UIColor.clear
        reviewsStarView.settings.emptyBorderColor = UIColor.clear
        reviewsStarView.settings.filledColor = contrastColor
        reviewsStarView.settings.emptyColor = contrastColor.withAlphaComponent(0.3)
        
        // alertView coloring
        alertView.blurRadius = 10
        alertView.colorTint = contrastColor
        alertView.colorTintAlpha = 0.65
        alertViewImage.tintColor = avgColor
        alertViewLabel.textColor = avgColor
        
        // long-term favourites
        
        if shouldHideStatus == false {
            let barButton = UIBarButtonItem(barButtonSystemItem: .organize, target: self, action: #selector(self.openRestaurantActionSheet))
            self.navigationItem.rightBarButtonItem = barButton
        }
        
    }
    
    func dismissViewThing() {
        
        if shouldHideStatus == false {
            // nav bar is used
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
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
    
    func updateOpenCloseLabel() {
        
        timingsOpenOrClose.sizeToFit()
        timingsOpenOrCloseViewConstraint.constant = timingsOpenOrClose.bounds.size.width + 10
        timingsOpenOrCloseView.sizeToFit()
        
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
    
    func fixTimings() {
        
        let timings = currentTimings
        let fullWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        
        if timings.count > 7 {
            
            // multiple timings
            var i = 0
            
            var timingsDictTemp = [Int: [String: String]]()
            
            for time in timings {
                
                if !(i == currentTimings.count - 1) {
                    // if not equal to the last last one
                    if timings[i + 1].day == time.day {
                        // if next day is equal to current day -> multiple timings for each day
                        timingsDictTemp[i/2] = [time.day:"\(time.startTime) to \(time.endTime) \n \(timings[(i/2) + 1].startTime) to \(timings[(i/2) + 1].endTime)"]
                        // divided by 2 because multiple timings (double times for each day)
                        timingsDict[time.day] = "\(time.startTime) to \(time.endTime) \n \(timings[i + 1].startTime) to \(timings[i + 1].endTime)"
                    }
                }
                
                i += 1
                
            }
            
            // sort the dictionary by the int (acts as an index to sort)
            var newTimings = timingsDictTemp.sorted(by: { $0.0 < $1.0 })
            
            // get days from new timings in order
            var days = [String]()
            for timi in newTimings {
                for tim in timi.value {
                    days.append(tim.key)
                }
            }
            
            // finalize and add missing days
            let new = fullWeek.filter( {!days.contains($0)} ) // days that are missing
            for day in new {
                
                let indexThing = fullWeek.index(of: day) // find which index day belongs in
                guard let indexyMcIndexFace = indexThing else { return }
                
                newTimings.insert((key: indexyMcIndexFace, value: [day : "CLOSED"]), at: indexyMcIndexFace)
                
            }
            
            self.restaurantTimings = newTimings
            
            
        } else {
            
            // counts as full week
            
            var timingsDictTemp = [Int: [String: String]]()
            
            if timings.count < fullWeek.count {
                // day(s) missing, figure out what day is missing
                let mapped = Set(timings.map( { $0.day } )) // map out only days of timings
                
                var index = 0
                
                for day in fullWeek {
                    
                    if (!(index == mapped.count) && !(index > mapped.count)) {
                        // if not equal to last count
                        if day == timings[index].day {
                            // day is the same
                            let thing = timings[index].day
                            timingsDictTemp[index] = [thing:"\(timings[index].startTime) to \(timings[index].endTime)"]
                        }
                    } else {
                        let thing = fullWeek[index]
                        timingsDictTemp[index] = [thing:"CLOSED"]
                        
                    }
                    
                    index += 1
                    
                }
                
                // sort the dictionary by the int (acts as an index to sort)
                let newTimings = timingsDictTemp.sorted(by: { $0.0 < $1.0 })
                self.restaurantTimings = newTimings
                
            } else {
                // a full week, everything is good
                var index = 0
                
                for _ in fullWeek {
                    
                    let thing = timings[index].day
                    timingsDictTemp[index] = [thing:"\(timings[index].startTime) to \(timings[index].endTime)"]
                    
                    index += 1
                    
                }
                
                let newTimings = timingsDictTemp.sorted(by: { $0.0 < $1.0 })
                self.restaurantTimings = newTimings
                
            }
            
        }
        
    }
    
    // MARK: - API Functions
    
    func getTimings() {
        
        guard let restaurant = restaurant else { return }
        
        let headers: HTTPHeaders = ["Authorization": "Bearer Y43yqZUkj6vah5sgOHU-1PFN2qpapJsSwXZYScYTo0-nK9w5Y3lDvrdRJeG1IpQAADep0GrRL5ZDv6ybln03nIVzP7BL_IzAf_s7Wj5_QLPOO6oXns-nJe3-kIPiWHYx"]
        
        Alamofire.request("https://api.yelp.com/v3/businesses/\(restaurant.id)", headers: headers).responseJSON { (Response) in
            
            if let value = Response.result.value {
                
                let json = JSON(value)
                
                // Restaurant Hours Of Operation
                
                for day in json["hours"].arrayValue {
                    
                    let isOpenNow = day["is_open_now"].boolValue
                    self.timingsOpenOrClose.text = isOpenNow ? "OPEN NOW" : "CLOSED NOW"
                    self.updateOpenCloseLabel()
                    
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
                        self.currentTimings.append(dayToUse)
                
                    }
                    
                    DispatchQueue.main.async {
                        self.timingsTableView.reloadData()
                    }
                    
                }
                
                self.fixTimings()
                
            }
            
        }
        
    }
    
    func getReviews() {
        
        guard let restaurant = restaurant else { return }
        
        let headers: HTTPHeaders = ["Authorization": "Bearer Y43yqZUkj6vah5sgOHU-1PFN2qpapJsSwXZYScYTo0-nK9w5Y3lDvrdRJeG1IpQAADep0GrRL5ZDv6ybln03nIVzP7BL_IzAf_s7Wj5_QLPOO6oXns-nJe3-kIPiWHYx"]
        
        Alamofire.request("https://api.yelp.com/v3/businesses/\(restaurant.id)/reviews", headers: headers).responseJSON { (Response) in
            
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
        
        self.reviewsStarView.rating = Double(restaurant.rating)
        self.reviewsStarView.text = "\(restaurant.reviewCount) VOTES"
        self.reviewsStarView.settings.emptyBorderWidth = 0
        self.reviewsStarView.settings.updateOnTouch = false
        self.reviewsStarView.settings.starSize = 21
        self.reviewsStarView.contentMode = .right
        
    }
    
    // MARK: - Button Functions
    
    func callBusiness() {
        
        guard let restaurant = restaurant else { return }
        guard let url = URL(string: "tel://\(restaurant.phone)") else { return }
        
        UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
            
            if !success {
                
                self.showAlertController("Failed To Call", "There's been a slight complication. The call cannot be made, make sure you are using an iPhone or a compatible device.", nil)
                
            }
            
        })
        
    }
    
    func openWebsite() {
        
        guard let restaurant = restaurant else { return }
        guard let browserName = defaults.object(forKey: "defaultBrowser") as? String else { return }
        
        switch browserName {
        case "Safari":
            
            guard let url = URL(string: restaurant.website) else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                
                if !success {
                    
                    self.showAlertController("Failed To Open Safari", "There's been a slight complication. Make sure you have Safari installed on your iPhone.", nil)
                    
                }
                
            })
            
        case "Google Chrome":
            
            // use everything after the "https" as url because Google Chrome ¯\_(ツ)_/¯
            let rangeOfScheme = (restaurant.website as NSString).range(of: ":")
            let urlNoScheme = (restaurant.website as NSString).substring(from: rangeOfScheme.location)
            let chromeURLString = "googlechromes" + (urlNoScheme)
            let chromeURL = URL(string: chromeURLString)
            
            guard let url = chromeURL else { return }
            
            UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                
                if !success {
                    
                    self.showAlertController("Failed To Open Google Chrome", "There's been a slight complication. Make sure you have Google Chrome installed on your iPhone.", "https://itunes.apple.com/us/app/google-chrome/id535886823?mt=8")
                    
                }
                
            })
            
        default:
            
            guard let url = URL(string: restaurant.website) else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                
                if !success {
                    
                    self.showAlertController("Failed To Open Safari", "There's been a slight complication. Make sure you have Safari installed on your iPhone.", nil)
                    
                }
                
            })

            
        }
        
    }
    
    func openMaps() {
        
        guard let restaurant = restaurant else { return }
        guard let appName = defaults.object(forKey: "defaultMaps") as? String else { return }
        
        let string = "\(restaurant.address),\(restaurant.city),\(restaurant.country)"
        let addressString = string.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        
        switch appName {
            
        case "Apple Maps":
            
            if let url = URL(string: "http://maps.apple.com/?address=\(addressString!)") {
                
                UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                    
                    if !success {
                        
                        self.showAlertController("Failed To Open Maps", "There's been a slight complication. Make sure you have Maps installed on your iPhone.", nil)
                    }
                    
                })
            }
            
        case "Google Maps":
            
            if let url = URL(string: "comgooglemaps://?q=\(addressString!)") {
                
                UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                    
                    if !success {
                        
                        self.showAlertController("Failed To Open Google Maps", "There's been a slight complication. Make sure you have Google Maps installed on your iPhone.", "https://itunes.apple.com/ca/app/google-maps/id585027354?mt=8")
                    }
                    
                })
                
            }
            
        case "Waze":
            
            if let url = URL(string: "waze://?q=\(addressString!)") {
                
                UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                    
                    if !success {
                        
                        self.showAlertController("Failed To Open Waze", "There's been a slight complication. Make sure you have Waze installed on your iPhone.", "https://itunes.apple.com/us/app/waze-social-gps-maps-traffic/id323229106?mt=8")
                        
                    }
                    
                })
                
            }
            
        default:
            
            // default is Apple Maps
            
            if let url = URL(string: "http://maps.apple.com/?address=\(addressString!)") {
                
                UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                    
                    if !success {
                        
                        self.showAlertController("Failed To Open Maps", "There's been a slight complication. Make sure you have Maps installed on your iPhone.", nil)
                    }
                    
                })
            }
            
        }
        
    }
    
    func openTimingsView() {
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.extraLight)
        
        let openView = UIViewPropertyAnimator(duration: 0.3, curve: .linear) {
            
            self.timingsContainerView.alpha = 1
            self.timingsContainerView.isUserInteractionEnabled = true
            if self.device.isOneOf(self.olderDevices) {
                // older device, use alpha
                self.containerBackgroundBlur.alpha = 1
            } else {
                self.containerBackgroundBlur.effect = blurEffect
            }
            self.containerBackgroundBlur.isUserInteractionEnabled = true
            if self.shouldHideStatus == false {
                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
                self.navigationController?.navigationBar.alpha = 0
            }
            
        }
        
        let closeView =  UIViewPropertyAnimator(duration: 0.2, curve: UIViewAnimationCurve.easeOut) {
            
            self.timingsContainerView.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
            self.timingsContainerView.alpha = 0
            self.timingsContainerView.isUserInteractionEnabled = false
            if self.device.isOneOf(self.olderDevices) {
                // older device, use alpha
                self.containerBackgroundBlur.alpha = 0
            } else {
                self.containerBackgroundBlur.effect = nil
            }
            self.containerBackgroundBlur.isUserInteractionEnabled = false
            if self.shouldHideStatus == false {
                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                self.navigationController?.navigationBar.alpha = 1
            }
            
        }
        
        let popOpenReview = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 0.6) {
            
            self.timingsContainerView.transform = CGAffineTransform.identity
            
        }
        
        if containerBackgroundBlur.effect == nil || containerBackgroundBlur.alpha == 0 {
            
            // open view here
            self.timingsContainerView.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
            popOpenReview.startAnimation()
            openView.startAnimation()
            
        } else {
            
            // close view here
            closeView.startAnimation()
            
        }
        
    }
    
    func openReviewView() {
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.extraLight)
        
        let openView = UIViewPropertyAnimator(duration: 0.3, curve: .linear) {
            
            self.reviewsContainerView.alpha = 1
            self.reviewsContainerView.isUserInteractionEnabled = true
            if self.device.isOneOf(self.olderDevices) {
                // older device, use alpha
                self.containerBackgroundBlur.alpha = 1
            } else {
                self.containerBackgroundBlur.effect = blurEffect
            }
            self.containerBackgroundBlur.isUserInteractionEnabled = true
            if self.shouldHideStatus == false {
                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
                self.navigationController?.navigationBar.alpha = 0
            }
            
        }
        
        let closeView =  UIViewPropertyAnimator(duration: 0.2, curve: UIViewAnimationCurve.easeOut) {
            
            self.reviewsContainerView.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
            self.reviewsContainerView.alpha = 0
            self.reviewsContainerView.isUserInteractionEnabled = false
            if self.device.isOneOf(self.olderDevices) {
                // older device, use alpha
                self.containerBackgroundBlur.alpha = 0
            } else {
                self.containerBackgroundBlur.effect = nil
            }
            self.containerBackgroundBlur.isUserInteractionEnabled = false
            if self.shouldHideStatus == false {
                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                self.navigationController?.navigationBar.alpha = 1
            }
            
        }
        
        let popOpenReview = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 0.6) {
            
            self.reviewsContainerView.transform = CGAffineTransform.identity
            
        }
        
        if containerBackgroundBlur.effect == nil || containerBackgroundBlur.alpha == 0 {
            
            // open view here
            self.reviewsContainerView.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
            popOpenReview.startAnimation()
            openView.startAnimation()
            
        } else {
            
            // close view here
            closeView.startAnimation()
            
        }
        
    }
    
    func restaurantInFavourites() -> Bool {
        
        guard let restaurant = restaurant else { return false }
        guard let decodedArr = defaults.object(forKey: "favourites") as? Data else { return false }
        guard let decodedRestaurants = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [Restaurant] else { return false }
        
        if decodedRestaurants.contains(where: { $0.id == restaurant.id }) {
            
            return true
            
        } else {
            
            return false
            
        }
        
    }
    
    func addToLongTermFavourites() {
        
        guard let restaurant = restaurant else { return }
        
        if defaults.object(forKey: "favourites") == nil {
            
            // no favs, create arr, encode and replace
            
            var favouriteRestaurants = [Restaurant]()
            favouriteRestaurants.append(restaurant)
            
            let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: favouriteRestaurants)
            defaults.set(encodedData, forKey: "favourites")
            defaults.synchronize()
            
            callRemoveDelegate() // remove from session favourites/likes array in FavouritesViewController (collection view)
            
        } else {
            
            if let decodedArr = defaults.object(forKey: "favourites") as? Data {
                
                if var decodedRestaurants = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [Restaurant] {
                    
                    if !(decodedRestaurants.contains(where: { $0.id == restaurant.id } )) {
                        
                        // not in favourites -> add to favourites
                        
                        decodedRestaurants.append(restaurant)
                        
                    }
                    
                    let encode: Data = NSKeyedArchiver.archivedData(withRootObject: decodedRestaurants)
                    defaults.set(encode, forKey: "favourites")
                    defaults.synchronize()
                    
                    callRemoveDelegate()
                    
                }
                
            }
            
        }
        
    }
    
    func addToDislikes() {
        
        guard let restaurant = restaurant else { return }
        if defaults.object(forKey: "dislikes") == nil {
            
            // no dislikes, create arr, encode and replace
            
            var dislikeRestaurants = [Restaurant]()
            dislikeRestaurants.append(restaurant)
            
            let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: dislikeRestaurants)
            defaults.set(encodedData, forKey: "dislikes")
            defaults.synchronize()
            
        } else {
            
            guard let decodedArr = defaults.object(forKey: "dislikes") as? Data else { return }
            guard var decodedRestaurants = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [Restaurant] else { return }
            
            if !(decodedRestaurants.contains(where: { $0.id == restaurant.id } )) {
                
                // not in dislikes -> add to dislikes
                
                decodedRestaurants.append(restaurant)
                
            }
            let encode: Data = NSKeyedArchiver.archivedData(withRootObject: decodedRestaurants)
            defaults.set(encode, forKey: "dislikes")
            defaults.synchronize()
            
        }
        
    }
    
    func removeFromDislikes() {
        
        guard let restaurant = restaurant else { return }
        guard let decodedArr = defaults.object(forKey: "dislikes") as? Data else { return }
        guard let decodedRestaurants = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [Restaurant] else { return }
        
        let newRestaurants = decodedRestaurants.filter{ !($0.id == restaurant.id) }
        // return everything that doesn't match the current restaurant ID
        // (i.e the one we want deleted)
        
        let encode: Data = NSKeyedArchiver.archivedData(withRootObject: newRestaurants)
        defaults.set(encode, forKey: "dislikes")
        defaults.synchronize()
        
    }
    
    func removeFromLongTermFavourites() {
        
        guard let restaurant = restaurant else { return }
        guard let decodedArr = defaults.object(forKey: "favourites") as? Data else { return }
        guard let decodedRestaurants = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [Restaurant] else { return }
                
        let newRestaurants = decodedRestaurants.filter{ !($0.id == restaurant.id) }
        // return everything that doesn't match the current restaurant ID
        // (i.e the one we want deleted)
        
        let encode: Data = NSKeyedArchiver.archivedData(withRootObject: newRestaurants)
        defaults.set(encode, forKey: "favourites")
        defaults.synchronize()
        
    }
    
    func showAlertController(_ title: String, _ message: String, _ url: String?) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let okayAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        let alertAction = UIAlertAction(title: "Download App", style: .default, handler: { (action) in
            
            let url = URL(string: url!)
            
            if let urlUnwrapped = url {
                
                UIApplication.shared.open(urlUnwrapped, options: [:], completionHandler: { (success) in
                    
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
    
    func showAlertView(withMessage message: String, _ image: UIImage) {
        
        let closeBlur = UIViewPropertyAnimator(duration: 0.2, curve: .easeOut) {
            
            self.alertView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            self.alertView.alpha = 0
            
        }
        closeBlur.addCompletion { (position) in
            
            self.alertView.isHidden = true
            
        }
        
        let blurAnimator = UIViewPropertyAnimator(duration: 0.2, curve: .easeIn) {
            
            self.alertView.transform = CGAffineTransform.identity
            self.alertView.alpha = 1
            
        }
        blurAnimator.addCompletion { (position) in
            
            // after 2 seconds automatically hide the alert view
            closeBlur.startAnimation(afterDelay: 1.5)
            
        }
        
        self.alertView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        self.alertView.alpha = 0
        self.alertView.isHidden = false
        
        // prep before animation
        
        alertViewImage.image = image.withRenderingMode(.alwaysTemplate)
        alertViewLabel.text = message
        alertView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        blurAnimator.startAnimation()
        
    }
    
    func callRemoveDelegate() {
        
        guard let restaurant = restaurant else { return }
        
        if let del = removeDelegate {
            del.removeFromArrayWith(restaurant)
        }
        
        self.navigationController?.popViewController(animated: true)
        
    }
    
    func openRestaurantActionSheet() {
        
        let alertCtrl = UIAlertController(title: "Restaurant Options", message: "Here are some options for adding/removing the restaurant.", preferredStyle: .actionSheet)
        
        switch restaurantSource {
        case .longTermFavourites:
            let removeFromLongTerm = UIAlertAction(title: "Remove From Long Term Favourites", style: .destructive, handler: { (_) in
                self.showAlertView(withMessage: "Removed From Long Term Favourites", #imageLiteral(resourceName: "notHappyHeart"))
                self.removeFromLongTermFavourites()
                self.navigationController?.popViewController(animated: true)
            })
            let addToDislikes = UIAlertAction(title: "Dislike", style: .destructive, handler: { (_) in
                self.showAlertView(withMessage: "Added To Dislikes", #imageLiteral(resourceName: "notHappyHeart"))
                self.removeFromLongTermFavourites()
                self.addToDislikes()
                self.navigationController?.popViewController(animated: true)
            })
            alertCtrl.addAction(removeFromLongTerm)
            alertCtrl.addAction(addToDislikes)
            
        case .likes:
            let removeFromSession = UIAlertAction(title: "Remove From Session Favourites", style: .destructive, handler: { (_) in
                self.showAlertView(withMessage: "Removed From Session Favourites", #imageLiteral(resourceName: "notHappyHeart"))
                self.callRemoveDelegate() // removes from FavouritesViewController (collection view) and then goes to back to preview view
            })
            let addToLongTerm = UIAlertAction(title: "Add To Long Term Favourites", style: .default, handler: { (_) in
                self.showAlertView(withMessage: "Added To Long Term Favourites", #imageLiteral(resourceName: "happyHeart"))
                self.addToLongTermFavourites()
            })
            let addToDislikes = UIAlertAction(title: "Dislike", style: .destructive, handler: { (_) in
                self.showAlertView(withMessage: "Added To Dislikes", #imageLiteral(resourceName: "notHappyHeart"))
                self.removeFromLongTermFavourites()
                self.addToDislikes()
                self.callRemoveDelegate() 
                self.navigationController?.popViewController(animated: true)
            })
            alertCtrl.addAction(addToLongTerm)
            alertCtrl.addAction(removeFromSession)
            alertCtrl.addAction(addToDislikes)
            
        case .dislikes:
            
            let removeFromDislikes = UIAlertAction(title: "Remove From Dislikes", style: .destructive, handler: { (_) in
                self.showAlertView(withMessage: "Removed From Dislikes", #imageLiteral(resourceName: "happyHeart"))
                self.removeFromDislikes()
                self.navigationController?.popViewController(animated: true)
            })
            alertCtrl.addAction(removeFromDislikes)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertCtrl.addAction(cancelAction)
        
        self.present(alertCtrl, animated: true, completion: nil)
        
    }
    
    // MARK: - Table view
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == reviewsTableView {
            return currentReviews.count
        } else {
            return restaurantTimings.count
            
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == reviewsTableView {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "ReviewsCell", for: indexPath) as! ReviewsCell
            
            let currentReview = currentReviews[indexPath.row]
            let imageURL = URL(string: currentReview.imageURL)
            
            if let urlThing = imageURL {
                cell.userImage.downloadedFrom(url: urlThing)
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
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "TimingsCell", for: indexPath) as! TimingsCell
            
            let timing = restaurantTimings[indexPath.row]
            let today = self.getCurrentDay()
            
            for tim in timing.value {
                cell.day.text = tim.key
                cell.hours.text = tim.value
            }
            
            if cell.day.text == today {
                // bold text if timing is today
                cell.day.font = UIFont.systemFont(ofSize: 19, weight: UIFontWeightSemibold)
                cell.hours.font = UIFont.systemFont(ofSize: 19, weight: UIFontWeightSemibold)
                
            }
            
            return cell
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableViewAutomaticDimension
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableViewAutomaticDimension
        
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "detailChildSegue" {
            
            let childController = segue.destination as! RestaurantDetailTableViewController
            childController.timingDelegate = self
            let restaurantToPass = restaurant
            childController.restaurant = restaurantToPass
            
        }
        
    }

}

