//
//  Restaurant.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-07-07.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import Foundation
import UIKit

struct RestaurantCategory {
    
    var title: String
    var alias: String
    
}

struct RestaurantReviews {
    
    var name: String
    var rating: Int
    var imageURL: String
    var reviewText: String
    var reviewTime: String
    
}

enum Attributes {
    
    case bold
    case color
    
}

enum LoadingOpener {
    
    case unhide
    case hide
    
}
