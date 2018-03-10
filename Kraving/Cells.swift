//
//  Cells.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-10-14.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit
import Cosmos
import ChameleonFramework

// MARK: - Table View Cells

class TimingsCell: UITableViewCell {
    
    @IBOutlet var day: UILabel!
    
}

class CategoryTableViewCell: UITableViewCell {
    
    @IBOutlet var categoryLabel: UILabel!
    
    override var isHighlighted: Bool {
        
        get {
            return super.isHighlighted
        }
        set {
            if newValue {
                // print("selected")
            } else {
                // print("no")
            }
            super.isHighlighted = newValue
        }
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.isHighlighted = false
        
        let newSelectionView = UIView(frame: self.bounds)
        newSelectionView.backgroundColor = UIColor.darkGray.darken(byPercentage: 0.2)
        
        self.selectedBackgroundView = newSelectionView
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        self.isHighlighted = selected
        
    }
    
}

class ReviewsCell: UITableViewCell {
    
    @IBOutlet var name: UILabel!
    @IBOutlet var rating: UILabel!
    @IBOutlet var timeOfReview: UILabel!
    @IBOutlet var textReview: UILabel!
    @IBOutlet var userImage: UIImageView!
    
}

// MARK: - Collection View Cells

class PhotoCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    
}

class FavouritesCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var restaurantImage: UIImageView!
    @IBOutlet var restaurantTitle: UILabel!
    @IBOutlet var restaurantStars: CosmosView!
    @IBOutlet var checkMarkView: UIView!
    @IBOutlet var checkMarkImage: UIImageView!
    
    var isChecked = false {
        
        didSet {
            
            if isChecked == true {
                print("isChecked")
                DispatchQueue.main.async {
                    self.checkMarkView.alpha = 0
                }
            } else {
                DispatchQueue.main.async {
                    self.checkMarkView.alpha = 0
                }
            }
            
        }
        
    }
    var restaurant: GoogleRestaurant? {
        
        didSet {
            
            guard let favourite = restaurant else { return }
            guard let restaurantTitle = restaurantTitle else { return }
            guard let restaurantImage = restaurantImage else { return }
            guard let restaurantStars = restaurantStars else { return }
            guard let checkMarkView = checkMarkView else { return }
            guard let checkMarkImage = checkMarkImage else { return }
            
            restaurantTitle.text = favourite.name
            restaurantStars.rating = Double(favourite.rating)
            // restaurantStars.text = "\(favourite.reviewCount)" + " VOTES"
            
            let img = favourite.heroImage
            
            let avgColor = UIColor(averageColorFrom: img)
            let contrastColor = UIColor(contrastingBlackOrWhiteColorOn: avgColor, isFlat: true)
            
            restaurantTitle.textColor = contrastColor
            restaurantStars.settings.textColor = contrastColor
            restaurantStars.settings.filledColor = contrastColor
            restaurantStars.settings.emptyColor = contrastColor.withAlphaComponent(0.3)
            restaurantStars.settings.emptyBorderColor = UIColor.clear
            restaurantStars.settings.filledBorderColor = UIColor.clear
            
            restaurantImage.image = img
            restaurantImage.clipsToBounds = true
            restaurantImage.layer.cornerRadius = 5
            
            // checkMarkView.alpha = 0
            checkMarkView.backgroundColor = .flatRed
            checkMarkImage.image = #imageLiteral(resourceName: "checkmark").withRenderingMode(.alwaysTemplate)
            checkMarkImage.tintColor = UIColor.flatWhite
            
            backgroundColor = avgColor
            layer.cornerRadius = 12
            clipsToBounds = true
            
        }
        
    }
    
}
