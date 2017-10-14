//
//  ViewController2.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-09-09.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire
import SDWebImage

class ViewController2: UIViewController {
    
    var cards = [RestaurantCardALT]()
    var restaurants = [Restaurant]()

    var selectedCategory = String()
    var selectedSortBy = String()
    
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dynamicAnimator = UIDynamicAnimator(referenceView: self.view)
        self.selectedSortBy = "best_match"
        self.selectedCategory = "All Types"
        
        searchBusinesses(37.785834, -122.406417) { (success) in
            
            if success {
                
                for i in 1...self.restaurants.count - 1 {
                    
                    let restaurantCard = RestaurantCardALT(frame: CGRect(x: 0, y: 0, width: self.view.frame.width - 60, height: self.view.frame.height * 0.6))
                    print(self.view.frame.height * 0.9)
                    restaurantCard.restaurant = self.restaurants[i]
                    self.cards.append(restaurantCard)
                    
                }
                
                self.layoutCards()
                
            }
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    let cardAttributes: [(downscale: CGFloat, alpha: CGFloat)] = [(1, 1), (0.92, 0.8), (0.84, 0.6), (0.76, 0.4)]
    let cardInteritemSpacing: CGFloat = 15
    
    func layoutCards() {
        
        let firstCard = cards[0]
        self.view.addSubview(firstCard)
        firstCard.layer.zPosition = CGFloat(cards.count)
        firstCard.center = self.view.center
        firstCard.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleCardPan)))
        
        for i in 1...3 {
            
            if i > (cards.count - 1) { continue }
            
            let card = cards[i]
            card.layer.zPosition = CGFloat(cards.count - i)
            
            let downscale = cardAttributes[i].downscale
            let alpha = cardAttributes[i].alpha
            card.transform = CGAffineTransform(scaleX: downscale, y: downscale)
            card.alpha = alpha
            
            card.center.x = self.view.center.x
            card.frame.origin.y = cards[0].frame.origin.y - (CGFloat(i) * cardInteritemSpacing)
            
            if i == 3 {
                card.frame.origin.y += 1.5
            }
            
            self.view.addSubview(card)
            
        }
        
        self.view.bringSubview(toFront: cards[0])
        
    }
    
    func showNextCard() {
        
        let animationDuration: TimeInterval = 0.2
        
        for i in 1...3 {
            
            if i > (cards.count - 1) { continue }
            
            let card = cards[i]
            let newDownscale = cardAttributes[i - 1].downscale
            let newAlpha = cardAttributes[i - 1].alpha
            
            UIView.animate(withDuration: animationDuration, delay: (TimeInterval(i - 1) * (animationDuration / 2)), usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: [], animations: {
                card.transform = CGAffineTransform(scaleX: newDownscale, y: newDownscale)
                card.alpha = newAlpha
                if i == 1 {
                    card.center = self.view.center
                } else {
                    card.center.x = self.view.center.x
                    card.frame.origin.y = self.cards[1].frame.origin.y - (CGFloat(i - 1) * self.cardInteritemSpacing)
                }
            }, completion: { (_) in
                if i == 1 {
                    card.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.handleCardPan)))
                }
            })
            
        }
        
        if 4 > (cards.count - 1) {
            if cards.count != 1 {
                self.view.bringSubview(toFront: cards[1])
            }
            return
        }
        let newCard = cards[4]
        newCard.layer.zPosition = CGFloat(cards.count - 4)
        let downscale = cardAttributes[3].downscale
        let alpha = cardAttributes[3].alpha
        
        newCard.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        newCard.alpha = 0
        newCard.center.x = self.view.center.x
        newCard.frame.origin.y = cards[1].frame.origin.y - (4 * cardInteritemSpacing)
        self.view.addSubview(newCard)
        
        UIView.animate(withDuration: animationDuration, delay: (3 * (animationDuration / 2)), usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: [], animations: {
            newCard.transform = CGAffineTransform(scaleX: downscale, y: downscale)
            newCard.alpha = alpha
            newCard.center.x = self.view.center.x
            newCard.frame.origin.y = self.cards[1].frame.origin.y - (3 * self.cardInteritemSpacing) + 1.5
        }, completion: { (_) in
            
        })

        self.view.bringSubview(toFront: self.cards[1])
        
    }
    
    func removeOldFrontCard() {
        cards[0].removeFromSuperview()
        cards.remove(at: 0)
    }
    
    var dynamicAnimator: UIDynamicAnimator!
    var cardAttachmentBehavior: UIAttachmentBehavior!
    
    func handleCardPan(sender: UIPanGestureRecognizer) {
        
        if cardIsHiding { return }
        
        // let optionLength: CGFloat = 60
        let requiredOffsetFromCenter: CGFloat = 15
        
        let panLocationInView = sender.location(in: view)
        let panLocationInCard = sender.location(in: cards[0])
        
        switch sender.state {
            
        case .began:
            
            dynamicAnimator.removeAllBehaviors()
            let offset = UIOffsetMake(panLocationInCard.x - cards[0].bounds.midX, panLocationInCard.y - cards[0].bounds.midY);
            // card is attached to center
            cardAttachmentBehavior = UIAttachmentBehavior(item: cards[0], offsetFromCenter: offset, attachedToAnchor: panLocationInView)
            dynamicAnimator.addBehavior(cardAttachmentBehavior)
            
        case .changed:
            cardAttachmentBehavior.anchorPoint = panLocationInView
            
        case .ended:
            dynamicAnimator.removeAllBehaviors()
            
            if !(cards[0].center.x > (self.view.center.x + requiredOffsetFromCenter) || cards[0].center.x < (self.view.center.x - requiredOffsetFromCenter)) {
                // snap to center
                let snapBehavior = UISnapBehavior(item: cards[0], snapTo: self.view.center)
                dynamicAnimator.addBehavior(snapBehavior)
            } else {
                
                let velocity = sender.velocity(in: self.view)
                let pushBehavior = UIPushBehavior(items: [cards[0]], mode: .instantaneous)
                pushBehavior.pushDirection = CGVector(dx: velocity.x/10, dy: velocity.y/10)
                pushBehavior.magnitude = 175
                dynamicAnimator.addBehavior(pushBehavior)
                // spin after throwing
                var angular = CGFloat.pi / 2 // angular velocity of spin
                
                let currentAngle: Double = atan2(Double(cards[0].transform.b), Double(cards[0].transform.a))
                
                if currentAngle > 0 {
                    angular = angular * 1
                } else {
                    angular = angular * -1
                }
                let itemBehavior = UIDynamicItemBehavior(items: [cards[0]])
                itemBehavior.friction = 0.2
                itemBehavior.allowsRotation = true
                itemBehavior.addAngularVelocity(CGFloat(angular), for: cards[0])
                dynamicAnimator.addBehavior(itemBehavior)
                
                showNextCard()
                hideFrontCard()
                
            }
            
        default:
            break

        }
        
    }
    
    var cardIsHiding = false
    
    func hideFrontCard() {
        
        if #available(iOS 10.0, *) {
            
            var cardRemoveTimer: Timer? = nil
            cardRemoveTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] (_) in
                guard self != nil else { return }
                if !(self!.view.bounds.contains(self!.cards[0].center)) {
                    cardRemoveTimer!.invalidate()
                    self?.cardIsHiding = true
                    UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseIn], animations: {
                        self?.cards[0].alpha = 0.0
                    }, completion: { (_) in
                        self?.removeOldFrontCard()
                        self?.cardIsHiding = false
                    })
                }
            })
            
        } else {
            // fallback for earlier versions
            
            UIView.animate(withDuration: 0.2, delay: 1.5, options: [.curveEaseIn], animations: {
                self.cards[0].alpha = 0.0
            }, completion: { (_) in
                self.removeOldFrontCard()
            })
        }
       
    }
    
    func searchBusinesses(_ lat: Double, _ long: Double, completetionHandler: @escaping (Bool) -> Void) {
        
        let headers: HTTPHeaders = ["Authorization": "Bearer Y43yqZUkj6vah5sgOHU-1PFN2qpapJsSwXZYScYTo0-nK9w5Y3lDvrdRJeG1IpQAADep0GrRL5ZDv6ybln03nIVzP7BL_IzAf_s7Wj5_QLPOO6oXns-nJe3-kIPiWHYx"]
        
        var searchRadius = defaults.integer(forKey: "searchRadius")
        
        let locale = Locale.current
        let isMetric = locale.usesMetricSystem
        
        if !isMetric {
            
            // convert searchRadius to meteres here
            
            let numberFormatter = NumberFormatter()
            numberFormatter.maximumFractionDigits = 0
            let measurementFormatter = MeasurementFormatter()
            measurementFormatter.unitOptions = .providedUnit
            measurementFormatter.numberFormatter = numberFormatter
            
            let searchMiles = Measurement(value: Double(searchRadius), unit: UnitLength.miles)
            let searchMeters = searchMiles.converted(to: UnitLength.meters)
            
            let searchToUse = measurementFormatter.string(from: searchMeters)
            let oneReplaced = searchToUse.replacingOccurrences(of: " m", with: "")
            
            if let intVal = Int(oneReplaced) {
                
                searchRadius = intVal
                
            }
            
        }
        
        var url = ""
        
        switch self.selectedCategory {
        case "All Types":
            
            url = "https://api.yelp.com/v3/businesses/search?radius=\(searchRadius)&latitude=\(lat)&longitude=\(long)&limit=50&sort_by=\(selectedSortBy)"
            
        default:
            
            url = "https://api.yelp.com/v3/businesses/search?radius=\(searchRadius)&latitude=\(lat)&longitude=\(long)&limit=50&categories=\(selectedCategory.lowercased())&sort_by=\(selectedSortBy)"
            
        }
        
        var name = String()
        var website = String()
        var image = UIImage()
        
        var rating = Int()
        var priceRange = String()
        var phone = String()
        var id = String()
        var closedBool = Bool()
        var restaurantCategory = String()
        var reviewCount = Int()
        var distance = Double()
        
        var city = String()
        var country = String()
        var state = String()
        var address = String()
        var zipCode = String()
        
        var transactions = [String]()
        
        var restaurantHoursToAppend = [RestaurantHours]()
        
        Alamofire.request(url, headers: headers).responseJSON { response in
            
            if let value = response.result.value {
                
                let json = JSON(value)
                
                if json["total"].intValue == 0 {
                    
                    completetionHandler(false)
                    
                } else {
                    
                    for business in json["businesses"].arrayValue {
                        
                        name = business["name"].stringValue
                        website = business["url"].stringValue
                        let imageURL = business["image_url"].stringValue
                        rating = business["rating"].intValue
                        priceRange = business["price"].stringValue
                        phone = business["phone"].stringValue
                        id = business["id"].stringValue
                        closedBool = business["is_closed"].boolValue
                        reviewCount = business["review_count"].intValue
                        distance = business["distance"].doubleValue
                        
                        city = business["location"]["city"].stringValue
                        country = business["location"]["country"].stringValue
                        state = business["location"]["state"].stringValue
                        address = business["location"]["address1"].stringValue
                        zipCode = business["location"]["zip_code"].stringValue
                        
                        transactions = business["transactions"].arrayValue.map( { $0.string! } )
                        
                        let imageFinalURL = URL(string: imageURL)
                        let posterData = try? Data(contentsOf: imageFinalURL!)
                        if let pData = posterData {
                            
                            image = UIImage(data: pData)!
                            
                        } else {
                            
                            image = #imageLiteral(resourceName: "placeholderImage")
                            
                        }
                        
                        restaurantHoursToAppend = [RestaurantHours]()
                        
                        for category in business["categories"].arrayValue {
                            
                            restaurantCategory = category["title"].stringValue
                            
                        }
                        
                        let newRestaurant = Restaurant(name: name, website: website, image: image, rating: rating, priceRange: priceRange, phone: phone, id: id, isClosed: closedBool, category: restaurantCategory, reviewCount: reviewCount, distance: distance, city: city, country: country, state: state, address: address, zipCode: zipCode, transactions: transactions)
                        self.restaurants.append(newRestaurant)
                        
                    }
                    
                    completetionHandler(true)
                    
                }
                
            } else {
                
                // add refresh type of button to try to reload results
                
                completetionHandler(false)
                
            }
            
        }
        
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
