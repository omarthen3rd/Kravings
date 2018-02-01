//
//  RestaurantCard.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-12-15.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit
import Cosmos
import PhoneNumberKit
import DeviceKit

class RestaurantCard: UIView {
    
    @IBOutlet var contentView: UIView!
    
    @IBOutlet var featuredImageView: UIImageView!
    @IBOutlet var imageView2: UIImageView!

    @IBOutlet var containerBlurView: VisualEffectView!
    @IBOutlet var restaurantName: UILabel!
    @IBOutlet var restaurantCategory: UILabel!
    @IBOutlet var restaurantPriceAndDistance: UILabel!
    @IBOutlet var restaurantStars: CosmosView!
    
    let defaults = UserDefaults.standard
    
    var view: UIView!
    var smallDevices = [Device]()
    
    var restaurant: Restaurant? {
        
        didSet {
            
            guard let restaurant = restaurant else { return }
            
            smallDevices = [.iPhone5, .iPhone5c, .iPhone5s, .iPhoneSE, .iPodTouch5, .iPodTouch6]
            
            let avgColor = UIColor(averageColorFrom: restaurant.image!)
            let contrastColor = UIColor(contrastingBlackOrWhiteColorOn: avgColor, isFlat: false)
            
            containerBlurView.blurRadius = 25
            containerBlurView.colorTint = avgColor.withAlphaComponent(0.6)
            containerBlurView.colorTintAlpha = 1
            
            featuredImageView.image = restaurant.image
            featuredImageView.clipsToBounds = true
            featuredImageView.contentMode = .scaleAspectFill
            
            imageView2.image = restaurant.image
            imageView2.clipsToBounds = true
            imageView2.contentMode = .scaleAspectFill
            
            restaurantName.text = restaurant.name
            restaurantName.textColor = contrastColor
            
            restaurantCategory.text = restaurant.category
            restaurantCategory.textColor = contrastColor
            
            restaurantPriceAndDistance.textColor = contrastColor
            
            // Start attributed label
            
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
            
            restaurantPriceAndDistance.attributedText = attributedString
            
            // End attributed label
            
            restaurantStars.contentMode = .right
            restaurantStars.rating = Double(restaurant.rating)
            restaurantStars.settings.textColor = contrastColor
            restaurantStars.settings.emptyBorderWidth = 0
            restaurantStars.settings.filledBorderColor = UIColor.clear
            restaurantStars.settings.emptyBorderColor = UIColor.clear
            restaurantStars.settings.filledColor = contrastColor
            restaurantStars.settings.emptyColor = contrastColor.withAlphaComponent(0.3)
            restaurantStars.settings.updateOnTouch = false
            restaurantStars.settings.starSize = 23
            restaurantStars.contentMode = .right
            
            if Device().isOneOf(smallDevices) {
                // reduce font sizes on 4" devices
                restaurantName.font = UIFont.boldSystemFont(ofSize: 22)
                restaurantCategory.font = UIFont.systemFont(ofSize: 17, weight: UIFontWeightLight)
                restaurantPriceAndDistance.font = UIFont.systemFont(ofSize: 18, weight: UIFontWeightLight)
                restaurantStars.settings.starSize = 21
            }
            
            self.layoutSubviews()
            
        }
        
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func loadViewFromNib() -> UIView {
        
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "RestaurantCard1", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        
        return view
        
    }
    
    func commonInit() {
        
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        addSubview(view)
        
        self.clipsToBounds = true
        self.layer.cornerRadius = 15
        
        self.layoutSubviews()
        
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
    
    func checkPrice(_ range: String) -> String {
        
        if range == "" {
            
            return "Price Unavailable"
            
        } else {
            
            return "\(range)"
            
        }
        
    }


}
