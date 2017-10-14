//
//  RestaurantDetailTableViewController.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-10-07.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit
import Hero
import Cosmos
import ChameleonFramework

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

class RestaurantDetailTableViewController: UITableViewController {

    @IBOutlet var closeBtn: UIButton!
    @IBOutlet var restaurantPhoto: UIImageView!
    @IBOutlet var restaurantName: UILabel!
    @IBOutlet var restaurantCategory: UILabel!
    @IBOutlet var restaurantRating: CosmosView!
    @IBOutlet var restaurantPriceDistance: UILabel!
    
    @IBOutlet var restaurantAddress: UILabel!
    
    var headerView: CategoryHeaderView!
    var headerHeightConstraint: NSLayoutConstraint!
    var panGR: UIPanGestureRecognizer!
    var restaurant: Restaurant?
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isHeroEnabled = true
        
        if let restaurant = restaurant {
            
            let btnImg = #imageLiteral(resourceName: "btn_closeView").withRenderingMode(.alwaysTemplate)
            closeBtn.setImage(btnImg, for: .normal)
            closeBtn.addTarget(self, action: #selector(self.hero_dismissViewController), for: .touchUpInside)
            
            let restID = restaurant.id
            
            restaurantName.text = restaurant.name
            restaurantName.heroID = "\(restID)_name"
            restaurantName.heroModifiers = [.zPosition(4)]
            
            restaurantPhoto.image = restaurant.image
            restaurantPhoto.heroID = "\(restID)_image"
            restaurantPhoto.heroModifiers = [.zPosition(2)]
            
            restaurantCategory.text = restaurant.category
            restaurantCategory.heroID = "\(restID)_category"
            restaurantCategory.heroModifiers = [.zPosition(4)]
            
            restaurantRating.contentMode = .right
            restaurantRating.rating = Double(restaurant.rating)
            restaurantRating.settings.emptyBorderWidth = 0
            restaurantRating.settings.emptyBorderColor = UIColor.clear
            restaurantRating.settings.emptyColor = UIColor.lightText
            restaurantRating.settings.updateOnTouch = false
            restaurantRating.settings.starSize = 23
            restaurantRating.heroID = "\(restID)_rating"
            restaurantRating.heroModifiers = [.zPosition(4)]
            
            // start attributed label
            
            // get range of text to colour
            let textColorRange = NSRange(location: 0, length: restaurant.priceRange.count)
            // get location of text to have a darker colour (4 is highest price)
            let nonColor = 4 - restaurant.priceRange.count
            // get range of text to have a darker colour
            let nonTextColorRange = NSRange(location: restaurant.priceRange.count, length: nonColor)
            let multipleText = "$$$$ · " + convert(restaurant.distance)
            
            let attributedString = NSMutableAttributedString(string: multipleText)
            attributedString.setColorForRange(textColorRange, with: UIColor.green)
            attributedString.setColorForRange(nonTextColorRange, with: UIColor.green.withAlphaComponent(0.3))
            
            restaurantPriceDistance.attributedText = attributedString
            restaurantPriceDistance.heroID = "\(restID)_priceDistance"
            restaurantPriceDistance.heroModifiers = [.zPosition(4), .fade]
            
            let address = "\(restaurant.address) \n\(restaurant.city), \(restaurant.state) \n\(restaurant.country)"
            
            restaurantAddress.text = address
            
            // end attributed label
            
            DispatchQueue.main.async {
                
                // tableView background poster
                let posterBig = UIImageView(image: restaurant.image)
                posterBig.frame = self.view.bounds
                posterBig.contentMode = .scaleAspectFill
                posterBig.clipsToBounds = true
                self.tableView.backgroundView = posterBig
                posterBig.image = posterBig.image?.applyBlurWithRadius(30, tintColor: UIColor(white: 0.11, alpha: 0.73), saturationDeltaFactor: 1.8)
                posterBig.heroID = "\(restID)_gradient"
                posterBig.heroModifiers = [.fade]
                
                self.tableView.layoutSubviews()
                self.tableView.layoutIfNeeded()
                self.tableView.reloadData()
                
            }
            
            self.tableView.heroID = "\(restID)_view"
            
            self.tableView.backgroundColor = UIColor.clear
            self.tableView.separatorColor = UIColor.clear
            self.tableView.tableFooterView = UIView()
            
            panGR = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
            view.addGestureRecognizer(panGR)
            
            self.loadData()
            
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadData() {
        
        guard let restaurant = restaurant else { return }
        
        // let imgAvgColor = AverageColorFromImage(restaurant.image!)
        // let contrastColor = ContrastColorOf(imgAvgColor, returnFlat: true)
        
        headerView = CategoryHeaderView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 220), image: restaurant.image!)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        tableView.addSubview(headerView)
        
        headerHeightConstraint = headerView.heightAnchor.constraint(equalToConstant: 220)
        headerHeightConstraint.isActive = true
        
        let constraints:[NSLayoutConstraint] = [
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
        print(headerView.bounds)
        
        let btnImg = #imageLiteral(resourceName: "btn_closeView").withRenderingMode(.alwaysTemplate)
        closeBtn.setImage(btnImg, for: .normal)
        // closeBtn.backgroundColor = contrastColor
        // closeBtn.tintColor = imgAvgColor
        closeBtn.addTarget(self, action: #selector(self.hero_dismissViewController), for: .touchUpInside)
        
    }
    
    func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        let translation = gestureRecognizer.translation(in: nil)
        let progress = translation.y / view.bounds.height
        
        switch gestureRecognizer.state {
            
        case .began:
            // begin transition as normal
            dismiss(animated: true, completion: nil)
        case .changed:
            // calculate the progress based on how far the user moved
            Hero.shared.update(progress: Double(progress))
            
            // Hero.shared.apply(modifiers: [.position(CGPoint(x: restaurantPhoto.center.x, y: translation.y + restaurantPhoto.center.y))], to: restaurantPhoto)
            // Hero.shared.apply(modifiers: [.position(CGPoint(x: restaurantName.center.x, y: translation.y + restaurantName.center.y))], to: restaurantName)
            // Hero.shared.apply(modifiers: [.position(CGPoint(x: restaurantCategory.center.x, y: translation.y + restaurantCategory.center.y))], to: restaurantCategory)
            // Hero.shared.apply(modifiers: [.position(CGPoint(x: restaurantRating.center.x, y: translation.y + restaurantRating.center.y))], to: restaurantRating)
            Hero.shared.apply(modifiers: [.fade], to: restaurantPriceDistance)
            
        default:
            if progress + panGR.velocity(in: nil).y / view.bounds.height > 0.3 {
                Hero.shared.end()
            } else {
                Hero.shared.cancel()
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
        
        if distance.value == 0 {
            
            finalString = measurementFormatter.string(from: distance)
            
        } else if distance.value <= 1 {
            
            numberFormatter.maximumFractionDigits = 2
            finalString = "0" + measurementFormatter.string(from: distance)
            
        } else {
            
            numberFormatter.maximumFractionDigits = 1
            finalString = measurementFormatter.string(from: distance)
            
        }
        
        return finalString + " away"
        
    }
    
    func returnFormatted(_ phoneNumber: String) -> String {
        
        do {
            
            // let parsedPhoneNumber = try phoneNumberKit.parse(phoneNumber)
            // let formattedNumber = phoneNumberKit.format(parsedPhoneNumber, toType: .international)
            return "return"
            
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
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    // add ViewDidAppear tableView layout thingy

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
