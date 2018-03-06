//
//  GoogleRestaurant.swift
//  Kraving
//
//  Created by Omar Abbasi on 2018-03-06.
//  Copyright © 2018 Omar Abbasi. All rights reserved.
//

import Foundation
import UIKit

struct GoogleRestaurant {
    
    var placeId: String
    var name: String
    var website: String
    var heroImage: UIImage
    var images: [UIImage]
    var rating: Double
    var priceRange: String
    var phone: String
    var openNow: Bool
    
    var distance: Double
    var address: String
    
    var timings: [String]
    var types: [String]
    
}
