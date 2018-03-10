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
import SimpleImageViewer
import DeviceKit
import PullToDismiss

protocol RemoveFromArray {
    
    func removeFromArrayWith(_ restaurant: GoogleRestaurant)
    
}

protocol UpdateStatusBar {
    
    func updateStatusBar()
    
}

enum ParentController {
    
    case defaultController, favouritesController
    
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
    var googleRestaurant: GoogleRestaurant?
    var imagesOfRestaurant = [UIImage]()
    var restaurantTimes = [String]()
    var isRestaurantOpen = Bool()
    
    var currentReviews = [RestaurantReviews]()
    
    var cornerRadius = Float()
    
    var parentSource: ParentController?
    var restaurantSource: RestaurantSource = .likes
    var removeDelegate: RemoveFromArray?
    var statusBarDelegate: UpdateStatusBar?
    
    var avgColor = UIColor()
    var contrastColor = UIColor()
    
    private var pullToDismiss: PullToDismiss?
    
    override var prefersStatusBarHidden: Bool {
        // if parent controller == defaultViewController
        // then status bar should be hidden
        return parentSource == .defaultController ? true : false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
    }
    
    // MARK: - Functions
    
    func setupView() {
        
        guard let restaurantToUse = googleRestaurant else { return }
        
        // universal corner radius for elements (set in DefaultViewController)
        cornerRadius = defaults.float(forKey: "cornerRadius")
        
        let closeBlur = UIViewPropertyAnimator(duration: 0.5, curve: .easeOut) {
            
            self.alertView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            self.alertView.alpha = 0
            
        }
        closeBlur.addCompletion { (position) in
            
            self.alertView.isHidden = true
            
        }
        
        // alertView coloring
        
        self.avgColor = UIColor(averageColorFrom: restaurantToUse.heroImage)
        self.contrastColor = UIColor(contrastingBlackOrWhiteColorOn: self.avgColor, isFlat: true)
        
        self.alertView.blurRadius = 10
        self.alertView.colorTint = self.contrastColor
        self.alertView.colorTintAlpha = 0.6
        self.alertViewImage.tintColor = self.avgColor
        self.alertViewLabel.textColor = self.avgColor
        
        self.showAlertView(withMessage: "Loading", #imageLiteral(resourceName: "btn_refresh"))
        
        getBusinessDetails(restaurantToUse.placeId) { (restaurant) in
            
            // Immediate visible UI setup
            self.restaurantPhotoBlur.colorTint = self.contrastColor
            self.restaurantPhotoBlur.colorTintAlpha = 0.45
            self.restaurantPhotoBlur.blurRadius = 23
            self.restaurantPhotoBlur.scale = 1
            
            self.restaurantPhoto.image = restaurant.heroImage
            self.restaurantPhoto.clipsToBounds = true
            self.restaurantPhoto.contentMode = .scaleAspectFill
            
            self.restaurantHeaderView.backgroundColor = self.avgColor.withAlphaComponent(0.8)
            
            self.restaurantName.text = restaurant.name
            self.restaurantName.textColor = self.contrastColor
            
            self.restaurantCategory.text = restaurant.category
            self.restaurantCategory.textColor = self.contrastColor
            self.restaurantCategory.numberOfLines = 0
            
            self.restaurantRating.contentMode = .right
            self.restaurantRating.rating = restaurant.rating
            // restaurantRating.text = "\(restaurant.reviewCount) VOTES"
            self.restaurantRating.settings.textColor = self.contrastColor
            self.restaurantRating.settings.emptyBorderWidth = 0
            self.restaurantRating.settings.filledBorderColor = UIColor.clear
            self.restaurantRating.settings.emptyBorderColor = UIColor.clear
            self.restaurantRating.settings.filledColor = self.contrastColor
            self.restaurantRating.settings.emptyColor = self.contrastColor.withAlphaComponent(0.3)
            self.restaurantRating.settings.updateOnTouch = false
            self.restaurantRating.settings.starSize = 23
            
            // start attributed label
            
            self.restaurantPriceDistance.textColor = self.contrastColor
            
            // get range of text to colour
            let textColorRange = NSRange(location: 0, length: restaurant.priceRange)
            // get location of text to have a darker colour (4 is highest price)
            let nonColor = 4 - restaurant.priceRange
            // get range of text to have a darker colour
            let nonTextColorRange = NSRange(location: restaurant.priceRange, length: nonColor)
            let multipleText = "$$$$ · \(restaurant.distance) · \(restaurant.duration)"
            
            let attributedString = NSMutableAttributedString(string: multipleText)
            attributedString.setColorForRange(textColorRange, with: self.contrastColor)
            attributedString.setColorForRange(nonTextColorRange, with: self.contrastColor.withAlphaComponent(0.3))
            self.restaurantPriceDistance.attributedText = attributedString
            
            // end attributed label
            
            self.restaurantAddressTitle.textColor = self.contrastColor.withAlphaComponent(0.7)
            self.restaurantAddress.text = restaurant.address
            self.restaurantAddress.textColor = self.contrastColor
            
            self.restaurantPhoneTitle.textColor = self.contrastColor.withAlphaComponent(0.7)
            self.restaurantPhone.text = restaurant.phone
            self.restaurantPhone.textColor = self.contrastColor
            
            // does timings and sets everything
            self.restaurantTimes = restaurant.timings
            self.restaurantTimingsTitle.textColor = self.contrastColor.withAlphaComponent(0.7)
            self.restaurantTimingsLabel.textColor = self.contrastColor
            let i = self.getCurrentDayIndex()
            self.restaurantTimingsLabel.text = restaurant.timings[i]
            
            self.restaurantPhotosTitle.textColor = self.contrastColor.withAlphaComponent(0.7)
            self.photosCollectionView.delegate = self
            self.photosCollectionView.dataSource = self
            self.imagesOfRestaurant = restaurant.images
            DispatchQueue.main.async {
                self.photosCollectionView.reloadData()
            }
            
            // set colors/tints for buttons
            
            // Timings Button Blur and Image
            self.restaurantTimingsView.backgroundColor = self.avgColor.withAlphaComponent(0.8)
            
            let timingsImage = #imageLiteral(resourceName: "btn_timings").withRenderingMode(.alwaysTemplate)
            self.restaurantTimingsButton.setImage(timingsImage, for: .normal)
            self.restaurantTimingsButton.imageView?.tintColor = self.contrastColor
            self.restaurantTimingsButton.tintColor = self.contrastColor
            self.restaurantTimingsButton.imageView?.contentMode = .scaleAspectFit
            
            // Reviews Button Blur and Image
            self.restaurantReviewsView.backgroundColor = self.avgColor.withAlphaComponent(0.8)
            
            let reviewsImage = #imageLiteral(resourceName: "btn_reviews_selected").withRenderingMode(.alwaysTemplate)
            self.restaurantReviewsButton.setImage(reviewsImage, for: .normal)
            self.restaurantReviewsButton.imageView?.tintColor = self.contrastColor
            self.restaurantReviewsButton.tintColor = self.contrastColor
            self.restaurantReviewsButton.imageView?.contentMode = .scaleAspectFit
            
            // App Buttons Blur and Images
            self.restaurantAppButtonsView.backgroundColor = self.avgColor.withAlphaComponent(0.8)
            
            let phoneImage = #imageLiteral(resourceName: "btn_call_selected").withRenderingMode(.alwaysTemplate)
            self.restaurantPhoneButton.setImage(phoneImage, for: .normal)
            self.restaurantPhoneButton.imageView?.tintColor = self.contrastColor
            self.restaurantPhoneButton.tintColor = self.contrastColor
            self.restaurantPhoneButton.imageView?.contentMode = .scaleAspectFit
            
            let mapsImage = #imageLiteral(resourceName: "btn_directions_selected").withRenderingMode(.alwaysTemplate)
            self.restaurantMapsButton.setImage(mapsImage, for: .normal)
            self.restaurantMapsButton.imageView?.tintColor = self.contrastColor
            self.restaurantMapsButton.tintColor = self.contrastColor
            self.restaurantMapsButton.imageView?.contentMode = .scaleAspectFit
            
            let websiteImage = #imageLiteral(resourceName: "btn_openWebsite_selected").withRenderingMode(.alwaysTemplate)
            self.restaurantWebsiteButton.setImage(websiteImage, for: .normal)
            self.restaurantWebsiteButton.imageView?.tintColor = self.contrastColor
            self.restaurantWebsiteButton.tintColor = self.contrastColor
            self.restaurantWebsiteButton.imageView?.contentMode = .scaleAspectFit
            
            self.reviewsMakeReview.setImage(#imageLiteral(resourceName: "btn_closeView"), for: [])
            self.reviewsMakeReview.imageView?.tintColor = self.contrastColor
            self.reviewsMakeReview.tintColor = self.contrastColor
            self.reviewsMakeReview.imageView?.contentMode = .scaleAspectFit
            
            // targets
            self.restaurantTimingsButton.addTarget(self, action: #selector(self.openTimingsView), for: .touchUpInside)
            self.restaurantReviewsButton.addTarget(self, action: #selector(self.openReviewView), for: .touchUpInside)
            self.timingsDoneButton.addTarget(self, action: #selector(self.openTimingsView), for: .touchUpInside)
            self.reviewsDoneButton.addTarget(self, action: #selector(self.openReviewView), for: .touchUpInside)
            self.restaurantReviewsButton.addTarget(self, action: #selector(self.openReviewView), for: .touchUpInside)
            self.restaurantMapsButton.addTarget(self, action: #selector(self.openMaps), for: .touchUpInside)
            self.restaurantPhoneButton.addTarget(self, action: #selector(self.callBusiness), for: .touchUpInside)
            self.restaurantWebsiteButton.addTarget(self, action: #selector(self.openWebsite), for: .touchUpInside)
            // reviewsMakeReview.addTarget(self, action: #selector(openSubmitReviewView), for: .touchUpInside)
            
            
            // Other UI setup (timings/reviews)
            
            // timings
            self.timingsTableView.estimatedRowHeight = 400
            self.timingsTableView.rowHeight = UITableViewAutomaticDimension
            self.timingsTableView.setNeedsLayout()
            self.timingsTableView.layoutIfNeeded()
            self.timingsTableView.reloadData()
            self.timingsTableView.delegate = self
            self.timingsTableView.dataSource = self
            self.timingsContainerView.isHidden = false // will now use blur effect == nil to open/close view
            self.timingsContainerView.alpha = 0
            
            // reviews
            self.reviewsTableView.estimatedRowHeight = 400
            self.reviewsTableView.rowHeight = UITableViewAutomaticDimension
            self.reviewsTableView.setNeedsLayout()
            self.reviewsTableView.layoutIfNeeded()
            self.reviewsTableView.reloadData()
            self.reviewsTableView.delegate = self
            self.reviewsTableView.dataSource = self
            self.reviewsContainerView.isHidden = false // will now use blur effect == nil to open/close view
            self.reviewsContainerView.alpha = 0
            
            // use .alpha instead of .effect to reduce CPU usage and lag
            // plus the VisualEffectView framework doesn't allow for
            // animating the .effect component
            self.containerBackgroundBlur.colorTint = self.avgColor
            self.containerBackgroundBlur.colorTintAlpha = 0.3
            self.containerBackgroundBlur.blurRadius = 25
            self.containerBackgroundBlur.scale = 1
            self.containerBackgroundBlur.alpha = 0
            
            // timings view coloring
            self.timingsDoneButton.backgroundColor = self.contrastColor
            self.timingsDoneButton.setTitleColor(self.avgColor, for: .normal)
            self.timingsTitleLabel.textColor = self.contrastColor
            self.timingsOpenOrCloseView.backgroundColor = self.contrastColor
            self.timingsOpenOrClose.textColor = self.avgColor.withAlphaComponent(0.8)
            
            self.timingsOpenOrClose.text = restaurant.openNow ? "OPEN NOW" : "CLOSED"
            self.updateOpenCloseLabel()
            
            let refreshImage = #imageLiteral(resourceName: "btn_refresh").withRenderingMode(.alwaysTemplate)
            self.timingsRedoButton.setImage(refreshImage, for: .normal)
            self.timingsRedoButton.tintColor = self.contrastColor
            self.timingsRedoButton.imageView?.tintColor = self.contrastColor
            self.timingsRedoButton.imageView?.contentMode = .scaleAspectFit
            
            // reviews view coloring
            self.reviewsDoneButton.backgroundColor = self.contrastColor
            self.reviewsDoneButton.setTitleColor(self.avgColor, for: .normal)
            self.reviewsTitleLabel.textColor = self.contrastColor
            self.reviewsStarView.settings.textColor = self.contrastColor
            self.reviewsStarView.settings.filledBorderColor = UIColor.clear
            self.reviewsStarView.settings.emptyBorderColor = UIColor.clear
            self.reviewsStarView.settings.filledColor = self.contrastColor
            self.reviewsStarView.settings.emptyColor = self.contrastColor.withAlphaComponent(0.3)
            
            if self.parentSource == .favouritesController {
                // show button on navigation bar since favouriteController pushes this view with a nav bar
                let barButton = UIBarButtonItem(image: #imageLiteral(resourceName: "dots"), style: .plain, target: self, action: #selector(self.openRestaurantActionSheet))
                self.navigationItem.rightBarButtonItem = barButton
                
            } else {
                // use pull to dismiss since defaultController pushes this view using a modal segue
                self.pullToDismiss = PullToDismiss(scrollView: self.scrollView, viewController: self)
                self.pullToDismiss?.delegate = self
                self.pullToDismiss?.dismissableHeightPercentage = 0.45
                self.pullToDismiss?.dismissAction = {
                    self.dismissViewThing()
                }
            }
            
            self.setCornerRadius()
            closeBlur.startAnimation()
            
        }
        
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
        
        self.dismiss(animated: true, completion: nil)
        if let del = statusBarDelegate {
            del.updateStatusBar()
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
    
    func getCurrentDayIndex() -> Int {
        
        // return index of day
        
        let date = Date()
        let calendar = Calendar.current
        
        let day = calendar.component(.weekday, from: date)
        
        return day - 2 // - 2 because week starts from sunday
        
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
    
    // MARK: - Button Functions
    
    func openTimingsView() {
        
        let openView = UIViewPropertyAnimator(duration: 0.3, curve: .linear) {
            
            self.timingsContainerView.alpha = 1
            self.timingsContainerView.isUserInteractionEnabled = true
            self.containerBackgroundBlur.alpha = 1
            self.containerBackgroundBlur.isUserInteractionEnabled = true
            if self.parentSource == .favouritesController {
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
            if self.parentSource == .favouritesController {
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
            if self.parentSource == .favouritesController {
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
            if self.parentSource == .favouritesController {
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
        
        guard let restaurant = googleRestaurant else { return }
        guard let url = URL(string: "tel://\(restaurant.phone)") else { return }
        
        UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
            
            if !success {
                
                self.showAlertController("Failed To Call", "There's been a slight complication. The call cannot be made, make sure you are using an iPhone or a compatible device.", nil)
                
            }
            
        })
        
    }
    
    func openWebsite() {
        
        guard let restaurant = googleRestaurant else { return }
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
        
        guard let restaurant = googleRestaurant else { return }
        guard let appName = defaults.object(forKey: "defaultMaps") as? String else { return }
        
        let addressString = restaurant.address.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        
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
        
        guard let restaurant = googleRestaurant else { return }
        
        if defaults.object(forKey: "favourites") == nil {
            
            // no favs, create arr, encode and replace
            
            var favouriteRestaurants = [GoogleRestaurant]()
            favouriteRestaurants.append(restaurant)
            
            let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: favouriteRestaurants)
            defaults.set(encodedData, forKey: "favourites")
            defaults.synchronize()
            
            callRemoveDelegate() // remove from session favourites/likes array in FavouritesViewController (collection view)
            
        } else {
            
            if let decodedArr = defaults.object(forKey: "favourites") as? Data {
                
                if var decodedRestaurants = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [GoogleRestaurant] {
                    
                    if !(decodedRestaurants.contains(where: { $0.placeId == restaurant.placeId } )) {
                        
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
        
        guard let restaurant = googleRestaurant else { return }
        if defaults.object(forKey: "dislikes") == nil {
            
            // no dislikes, create arr, encode and replace
            
            var dislikeRestaurants = [GoogleRestaurant]()
            dislikeRestaurants.append(restaurant)
            
            let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: dislikeRestaurants)
            defaults.set(encodedData, forKey: "dislikes")
            defaults.synchronize()
            
        } else {
            
            guard let decodedArr = defaults.object(forKey: "dislikes") as? Data else { return }
            guard var decodedRestaurants = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [GoogleRestaurant] else { return }
            
            if !(decodedRestaurants.contains(where: { $0.placeId == restaurant.placeId } )) {
                
                // not in dislikes -> add to dislikes
                
                decodedRestaurants.append(restaurant)
                
            }
            let encode: Data = NSKeyedArchiver.archivedData(withRootObject: decodedRestaurants)
            defaults.set(encode, forKey: "dislikes")
            defaults.synchronize()
            
        }
        
    }
    
    func removeFromDislikes() {
        
        guard let restaurant = googleRestaurant else { return }
        guard let decodedArr = defaults.object(forKey: "dislikes") as? Data else { return }
        guard let decodedRestaurants = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [GoogleRestaurant] else { return }
        
        let newRestaurants = decodedRestaurants.filter{ !($0.placeId == restaurant.placeId) }
        // return everything that doesn't match the current restaurant ID
        // (i.e the one we want deleted)
        
        let encode: Data = NSKeyedArchiver.archivedData(withRootObject: newRestaurants)
        defaults.set(encode, forKey: "dislikes")
        defaults.synchronize()
        
    }
    
    func removeFromLongTermFavourites() {
        
        guard let restaurant = googleRestaurant else { return }
        guard let decodedArr = defaults.object(forKey: "favourites") as? Data else { return }
        guard let decodedRestaurants = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [GoogleRestaurant] else { return }
        
        let newRestaurants = decodedRestaurants.filter{ !($0.placeId == restaurant.placeId) }
        // return everything that doesn't match the current restaurant ID
        // (i.e the one we want deleted)
        
        let encode: Data = NSKeyedArchiver.archivedData(withRootObject: newRestaurants)
        defaults.set(encode, forKey: "favourites")
        defaults.synchronize()
        
    }
    
    func callRemoveDelegate() {
        
        // removes from sessions likes in Favourites controller
        // then goes back to favourites view
        
        guard let restaurant = googleRestaurant else { return }
        
        if let del = removeDelegate {
            // del.removeFromArrayWith(restaurant)
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
                self.callRemoveDelegate() // removes from FavouritesViewController (collection view) and then goes to back to preview view
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
        
        let blurAnimator = UIViewPropertyAnimator(duration: 0.5, curve: .easeIn) {
            
            self.alertView.transform = CGAffineTransform.identity
            self.alertView.alpha = 1
            
        }
        
        self.alertView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        self.alertView.alpha = 0
        self.alertView.isHidden = false
        
        // prep before animation
        
        alertViewImage.image = image.withRenderingMode(.alwaysTemplate)
        alertViewLabel.text = message
        alertView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        blurAnimator.startAnimation(afterDelay: 3)
        
    }
    
    // MARK: - API Functions
    
    func getBusinessDetails(_ id: String, completionHandler: @escaping (GoogleRestaurant) -> ()) {
        
        let stringURL = "https://maps.googleapis.com/maps/api/place/details/json?placeid=\(id)&key=AIzaSyBfBphVionPiyoDp0KFcz_jrKwJIKiWStI"
        
        print(stringURL)
        
        guard let url = URL(string: stringURL) else { return }
        
        Alamofire.request(url).responseJSON { (response) in
            
            if let value = response.result.value {
                
                let json = JSON(value)
                
                var address = json["result"]["vicinity"].stringValue
                address += ", \(json["result"]["address_components"][4]["long_name"].stringValue) \(json["result"]["address_components"][6]["long_name"].stringValue)"
                
                let phoneNumber = json["result"]["formatted_phone_number"].stringValue
                let website = json["result"]["website"].stringValue
                let hours = json["result"]["opening_hours"]["weekday_text"].arrayObject as! [String]
                
                address = address.replacingOccurrences(of: ", ", with: "\n")
                
                guard let unwrappedGoogle = self.googleRestaurant else { return }
                
                self.getPhotos(id, completionHandler: { (images) in
                    
                    let newRestaurant = GoogleRestaurant(placeId: unwrappedGoogle.placeId, name: unwrappedGoogle.name, website: website, category: unwrappedGoogle.category, heroImage: unwrappedGoogle.heroImage, images: images, rating: unwrappedGoogle.rating, priceRange: unwrappedGoogle.priceRange, phone: phoneNumber, openNow: unwrappedGoogle.openNow, distance: unwrappedGoogle.distance, duration: unwrappedGoogle.duration, address: address, timings: hours, types: [""])
                                        
                    completionHandler(newRestaurant)
                    
                })
                
                self.getReviews(id)
                
            }
            
        }
        
    }
    
    func getPhotos(_ id: String, completionHandler: @escaping ([UIImage]) -> ()) {
        
        let stringURL = "https://maps.googleapis.com/maps/api/place/details/json?placeid=\(id)&key=AIzaSyBfBphVionPiyoDp0KFcz_jrKwJIKiWStI"
        
        guard let url = URL(string: stringURL) else { return }
        
        Alamofire.request(url).responseJSON { (response) in
            
            if let value = response.result.value {
                
                let json = JSON(value)
                
                let photosArr = json["result"]["photos"].arrayValue
                
                var images = [UIImage]()
                for photo in photosArr {
                    
                    var image = UIImage()
                    let link = "https://maps.googleapis.com/maps/api/place/photo?maxheight=600&photoreference=\(photo["photo_reference"].stringValue)&key=AIzaSyBfBphVionPiyoDp0KFcz_jrKwJIKiWStI"
                    if let unwrappedImageURL = URL(string: link) {
                        
                        if let imageData = try? Data(contentsOf: unwrappedImageURL) {
                            
                            image = UIImage(data: imageData)!
                            
                        } else {
                            
                            image = #imageLiteral(resourceName: "placeholderImage")
                            
                        }
                        
                    } else {
                        
                        image = #imageLiteral(resourceName: "placeholderImage")
                        
                    }
                    
                    images.append(image)
                    
                }
                
                completionHandler(images)
                
            }
            
        }
        
        
    }
    
    func getReviews(_ id: String) {
        
        let stringURL = "https://maps.googleapis.com/maps/api/place/details/json?placeid=\(id)&key=AIzaSyBfBphVionPiyoDp0KFcz_jrKwJIKiWStI"
        
        guard let url = URL(string: stringURL) else { return }
        Alamofire.request(url).responseJSON { (response) in
            
            if let value = response.result.value {
                
                let json = JSON(value)
                let reviewsArr = json["result"]["reviews"].arrayValue
                
                for review in reviewsArr {
                    
                    let name = review["author_name"].stringValue
                    let photoURL = review["profile_photo_url"].stringValue
                    let time = review["relative_time_description"].stringValue
                    let text = review["text"].stringValue
                    let rating = review["rating"].intValue
                    
                    let newReview = RestaurantReviews(name: name, rating: 5, imageURL: photoURL, reviewText: text, reviewTime: time)
                    self.currentReviews.append(newReview)
                    
                }
                
                DispatchQueue.main.async {
                    self.reviewsTableView.reloadData()
                }
                
            }
            
        }
        
    }
    
    // MARK: - Table view
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == reviewsTableView {
            return currentReviews.count
        } else {
            return restaurantTimes.count
            
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
            
            cell.name.textColor = UIColor.flatBlack
            cell.textReview.textColor = UIColor.flatBlack
            cell.timeOfReview.textColor = UIColor.flatBlack
            
            return cell
            
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "TimingsCell", for: indexPath) as! TimingsCell
            
            cell.day.numberOfLines = 0
            
            let fullWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
            let timing = restaurantTimes[indexPath.row]
            
            let range = (timing as NSString).range(of: "\(fullWeek[indexPath.row]):")
            let text = (timing as NSString).substring(with: range)
            
            if let range2 = timing.range(of: "\(fullWeek[indexPath.row]): ") {
                
                let other = timing[range2.upperBound...]
                cell.day.text = "\(text)\n\(other)"
                
            }
            
            
            cell.day.textColor = UIColor.flatBlack
            
            if indexPath.row == getCurrentDayIndex() {
                
                cell.day.font = UIFont.boldSystemFont(ofSize: 19)
                
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
    
    // MARK: - Collection View Delegate
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagesOfRestaurant.count
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
        
        let photos = imagesOfRestaurant[indexPath.row]
        
        cell.imageView.image = photos
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
