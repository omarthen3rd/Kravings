//
//  RestaurantCardView.swift
//  Kraving
//
//  Created by Omar Abbasi on 2018-02-11.
//  Copyright © 2018 Omar Abbasi. All rights reserved.
//

import UIKit
import DeviceKit
import PhoneNumberKit
import Cosmos

extension UILabel {
    
    var height: CGFloat {
        
        return self.bounds.size.height
        
    }
    
    var y: CGFloat {
        
        return self.bounds.origin.y
        
    }
    
    var x: CGFloat {
        
        return self.bounds.origin.x
        
    }
    
    var totalY: CGFloat {
        
        return (self.frame.origin.y + self.bounds.size.height)
        
    }
    
    var totalX: CGFloat {
        
        return (self.bounds.origin.y + self.bounds.size.width)
        
    }
    
}

class RestaurantCardView: UIView {

    let defaults = UserDefaults.standard
    var thumbsUpDownVisual = VisualEffectView()
    var thumbsUpDownImage = UIImageView()
    var smallDevices = [Device]()
    
    var restaurant: Restaurant? {
        
        didSet {
            
            commonInit()
            
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        
        guard let restaurant = restaurant else { return }
        
        let width = self.bounds.size.width
        let height = self.bounds.size.height
        
        smallDevices = [.iPhone5, .iPhone5c, .iPhone5s, .iPhoneSE, .iPodTouch5, .iPodTouch6]
        let deviceIsSmall = Device().isOneOf(smallDevices)
        
        let avgColor = UIColor(averageColorFrom: restaurant.image!)
        let contrastColor = UIColor(contrastingBlackOrWhiteColorOn: avgColor, isFlat: false)
        
        let bgImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        bgImageView.image = restaurant.image
        bgImageView.clipsToBounds = true
        bgImageView.contentMode = .scaleAspectFill
        self.addSubview(bgImageView)
        
        let containerHeight: CGFloat = deviceIsSmall ? 106 : 110
        
        let containerBlurView = VisualEffectView(frame: CGRect(x: 0, y: height - containerHeight, width: width, height: containerHeight))
        containerBlurView.blurRadius = 20
        containerBlurView.colorTint = avgColor.withAlphaComponent(0.6)
        containerBlurView.colorTintAlpha = 1
        
        let restaurantName = UILabel(frame: CGRect(x: 10, y: 10, width: width - 20, height: 32))
        restaurantName.font = UIFont.boldSystemFont(ofSize: deviceIsSmall ? 23 : 26)
        restaurantName.textColor = contrastColor
        restaurantName.text = restaurant.name
        restaurantName.lineBreakMode = .byTruncatingTail
        
        let starsWidth: CGFloat = deviceIsSmall ? 119 : 134
        
        // 30 is spacing between the category/stars as they are side by side ------------------------------>
        let restaurantCategory = UILabel(frame: CGRect(x: 10, y: restaurantName.totalY + 4, width: width - (30 + starsWidth), height: 23))
        restaurantCategory.font = UIFont.systemFont(ofSize: deviceIsSmall ? 17 : 19, weight: UIFontWeightLight)
        restaurantCategory.textColor = contrastColor
        restaurantCategory.text = restaurant.category
        restaurantCategory.lineBreakMode = .byTruncatingTail
        
        let restaurantStars = CosmosView(frame: CGRect(x: restaurantCategory.totalX + 10, y: restaurantName.totalY + 4, width: starsWidth, height: deviceIsSmall ? 21 : 23))
        restaurantStars.contentMode = .right
        restaurantStars.rating = Double(restaurant.rating)
        restaurantStars.settings.textColor = contrastColor
        restaurantStars.settings.emptyBorderWidth = 0
        restaurantStars.settings.filledBorderColor = UIColor.clear
        restaurantStars.settings.emptyBorderColor = UIColor.clear
        restaurantStars.settings.filledColor = contrastColor
        restaurantStars.settings.emptyColor = contrastColor.withAlphaComponent(0.3)
        restaurantStars.settings.updateOnTouch = false
        restaurantStars.settings.starSize = deviceIsSmall ? 21 : 23
        restaurantStars.contentMode = .right
        
        print("restaurantCategory.totalY: \(restaurantCategory.totalY)")
        let restaurantPriceDistance = UILabel(frame: CGRect(x: 10, y: restaurantCategory.totalY + 4, width: width - 20, height: deviceIsSmall ? 21 : 23))
        restaurantPriceDistance.font = UIFont.systemFont(ofSize: deviceIsSmall ? 17 : 19, weight: UIFontWeightLight)
        restaurantPriceDistance.textColor = contrastColor
        
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
        
        restaurantPriceDistance.attributedText = attributedString
        
        // End attributed label
        
        containerBlurView.contentView.addSubview(restaurantName)
        containerBlurView.contentView.addSubview(restaurantCategory)
        containerBlurView.contentView.addSubview(restaurantStars)
        containerBlurView.contentView.addSubview(restaurantPriceDistance)
        addSubview(containerBlurView)
        
        thumbsUpDownVisual = VisualEffectView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        thumbsUpDownVisual.blurRadius = 20
        thumbsUpDownVisual.colorTintAlpha = 0.4
        thumbsUpDownVisual.scale = 1
        thumbsUpDownVisual.alpha = 0
        
        thumbsUpDownImage = UIImageView(frame: CGRect(x: thumbsUpDownVisual.center.x, y: thumbsUpDownVisual.center.y, width: width - 160, height: width - 160))
        
        thumbsUpDownVisual.contentView.addSubview(thumbsUpDownImage)
        thumbsUpDownVisual.layoutSubviews()
        addSubview(thumbsUpDownVisual)
        bringSubview(toFront: thumbsUpDownVisual)
        
        self.layoutSubviews()
        
        self.layer.cornerRadius = 15
        self.clipsToBounds = true
        
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
