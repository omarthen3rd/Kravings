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

@objc protocol CardDelegate {
    
    @objc optional func cardDidTap(card: RestaurantCardView)
    @objc optional func cardWillShowDetailView(card: RestaurantCardView)
    @objc optional func cardDidShowDetailView(card: RestaurantCardView)
    @objc optional func cardWillCloseDetailView(card: RestaurantCardView)
    @objc optional func cardDidCloseDetailView(card: RestaurantCardView)
    @objc optional func cardIsShowingDetail(card: RestaurantCardView)
    @objc optional func cardIsHidingDetail(card: RestaurantCardView)
    @objc optional func cardDetailIsScrolling(card: RestaurantCardView)
}

class RestaurantCardView: UIView, CardDelegate {

    let defaults = UserDefaults.standard
    
    var containerBlurView = VisualEffectView()
    var restaurantName = UILabel()
    var restaurantCategory = UILabel()
    var restaurantStars = CosmosView()
    var restaurantPriceDistance = UILabel()
    
    var thumbsUpDownView = UIView()
    var thumbsUpDownImage = UIImageView()
    
    var smallDevices = [Device]()
    var cornerRadius = Float()
    var originalFrame = CGRect.zero
    
    var superVC: UIViewController?
    var stuffContainer = UIView()
    var bgImageView = UIImageView()
    var isPresenting = false
    
    public var delegate: CardDelegate?
    fileprivate var detailVC = DetailViewController()
    
    fileprivate var tap = UITapGestureRecognizer()
    
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
        
        originalFrame = self.frame
        
        guard let restaurant = restaurant else { return }
        
        cornerRadius = defaults.float(forKey: "cornerRadius")
        
        self.addGestureRecognizer(tap)
        tap.delegate = self
        tap.cancelsTouchesInView = false
        
        detailVC.transitioningDelegate = self
        
        let width = self.bounds.width
        let height = self.bounds.height
        
        self.layer.cornerRadius = CGFloat(cornerRadius)
        
        stuffContainer.layer.cornerRadius = self.layer.cornerRadius
        stuffContainer.clipsToBounds = true
        stuffContainer.frame.origin = bounds.origin
        stuffContainer.frame.size = CGSize(width: bounds.width, height: bounds.height)
        
        stuffContainer.clipsToBounds = true
        stuffContainer.backgroundColor = .clear
        
        smallDevices = [.iPhone5, .iPhone5c, .iPhone5s, .iPhoneSE, .iPodTouch5, .iPodTouch6]
        let deviceIsSmall = Device().isOneOf(smallDevices)
        
        let avgColor = UIColor(averageColorFrom: restaurant.image!)
        let contrastColor = UIColor(contrastingBlackOrWhiteColorOn: avgColor, isFlat: false)
        
        bgImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        bgImageView.image = restaurant.image
        bgImageView.clipsToBounds = true
        bgImageView.contentMode = .scaleAspectFill
        stuffContainer.addSubview(bgImageView)
        
        let containerHeight: CGFloat = deviceIsSmall ? 106 : 110
        
        containerBlurView = VisualEffectView(frame: CGRect(x: 0, y: height - containerHeight, width: width, height: containerHeight))
        containerBlurView.blurRadius = 20
        containerBlurView.colorTint = avgColor.withAlphaComponent(0.6)
        containerBlurView.colorTintAlpha = 1
        
        restaurantName = UILabel(frame: CGRect(x: 10, y: 10, width: width - 20, height: 32))
        restaurantName.font = UIFont.boldSystemFont(ofSize: deviceIsSmall ? 23 : 26)
        restaurantName.textColor = contrastColor
        restaurantName.text = restaurant.name
        restaurantName.lineBreakMode = .byTruncatingTail
        
        let starsWidth: CGFloat = deviceIsSmall ? 119 : 134
        
        // 30 is spacing between the category/stars as they are side by side ------------------------------>
        restaurantCategory = UILabel(frame: CGRect(x: 10, y: restaurantName.totalY + 4, width: width - (30 + starsWidth), height: 23))
        restaurantCategory.font = UIFont.systemFont(ofSize: deviceIsSmall ? 17 : 19, weight: UIFontWeightLight)
        restaurantCategory.textColor = contrastColor
        restaurantCategory.text = restaurant.category
        restaurantCategory.lineBreakMode = .byTruncatingTail
        
        restaurantStars = CosmosView(frame: CGRect(x: restaurantCategory.totalX + 10, y: restaurantName.totalY + 4, width: starsWidth, height: deviceIsSmall ? 21 : 23))
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
        
        restaurantPriceDistance = UILabel(frame: CGRect(x: 10, y: restaurantCategory.totalY + 4, width: width - 20, height: deviceIsSmall ? 21 : 23))
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
        stuffContainer.addSubview(containerBlurView)
        
        thumbsUpDownView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        thumbsUpDownView.alpha = 0
        
        thumbsUpDownImage = UIImageView(frame: CGRect(x: 0, y: 0, width: width - 160, height: width - 160))
        thumbsUpDownImage.center = thumbsUpDownView.center
        thumbsUpDownImage.tintColor = UIColor.flatWhite

        
        thumbsUpDownView.addSubview(thumbsUpDownImage)
        thumbsUpDownView.layoutSubviews()
        stuffContainer.addSubview(thumbsUpDownView)
        stuffContainer.bringSubview(toFront: thumbsUpDownView)
        
        addSubview(stuffContainer)
        
        self.backgroundColor = .clear
        
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
    
    public func shouldPresent( _ contentViewController: UIViewController?, from superVC: UIViewController?, fullscreen: Bool = false) {
        if let content = contentViewController {
            self.superVC = superVC
            detailVC.addChildViewController(content)
            detailVC.detailView = content.view
            detailVC.card = self
            detailVC.delegate = self.delegate
            detailVC.isFullscreen = fullscreen
        }
    }
    
    // MARK: - Layout
    
    func layout(animating: Bool = true) {
        
        let framer = stuffContainer.frame
        
        let width = framer.width
        let height = framer.height
        
        print(width)
        
        smallDevices = [.iPhone5, .iPhone5c, .iPhone5s, .iPhoneSE, .iPodTouch5, .iPodTouch6]
        let deviceIsSmall = Device().isOneOf(smallDevices)

        bgImageView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        
        let containerHeight: CGFloat = deviceIsSmall ? 106 : 110
        containerBlurView.frame = CGRect(x: 0, y: height - containerHeight, width: width, height: containerHeight)
        
        restaurantName.frame = CGRect(x: 10, y: 10, width: width - 20, height: 32)
        
        let starsWidth: CGFloat = deviceIsSmall ? 119 : 134
        
        // 30 is spacing between the category/stars as they are side by side ------------------------------>
        restaurantCategory.frame = CGRect(x: 10, y: restaurantName.totalY + 4, width: width - (30 + starsWidth), height: 23)
        
        restaurantStars.frame = CGRect(x: restaurantCategory.totalX + 10, y: restaurantName.totalY + 4, width: starsWidth, height: deviceIsSmall ? 21 : 23)
        
        restaurantPriceDistance.frame = CGRect(x: 10, y: restaurantCategory.totalY + 4, width: width - 20, height: deviceIsSmall ? 21 : 23)
        
        thumbsUpDownView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        thumbsUpDownImage.frame = CGRect(x: 0, y: 0, width: width - 160, height: width - 160)
        
    }
    
    @objc func cardTapped() {
        self.delegate?.cardDidTap?(card: self)
        
        if let vc = superVC {
            vc.present(self.detailVC, animated: true, completion: nil)
        } else {
            resetAnimated()
        }
        
    }
    
    func pushBackAnimated() {
        
        UIView.animate(withDuration: 0.2, animations: { self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95) })
    }
    
    func resetAnimated() {
        
        UIView.animate(withDuration: 0.2, animations: { self.transform = CGAffineTransform.identity })
    }

}

extension RestaurantCardView: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return Animator(presenting: true, from: self)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return Animator(presenting: false, from: self)
    }
    
}

extension RestaurantCardView: UIGestureRecognizerDelegate {
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        cardTapped()
    }
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
         if let superview = self.superview {
            originalFrame = superview.convert(self.frame, to: nil)
         }
         pushBackAnimated()
    }
}
