//
//  FavouritesDetailContainerViewController.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-07-14.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import DeviceKit
import Cosmos

class FavouritesDetailContainerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var backgroundImageThingy: UIImageView!
    @IBOutlet var containerThingy: UIView!
    
    @IBOutlet var restaurantPhoneButton: UIButton!
    @IBOutlet var restaurantMapsButton: UIButton!
    @IBOutlet var restaurantWebsiteButton: UIButton!
    @IBOutlet var restaurantReviewsButton: UIButton!
    
    @IBOutlet var backgroundBlur: UIVisualEffectView!
    @IBOutlet var reviewsContainerView: UIView!
    @IBOutlet var reviewsTableView: UITableView!
    @IBOutlet var reviewsHeaderLabel: UILabel!
    @IBOutlet var reviewsHeaderView: UIVisualEffectView!
    @IBOutlet var reviewsDoneButton: UIButton!
    @IBOutlet var reviewsStarView: CosmosView!
    
    var defaults = UserDefaults.standard
    var currentReviews = [RestaurantReviews]()
    let device = Device()
    
    var restaurant: Restaurant! {
        
        didSet {
            
            setupView()
            
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.reviewsTableView.estimatedRowHeight = 400
        self.reviewsTableView.rowHeight = UITableViewAutomaticDimension
        self.reviewsTableView.setNeedsLayout()
        self.reviewsTableView.layoutIfNeeded()
        self.reviewsTableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getReviews()
        setupView()
        
        let image1 = #imageLiteral(resourceName: "btn_openWebsite").withRenderingMode(.alwaysTemplate)
        let image1S = #imageLiteral(resourceName: "btn_openWebsite_selected").withRenderingMode(.alwaysTemplate)
        let image2 = #imageLiteral(resourceName: "btn_reviews").withRenderingMode(.alwaysTemplate)
        let image2S = #imageLiteral(resourceName: "btn_reviews_selected").withRenderingMode(.alwaysTemplate)
        let image3 = #imageLiteral(resourceName: "btn_directions").withRenderingMode(.alwaysTemplate)
        let image3S = #imageLiteral(resourceName: "btn_directions_selected").withRenderingMode(.alwaysTemplate)
        let image4 = #imageLiteral(resourceName: "btn_call").withRenderingMode(.alwaysTemplate)
        let image4S = #imageLiteral(resourceName: "btn_call_selected").withRenderingMode(.alwaysTemplate)
        
        restaurantPhoneButton.setImage(image4, for: .normal)
        restaurantPhoneButton.setImage(image4S, for: .highlighted)
        restaurantPhoneButton.imageView?.tintColor = UIColor.white
        restaurantPhoneButton.imageView?.contentMode = .scaleAspectFit
        
        restaurantWebsiteButton.setImage(image1, for: .normal)
        restaurantWebsiteButton.setImage(image1S, for: .highlighted)
        restaurantWebsiteButton.imageView?.tintColor = UIColor.white
        restaurantWebsiteButton.imageView?.contentMode = .scaleAspectFit
        
        restaurantReviewsButton.setImage(image2, for: .normal)
        restaurantReviewsButton.setImage(image2S, for: .highlighted)
        restaurantReviewsButton.imageView?.tintColor = UIColor.white
        restaurantReviewsButton.imageView?.contentMode = .scaleAspectFit
        
        restaurantMapsButton.setImage(image3, for: .normal)
        restaurantMapsButton.setImage(image3S, for: .highlighted)
        restaurantMapsButton.imageView?.tintColor = UIColor.white
        restaurantMapsButton.imageView?.contentMode = .scaleAspectFit
        
        
        if device.diagonal == 4 {
            
            // setInsets(5)
            
        } else {
            
            // setInsets(4)
            
        }
        
        backgroundBlur.effect = nil
        self.reviewsContainerView.alpha = 0.0
        
        self.reviewsContainerView.isHidden = true
        self.backgroundBlur.isHidden = true
        
        reviewsContainerView.layer.cornerRadius = 15
        reviewsContainerView.clipsToBounds = true
        reviewsContainerView.isHidden = true
        reviewsTableView.backgroundColor = UIColor.white
        
        restaurantPhoneButton.addTarget(self, action: #selector(self.callBusiness), for: .touchUpInside)
        restaurantMapsButton.addTarget(self, action: #selector(self.openMaps), for: .touchUpInside)
        restaurantWebsiteButton.addTarget(self, action: #selector(self.openWebsite), for: .touchUpInside)
        restaurantReviewsButton.addTarget(self, action: #selector(self.openReviews), for: .touchUpInside)
        
    }
    
    func setupView() {
        
        if let url = URL(string: restaurant.imageURL) {
                        
            if let background = backgroundImageThingy {
                background.sd_setImage(with: url)
                background.contentMode = .scaleAspectFill
                background.clipsToBounds = true
                let blurEffect = UIBlurEffect(style: .dark)
                let blurView = UIVisualEffectView(effect: blurEffect)
                blurView.frame = background.bounds
                background.addSubview(blurView)
            }
            
        }
        
    }
    
    func setInsets(_ number: CGFloat) {
        
        restaurantMapsButton.imageEdgeInsets = UIEdgeInsets(top: number, left: 0, bottom: number, right: 0)
        restaurantPhoneButton.imageEdgeInsets = UIEdgeInsets(top: number, left: 0, bottom: number, right: 0)
        restaurantReviewsButton.imageEdgeInsets = UIEdgeInsets(top: number, left: 0, bottom: number, right: 0)
        restaurantWebsiteButton.imageEdgeInsets = UIEdgeInsets(top: number, left: 0, bottom: number, right: 0)
        
    }
    
    func getReviews() {
        
        self.currentReviews.removeAll()
        
        let headers: HTTPHeaders = ["Authorization": "Bearer Y43yqZUkj6vah5sgOHU-1PFN2qpapJsSwXZYScYTo0-nK9w5Y3lDvrdRJeG1IpQAADep0GrRL5ZDv6ybln03nIVzP7BL_IzAf_s7Wj5_QLPOO6oXns-nJe3-kIPiWHYx"]
        
        Alamofire.request("https://api.yelp.com/v3/businesses/\(self.restaurant.id)/reviews", headers: headers).responseJSON { (Response) in
            
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
        
        self.reviewsStarView.rating = Double(self.restaurant.rating)
        self.reviewsStarView.text = "\(self.restaurant.reviewCount) VOTES"
        self.reviewsStarView.settings.emptyBorderWidth = 0
        self.reviewsStarView.settings.emptyBorderColor = UIColor.clear
        self.reviewsStarView.settings.emptyColor = UIColor.darkGray
        self.reviewsStarView.settings.updateOnTouch = false
        self.reviewsStarView.settings.starSize = 21
        self.reviewsStarView.contentMode = .right
        
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
    
    func openReviews() {
        
        let blurAnimator = UIViewPropertyAnimator(duration: 0.3, curve: .linear) {
            
            self.reviewsContainerView.alpha = 1.0
            self.backgroundBlur.effect = UIBlurEffect(style: UIBlurEffectStyle.dark)
            
        }
        
        let noBlurAnimator = UIViewPropertyAnimator(duration: 0.3, curve: .linear) {
            
            self.reviewsContainerView.alpha = 0.0
            self.backgroundBlur.effect = nil
            
        }
        noBlurAnimator.addCompletion({ (postion) in
            self.reviewsContainerView.isHidden = true
            self.backgroundBlur.isHidden = true
            self.restaurantWebsiteButton.isEnabled = true
            self.restaurantMapsButton.isEnabled = true
            self.restaurantPhoneButton.isEnabled = true
        })
        
        let image1 = #imageLiteral(resourceName: "btn_reviews").withRenderingMode(.alwaysTemplate)
        let image1S = #imageLiteral(resourceName: "btn_reviews_selected").withRenderingMode(.alwaysTemplate)
        
        if reviewsContainerView.isHidden == true {
            
            self.reviewsContainerView.isHidden = false
            self.backgroundBlur.isHidden = false
            self.restaurantWebsiteButton.isEnabled = false
            self.restaurantMapsButton.isEnabled = false
            self.restaurantPhoneButton.isEnabled = false
            blurAnimator.startAnimation()
            
            self.restaurantReviewsButton.setImage(image1S, for: UIControlState.normal)
            
        } else {
            
            noBlurAnimator.startAnimation()
            
            self.restaurantReviewsButton.setImage(image1, for: UIControlState.normal)
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.currentReviews.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReviewsCell", for: indexPath) as! ReviewsCell
        
        let currentReview = currentReviews[indexPath.row]
        let imageURL = URL(string: currentReview.imageURL)
        
        if let urlThing = imageURL {
            cell.userImage.sd_setImage(with: urlThing, placeholderImage: UIImage(named: "emptyProfile"))
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
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableViewAutomaticDimension
        
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "FavouritesChildSegue" {
            
            let childController = segue.destination as! FavouritesDetailTableViewController
            childController.restaurant = restaurant
            
        }
        
    }

}
