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
    
    var defaults = UserDefaults.standard
    var currentReviews = [RestaurantReviews]()
    
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
        
        backgroundBlur.effect = nil
        self.reviewsContainerView.alpha = 0.0
        
        self.reviewsContainerView.isHidden = true
        self.backgroundBlur.isHidden = true
        
        reviewsContainerView.layer.cornerRadius = 15
        reviewsContainerView.clipsToBounds = true
        reviewsContainerView.isHidden = true
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        let blurEffectView2 = UIVisualEffectView(effect: blurEffect)
        blurEffectView2.frame = reviewsTableView.bounds
        reviewsTableView.backgroundView = blurEffectView2
        reviewsTableView.separatorEffect = UIBlurEffect(style: UIBlurEffectStyle.prominent)
        
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
        
        self.reviewsHeaderLabel.text = "\(self.restaurant.reviewCount) VOTES"
        
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
        
        if reviewsContainerView.isHidden == true {
            
            self.reviewsContainerView.isHidden = false
            self.backgroundBlur.isHidden = false
            blurAnimator.startAnimation()
            
        } else {
            
            noBlurAnimator.startAnimation()
            self.reviewsContainerView.isHidden = true
            self.backgroundBlur.isHidden = true
            
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
