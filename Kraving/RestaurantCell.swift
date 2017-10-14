//
//  RestaurantCell.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-10-14.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit
import Cosmos

class RestaurantCell: UICollectionViewCell {
    
    @IBOutlet var gradientView: UIView!
    @IBOutlet var featuredImageView: UIImageView!
    @IBOutlet var restaurantName: UILabel!
    @IBOutlet var restaurantCategory: UILabel!
    @IBOutlet var restaurantPriceAndDistance: UILabel!
    @IBOutlet var restaurantStars: CosmosView!
    
    var gradient = CAGradientLayer()
    
    var restaurant: Restaurant? {
        
        didSet {
            
            guard let restaurant = restaurant else { return }
            
            let id = restaurant.id
            
            featuredImageView.image = restaurant.image
            featuredImageView.heroID = "\(id)_image"
            featuredImageView.heroModifiers = [.zPosition(2)]
            
            restaurantName.text = restaurant.name
            restaurantName.heroID = "\(id)_name"
            restaurantName.heroModifiers = [.zPosition(4)]
            
            restaurantCategory.text = restaurant.category
            restaurantCategory.heroID = "\(id)_category"
            restaurantCategory.heroModifiers = [.zPosition(4)]
            
            // Start attributed label
            
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
            
            restaurantPriceAndDistance.attributedText = attributedString
            restaurantPriceAndDistance.heroID = "\(id)_priceDistance"
            restaurantPriceAndDistance.heroModifiers = [.zPosition(4)]
            
            // End attributed label
            
            restaurantStars.contentMode = .right
            restaurantStars.rating = Double(restaurant.rating)
            restaurantStars.settings.emptyBorderWidth = 0
            restaurantStars.settings.emptyBorderColor = UIColor.clear
            restaurantStars.settings.emptyColor = UIColor.lightText
            restaurantStars.settings.updateOnTouch = false
            restaurantStars.settings.starSize = 23
            restaurantStars.heroID = "\(id)_rating"
            restaurantStars.heroModifiers = [.zPosition(2)]
            
            gradient.frame = gradientView.bounds
            gradient.colors = [UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor, UIColor(red: 0, green: 0, blue: 0, alpha: 0.9).cgColor]
            gradient.locations = [0.5, 1.0] // halfway point to endpoint
            gradientView.layer.insertSublayer(gradient, at: 0)
            
            mainBlurView.effect = nil
            
            self.gradientView.layoutSubviews()
            
            gradientView.heroModifiers = [.fade]
            gradientView.layer.cornerRadius = 8
            gradientView.heroID = "\(id)_gradient"
            self.contentView.heroID = "\(id)_view"
            
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
    
}
