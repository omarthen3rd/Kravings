//
//  RestaurantDetailController.swift
//  Kraving
//
//  Created by Omar Abbasi on 2018-02-02.
//  Copyright © 2018 Omar Abbasi. All rights reserved.
//

import UIKit
import Alamofire
import Cosmos
import SwiftyJSON
import ChameleonFramework
import PhoneNumberKit
import SimpleImageViewer
import DeviceKit
import PullToDismiss

protocol RemoveFromArray {
    
    func removeFromArrayWith(_ restaurant: Restaurant)
    
}

protocol UpdateStatusBar {
    
    func updateStatusBar()
    
}

extension CIImage {
    
    var image: UIImage? {
        let image = UIImage(ciImage: self)
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        image.draw(in: CGRect(origin: .zero, size: image.size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
}

extension UIImage {
    
    func applying(saturation value: NSNumber) -> UIImage? {
        return CIImage(image: self)?
            .applyingFilter("CIColorControls", withInputParameters: [kCIInputSaturationKey: value])
            .image
    }
    
    var grayscale: UIImage? {
        return applying(saturation: 0)
    }
    
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

class RestaurantDetailController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var restaurantPhoto: UIImageView!
    @IBOutlet var restaurantPhotoBlur: VisualEffectView!
    
    @IBOutlet var scrollView: UIScrollView!
    
    // Header View Outlets
    @IBOutlet var restaurantHeaderViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var restaurantHeaderView: UIView!
    @IBOutlet var restaurantName: UILabel!
    @IBOutlet var restaurantCategory: UILabel!
    @IBOutlet var restaurantRating: CosmosView!
    @IBOutlet var restaurantPriceDistance: UILabel!
    @IBOutlet var restaurantAddressTitle: UILabel!
    @IBOutlet var restaurantAddress: UILabel!
    @IBOutlet var restaurantPhoneTitle: UILabel!
    @IBOutlet var restaurantPhone: UILabel!
    @IBOutlet var restaurantTimingsTitle: UILabel!
    @IBOutlet var restaurantTimingsLabel: UILabel!
    @IBOutlet var restaurantPhotosTitle: UILabel!
    @IBOutlet var photosCollectionView: UICollectionView!
    
    // Timings Button Outlets
    @IBOutlet var restaurantTimingsView: UIView!
    @IBOutlet var restaurantTimingsButton: UIButton!
    
    // Review Button Outlets
    @IBOutlet var restaurantReviewsView: UIView!
    @IBOutlet var restaurantReviewsButton: UIButton!
    
    // App Button Outlets
    @IBOutlet var restaurantAppButtonsView: UIView!
    @IBOutlet var restaurantPhoneButton: UIButton!
    @IBOutlet var restaurantMapsButton: UIButton!
    @IBOutlet var restaurantWebsiteButton: UIButton!
    
    // App Button Outlets
    @IBOutlet var restaurantOptionsView: UIView!
    @IBOutlet var restaurantOptionsButton: UIButton!
    
    @IBOutlet var containerBackgroundBlur: VisualEffectView!
    
    @IBOutlet var reviewsTitleLabel: UILabel!
    @IBOutlet var reviewsDoneButton: UIButton!
    @IBOutlet var reviewsStarView: CosmosView!
    @IBOutlet var reviewsMakeReview: UIButton!
    @IBOutlet var reviewsContainerView: UIView!
    @IBOutlet var reviewsTableView: UITableView!
    @IBOutlet var reviewsTextView: UITextView!
    
    @IBOutlet var timingsTitleLabel: UILabel!
    @IBOutlet var timingsOpenOrClose: UILabel!
    @IBOutlet var timingsOpenOrCloseView: UIView!
    @IBOutlet var timingsOpenOrCloseViewConstraint: NSLayoutConstraint!
    @IBOutlet var timingsDoneButton: UIButton!
    @IBOutlet var timingsContainerView: UIView!
    @IBOutlet var timingsTableView: UITableView!
    @IBOutlet var timingsRedoButton: UIButton!
    
    @IBOutlet var alertView: VisualEffectView!
    @IBOutlet var alertViewLabel: UILabel!
    @IBOutlet var alertViewImage: UIImageView!
    
    let defaults = UserDefaults.standard
    var restaurant: Restaurant?
    var phoneNumberKit = PhoneNumberKit()
    var photos = [URL]()
    var isRestaurantOpen = Bool()
    var shouldHideStatus: Bool = false
    
    typealias TimeOfDay = (hour: Int, minute: Int)
    
    var timingsDict = [String: String]()
    var currentReviews = [RestaurantReviews]()
    var currentTimings = [RestaurantHours]()
    var restaurantTimings = [(key: Int, value: [String: String])]()
    
    var cornerRadius = Float()
    
    var restaurantSource: RestaurantSource = .likes
    var removeDelegate: RemoveFromArray?
    var statusBarDelegate: UpdateStatusBar?
    
    var avgColor = UIColor()
    var contrastColor = UIColor()
    
    private var pullToDismiss: PullToDismiss?
    
    override var prefersStatusBarHidden: Bool {
        return shouldHideStatus
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // shouldHideStatus == false -> means that navigation bar will be used
        self.setNeedsStatusBarAppearanceUpdate()
        
        if #available(iOS 11.0, *) {
            // for favourites segue with navigation bar
            self.navigationItem.largeTitleDisplayMode = .never
        }
        
        setupView()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Functions
    
    func setupView() {
        
        // universal corner radius for elements (set in DefaultViewController)
        cornerRadius = defaults.float(forKey: "cornerRadius")
        
        guard let restaurant = restaurant else { return }
        
        avgColor = UIColor(averageColorFrom: restaurant.image!)
        contrastColor = UIColor(contrastingBlackOrWhiteColorOn: avgColor, isFlat: true)
        
        // Immediate visible UI setup
        restaurantPhotoBlur.colorTint = contrastColor
        restaurantPhotoBlur.colorTintAlpha = 0.2
        restaurantPhotoBlur.blurRadius = 23
        restaurantPhotoBlur.scale = 1
        
        // photo saturation
        let filteredImage = restaurant.image?.applying(saturation: 0.3)
        restaurantPhoto.image = filteredImage
        restaurantPhoto.clipsToBounds = true
        restaurantPhoto.contentMode = .scaleAspectFill
        
        restaurantHeaderView.backgroundColor = avgColor.withAlphaComponent(0.7)
        
        restaurantName.text = restaurant.name
        restaurantName.textColor = contrastColor
        
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
        doTimings() // sets/sorts timings for todays day
        restaurantTimingsTitle.textColor = contrastColor.withAlphaComponent(0.7)
        restaurantTimingsLabel.textColor = contrastColor
        restaurantTimingsLabel.text = "Loading..."
        
        restaurantPhotosTitle.textColor = contrastColor.withAlphaComponent(0.7)
        photosCollectionView.delegate = self
        photosCollectionView.dataSource = self
        loadPhotos()
        
        // set colors/tints for buttons
        
        // Timings Button Blur and Image
        restaurantTimingsView.backgroundColor = avgColor.withAlphaComponent(0.7)
        
        let timingsImage = #imageLiteral(resourceName: "btn_timings").withRenderingMode(.alwaysTemplate)
        restaurantTimingsButton.setImage(timingsImage, for: .normal)
        restaurantTimingsButton.imageView?.tintColor = contrastColor
        restaurantTimingsButton.tintColor = contrastColor
        restaurantTimingsButton.imageView?.contentMode = .scaleAspectFit
        
        // Reviews Button Blur and Image
        restaurantReviewsView.backgroundColor = avgColor.withAlphaComponent(0.7)
        
        let reviewsImage = #imageLiteral(resourceName: "btn_reviews_selected").withRenderingMode(.alwaysTemplate)
        restaurantReviewsButton.setImage(reviewsImage, for: .normal)
        restaurantReviewsButton.imageView?.tintColor = contrastColor
        restaurantReviewsButton.tintColor = contrastColor
        restaurantReviewsButton.imageView?.contentMode = .scaleAspectFit
        
        // App Buttons Blur and Images
        restaurantAppButtonsView.backgroundColor = avgColor.withAlphaComponent(0.7)
        
        let phoneImage = #imageLiteral(resourceName: "btn_call_selected").withRenderingMode(.alwaysTemplate)
        restaurantPhoneButton.setImage(phoneImage, for: .normal)
        restaurantPhoneButton.imageView?.tintColor = contrastColor
        restaurantPhoneButton.tintColor = contrastColor
        restaurantPhoneButton.imageView?.contentMode = .scaleAspectFit
        
        let mapsImage = #imageLiteral(resourceName: "btn_directions_selected").withRenderingMode(.alwaysTemplate)
        restaurantMapsButton.setImage(mapsImage, for: .normal)
        restaurantMapsButton.imageView?.tintColor = contrastColor
        restaurantMapsButton.tintColor = contrastColor
        restaurantMapsButton.imageView?.contentMode = .scaleAspectFit
        
        let websiteImage = #imageLiteral(resourceName: "btn_openWebsite_selected").withRenderingMode(.alwaysTemplate)
        restaurantWebsiteButton.setImage(websiteImage, for: .normal)
        restaurantWebsiteButton.imageView?.tintColor = contrastColor
        restaurantWebsiteButton.tintColor = contrastColor
        restaurantWebsiteButton.imageView?.contentMode = .scaleAspectFit
        
        restaurantOptionsView.backgroundColor = avgColor.withAlphaComponent(0.7)
        
        reviewsMakeReview.setImage(#imageLiteral(resourceName: "btn_closeView"), for: [])
        reviewsMakeReview.imageView?.tintColor = contrastColor
        reviewsMakeReview.tintColor = contrastColor
        reviewsMakeReview.imageView?.contentMode = .scaleAspectFit
        
        // targets
        // restaurantTimingsButton target is added in doTimings() function
        restaurantReviewsButton.addTarget(self, action: #selector(openReviewView), for: .touchUpInside)
        timingsDoneButton.addTarget(self, action: #selector(self.openTimingsView), for: .touchUpInside)
        reviewsDoneButton.addTarget(self, action: #selector(self.openReviewView), for: .touchUpInside)
        restaurantReviewsButton.addTarget(self, action: #selector(self.openReviewView), for: .touchUpInside)
        restaurantMapsButton.addTarget(self, action: #selector(self.openMaps), for: .touchUpInside)
        restaurantPhoneButton.addTarget(self, action: #selector(self.callBusiness), for: .touchUpInside)
        restaurantWebsiteButton.addTarget(self, action: #selector(self.openWebsite), for: .touchUpInside)
        timingsRedoButton.addTarget(self, action: #selector(redoTimings), for: .touchUpInside)
        reviewsMakeReview.addTarget(self, action: #selector(openSubmitReviewView), for: .touchUpInside)
        restaurantOptionsButton.addTarget(self, action: #selector(openRestaurantActionSheet), for: .touchUpInside)
        
        // Other UI setup (timings/reviews)
        
        // timings
        self.timingsTableView.estimatedRowHeight = 400
        self.timingsTableView.rowHeight = UITableViewAutomaticDimension
        self.timingsTableView.setNeedsLayout()
        self.timingsTableView.layoutIfNeeded()
        self.timingsTableView.reloadData()
        self.timingsTableView.delegate = self
        self.timingsTableView.dataSource = self
        self.timingsTableView.backgroundColor = contrastColor
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
        self.reviewsTableView.backgroundColor = contrastColor
        reviewsContainerView.isHidden = false // will now use blur effect == nil to open/close view
        reviewsContainerView.alpha = 0
        
        // use .alpha instead of .effect to reduce CPU usage and lag
        // plus the VisualEffectView framework doesn't allow for
        // animating the .effect component
        containerBackgroundBlur.colorTint = avgColor
        containerBackgroundBlur.colorTintAlpha = 0.3
        containerBackgroundBlur.blurRadius = 25
        containerBackgroundBlur.scale = 1
        containerBackgroundBlur.alpha = 0
        
        getReviews()
        getTimings() // gets general timings for tableview
        
        // timings view coloring
        timingsDoneButton.backgroundColor = contrastColor
        timingsDoneButton.setTitleColor(avgColor, for: .normal)
        timingsTitleLabel.textColor = contrastColor
        timingsOpenOrCloseView.backgroundColor = contrastColor
        timingsOpenOrClose.textColor = avgColor.withAlphaComponent(0.8)
        
        timingsOpenOrClose.text = "LOADING..."
        updateOpenCloseLabel()
        
        let refreshImage = #imageLiteral(resourceName: "btn_refresh").withRenderingMode(.alwaysTemplate)
        timingsRedoButton.setImage(refreshImage, for: .normal)
        timingsRedoButton.tintColor = contrastColor
        timingsRedoButton.imageView?.tintColor = contrastColor
        timingsRedoButton.imageView?.contentMode = .scaleAspectFit
        
        // reviews view coloring
        reviewsDoneButton.backgroundColor = contrastColor
        reviewsDoneButton.setTitleColor(avgColor, for: .normal)
        reviewsTitleLabel.textColor = contrastColor
        reviewsStarView.settings.textColor = contrastColor
        reviewsStarView.settings.filledBorderColor = UIColor.clear
        reviewsStarView.settings.emptyBorderColor = UIColor.clear
        reviewsStarView.settings.filledColor = contrastColor
        reviewsStarView.settings.emptyColor = contrastColor.withAlphaComponent(0.3)
        
        // alertView coloring
        alertView.blurRadius = 10
        alertView.colorTint = contrastColor
        alertView.colorTintAlpha = 0.6
        alertViewImage.tintColor = avgColor
        alertViewLabel.textColor = avgColor
        
        // show/hide button in navigation bar
        if shouldHideStatus == false {
            // navigation bar is active
            // TODO: 
            
            let barButton = UIBarButtonItem(barButtonSystemItem: .organize, target: self, action: #selector(self.openRestaurantActionSheet))
            self.navigationItem.rightBarButtonItem = barButton
            
        } else {
            
            pullToDismiss = PullToDismiss(scrollView: scrollView, viewController: self)
            pullToDismiss?.delegate = self
            pullToDismiss?.dismissableHeightPercentage = 0.45
            pullToDismiss?.dismissAction = {
                
                self.dismissViewThing()
                
            }
            
        }
        
        setCornerRadius()
        
    }
    
    func setCornerRadius() {
        
        let radius = CGFloat(cornerRadius)
        
        restaurantHeaderView.clipsToBounds = true
        restaurantHeaderView.layer.cornerRadius = radius
        
        restaurantReviewsView.clipsToBounds = true
        restaurantReviewsView.layer.cornerRadius = radius
        
        restaurantTimingsView.clipsToBounds = true
        restaurantTimingsView.layer.cornerRadius = radius
        
        restaurantAppButtonsView.clipsToBounds = true
        restaurantAppButtonsView.layer.cornerRadius = radius
        
        restaurantOptionsView.clipsToBounds = true
        restaurantOptionsView.layer.cornerRadius = radius
        
        timingsTableView.clipsToBounds = true
        timingsTableView.layer.cornerRadius = radius
        
        reviewsTableView.clipsToBounds = true
        reviewsTableView.layer.cornerRadius = radius
        
        reviewsTextView.clipsToBounds = true
        reviewsTextView.layer.cornerRadius = radius
        
        timingsDoneButton.clipsToBounds = true
        timingsDoneButton.layer.cornerRadius = radius
        
        reviewsDoneButton.clipsToBounds = true
        reviewsDoneButton.layer.cornerRadius = radius
        
        alertView.clipsToBounds = true
        alertView.layer.cornerRadius = radius
        
        timingsOpenOrCloseView.clipsToBounds = true
        timingsOpenOrCloseView.layer.cornerRadius = 5
        
    }
    
    func dismissViewThing() {
        
        if shouldHideStatus == false {
            // nav bar is used
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
            if let del = statusBarDelegate {
                del.updateStatusBar()
            }
        }
        
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
                
                let daysCount = arr.count
                
                if daysCount > 7 {
                    
                    // multiple Timings Per Day
                    
                    var sameDays = 0
                    
                    self.numberOfDays(completionHandler: { (number) in
                        sameDays = number
                    })
                    
                    let today = self.getCurrentDay()
                    
                    self.restaurantTimingsLabel.text = ""
                    
                    for day in arr {
                        
                        if day.day == today {
                            
                            var attrString = NSMutableAttributedString()
                            var stringy = String()
                            
                            if i == sameDays {
                                
                                // self.restaurantTimingsLabel.text = self.restaurantTimingsLabel.text! + "\(day.startTime) to " + "\(day.endTime) \n"
                                stringy += "\(day.startTime) to " + "\(day.endTime) \n"
                            } else {
                                
                                let openOrCloseText = self.isRestaurantOpen ? "OPEN NOW" : "CLOSED NOW"
                                
                                stringy += "\(day.startTime) to " + "\(day.endTime) ⋅ \(openOrCloseText)"
                                
                                attrString = NSMutableAttributedString(string: stringy)
                                attrString.setBoldForText(openOrCloseText)
                                
                                self.restaurantTimingsLabel.attributedText = attrString
                                
                            }
                            
                            i += 1
                        }
                        
                    }
                    
                    
                } else {
                    
                    // a full week (or less)
                    
                    for operationDay in arr {
                        
                        if operationDay.day == self.getCurrentDay() {
                            
                            let openOrCloseText = self.isRestaurantOpen ? "OPEN NOW" : "CLOSED NOW"
                            
                            let stringy = "\(operationDay.startTime) to " + "\(operationDay.endTime) ⋅ \(openOrCloseText)"
                            
                            let attrString = NSMutableAttributedString(string: stringy)
                            attrString.setBoldForText(openOrCloseText)
                            self.restaurantTimingsLabel.attributedText = attrString
                            
                            break // break when restaurant timing is found
                            
                        } else if operationDay.day != self.getCurrentDay() {
                            
                            // if day is not found, therefore it is closed
                            
                            self.restaurantTimingsLabel.text = "Closed Today"
                            
                        } else {
                            
                            self.restaurantTimingsLabel.text = "Timings Unknown"
                            
                        }
                        
                    }
                    
                }
                
                self.restaurantTimingsButton.addTarget(self, action: #selector(self.openTimingsView), for: .touchUpInside)
                
            }
            
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
    
    // MARK: - Button Functions
    
    func openTimingsView() {
        
        let openView = UIViewPropertyAnimator(duration: 0.3, curve: .linear) {
            
            self.timingsContainerView.alpha = 1
            self.timingsContainerView.isUserInteractionEnabled = true
            self.containerBackgroundBlur.alpha = 1
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
            self.containerBackgroundBlur.alpha = 0
            self.containerBackgroundBlur.isUserInteractionEnabled = false
            if self.shouldHideStatus == false {
                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                self.navigationController?.navigationBar.alpha = 1
            }
            
        }
        
        let popOpenReview = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 0.6) {
            
            self.timingsContainerView.transform = CGAffineTransform.identity
            
        }
        
        if containerBackgroundBlur.alpha == 0 {
            
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
        
        let openView = UIViewPropertyAnimator(duration: 0.3, curve: .linear) {
            
            self.reviewsContainerView.alpha = 1
            self.reviewsContainerView.isUserInteractionEnabled = true
            self.containerBackgroundBlur.alpha = 1
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
            self.containerBackgroundBlur.alpha = 0
            self.containerBackgroundBlur.isUserInteractionEnabled = false
            if self.shouldHideStatus == false {
                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                self.navigationController?.navigationBar.alpha = 1
            }
            
        }
        
        let popOpenReview = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 0.6) {
            
            self.reviewsContainerView.transform = CGAffineTransform.identity
            
        }
        
        if containerBackgroundBlur.alpha == 0 {
            
            // open view here
            self.reviewsContainerView.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
            popOpenReview.startAnimation()
            openView.startAnimation()
            
        } else {
            
            // close view here
            closeView.startAnimation()
            
        }
        
    }
    
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
    
    func openSubmitReviewView() {
        
        reviewsTextView.isHidden = reviewsTableView.isHidden // open text view
        reviewsTableView.isHidden = !reviewsTextView.isHidden // hide table view
        
        
        makeReviewView()
        
    }
    
    func makeReviewView() {
        
        // add inputAccessoryView (view attatched to keyboard)
        
        let accessoryView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 52))
        accessoryView.backgroundColor = contrastColor
        accessoryView.translatesAutoresizingMaskIntoConstraints = false
        
        self.reviewsTextView.inputAccessoryView = accessoryView
        
        let submitButton = UIButton(type: .custom)
        submitButton.setTitle("Submit", for: [])
        submitButton.setTitleColor(contrastColor, for: [])
        submitButton.backgroundColor = avgColor
        submitButton.layer.cornerRadius = 10
        submitButton.clipsToBounds = true
        submitButton.heightAnchor.constraint(equalToConstant: 52)
        
        let cancelButton = UIButton(type: .custom)
        cancelButton.setTitle("Cancel", for: [])
        cancelButton.setTitleColor(contrastColor, for: [])
        cancelButton.backgroundColor = avgColor
        cancelButton.layer.cornerRadius = 10
        cancelButton.clipsToBounds = true
        cancelButton.heightAnchor.constraint(equalToConstant: 52)
        
        let stackView = UIStackView(arrangedSubviews: [cancelButton, submitButton])
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.spacing = 8
        stackView.distribution = .equalSpacing
        
        accessoryView.addSubview(stackView)
        
        stackView.leadingAnchor.constraint(equalTo: accessoryView.leadingAnchor, constant: 8)
        stackView.trailingAnchor.constraint(equalTo: accessoryView.trailingAnchor, constant: 8)
        stackView.topAnchor.constraint(equalTo: accessoryView.topAnchor, constant: 8)
        stackView.bottomAnchor.constraint(equalTo: accessoryView.bottomAnchor, constant: 8)
        
    }
    
    // MARK: - Restaurant Functions
    
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
    
    func callRemoveDelegate() {
        
        // for removing from sessions likes in Favourites controller
        
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
                
                // find which index "day" belongs in
                guard let indexyMcIndexFace = fullWeek.index(of: day) else { return }
                
                newTimings.insert((key: indexyMcIndexFace, value: [day : "CLOSED"]), at: indexyMcIndexFace)
                
            }
            
            self.restaurantTimings = newTimings
            
            self.timingsTableView.isUserInteractionEnabled = true
            
            
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
                
                self.timingsTableView.isUserInteractionEnabled = true
                
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
                
                self.timingsTableView.isUserInteractionEnabled = true
                
            }
            
        }
        
    }
    
    func redoTimings() {
        
        self.timingsTableView.isUserInteractionEnabled = false
        
        self.currentTimings.removeAll()
        self.restaurantTimings.removeAll()
        
        DispatchQueue.main.async {
            self.getTimings()
        }
        
    }
    
    // MARK: - Alert Functions
    
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
        // self.reviewsStarView.text = "\(restaurant.reviewCount) VOTES"
        self.reviewsStarView.settings.emptyBorderWidth = 0
        self.reviewsStarView.settings.updateOnTouch = false
        self.reviewsStarView.settings.starSize = 21
        self.reviewsStarView.contentMode = .right
        
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
            
            cell.userImage.layer.cornerRadius = 7
            cell.userImage.clipsToBounds = true
            
            cell.name.text = currentReview.name
            cell.rating.text = "\(currentReview.rating)"
            cell.textReview.text = currentReview.reviewText
            cell.timeOfReview.text = currentReview.reviewTime
            
            cell.name.textColor = avgColor.darken(byPercentage: 0.25)
            cell.textReview.textColor = avgColor.darken(byPercentage: 0.25)
            cell.timeOfReview.textColor = avgColor.darken(byPercentage: 0.25)
            
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
                cell.day.font = UIFont.systemFont(ofSize: 19, weight: UIFontWeightBold)
                cell.hours.font = UIFont.systemFont(ofSize: 19, weight: UIFontWeightBold)
                
            }
            
            cell.day.textColor = avgColor.darken(byPercentage: 0.25)
            cell.hours.textColor = avgColor.darken(byPercentage: 0.25)
            
            return cell
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableViewAutomaticDimension
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
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
        
        cell.layer.cornerRadius = 10
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
