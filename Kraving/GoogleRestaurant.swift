//
//  GoogleRestaurant.swift
//  Kraving
//
//  Created by Omar Abbasi on 2018-03-06.
//  Copyright © 2018 Omar Abbasi. All rights reserved.
//

import Foundation
import UIKit

class GoogleRestaurant: NSObject, NSCoding {
    
    var placeId: String
    var name: String
    var website: String
    var category: String
    var heroImage: UIImage
    var images: [UIImage]
    var rating: Double
    var priceRange: Int
    var phone: String
    var openNow: Bool
    
    var distance: String
    var duration: String
    var address: String
    
    var timings: [String]
    var types: [String]
    
    struct PropertyKey {
        
        static let idKey = "id"
        static let nameKey = "name"
        static let websiteKey = "website"
        static let categoryKey = "category"
        static let photoKey = "photo"
        static let photosKey = "photos"
        static let ratingKey = "rating"
        static let priceRangeKey = "priceRange"
        static let phoneKey = "phone"
        static let closedKey = "closed"
        
        static let distanceKey = "distance"
        static let durationKey = "duration"
        static let addressKey = "address"
        
        static let timingsKey = "timings"
        static let typesKey = "types"
        
    }
    
    init(placeId: String, name: String, website: String, category: String, heroImage: UIImage, images: [UIImage], rating: Double, priceRange: Int, phone: String, openNow: Bool, distance: String, duration: String, address: String, timings: [String], types: [String]) {
        
        self.placeId = placeId
        self.name = name
        self.website = website
        self.category = category
        self.heroImage = heroImage
        self.images = images
        self.rating = rating
        self.priceRange = priceRange
        self.phone = phone
        self.openNow = openNow
        
        self.distance = distance
        self.duration = duration
        self.address = address
        
        self.timings = timings
        self.types = types
        
        super.init()
        
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        
        let name1 = aDecoder.decodeObject(forKey: PropertyKey.nameKey) as! String
        let website1 = aDecoder.decodeObject(forKey: PropertyKey.websiteKey) as! String
        let category1 = aDecoder.decodeObject(forKey: PropertyKey.categoryKey) as! String
        let heroImage1 = aDecoder.decodeObject(forKey: PropertyKey.photoKey) as! UIImage
        let images1 = aDecoder.decodeObject(forKey: PropertyKey.photosKey) as! [UIImage]
        let rating1  = aDecoder.decodeDouble(forKey: PropertyKey.ratingKey)
        let priceRange1 = aDecoder.decodeInteger(forKey: PropertyKey.priceRangeKey)
        let phone1 = aDecoder.decodeObject(forKey: PropertyKey.phoneKey) as! String
        let id1 = aDecoder.decodeObject(forKey: PropertyKey.idKey) as! String
        let openNow1 = aDecoder.decodeBool(forKey: PropertyKey.closedKey)
        let distance1 = aDecoder.decodeObject(forKey: PropertyKey.distanceKey) as! String
        let duration1 = aDecoder.decodeObject(forKey: PropertyKey.durationKey) as! String
        let address1 = aDecoder.decodeObject(forKey: PropertyKey.addressKey) as! String
        let timings1 = aDecoder.decodeObject(forKey: PropertyKey.timingsKey) as! [String]
        let types1 = aDecoder.decodeObject(forKey: PropertyKey.typesKey) as! [String]
        
        self.init(placeId: id1, name: name1, website: website1, category: category1, heroImage: heroImage1, images: images1, rating: rating1, priceRange: priceRange1, phone: phone1, openNow: openNow1, distance: distance1, duration: duration1, address: address1, timings: timings1, types: types1)
        
    }
    
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(name, forKey: PropertyKey.nameKey)
        aCoder.encode(website, forKey: PropertyKey.websiteKey)
        aCoder.encode(category, forKey: PropertyKey.categoryKey)
        aCoder.encode(heroImage, forKey: PropertyKey.photoKey)
        aCoder.encode(images, forKey: PropertyKey.photosKey)
        aCoder.encode(rating, forKey: PropertyKey.ratingKey)
        aCoder.encode(priceRange, forKey: PropertyKey.priceRangeKey)
        aCoder.encode(phone, forKey: PropertyKey.phoneKey)
        aCoder.encode(placeId, forKey: PropertyKey.idKey)
        aCoder.encode(openNow, forKey: PropertyKey.closedKey)
        
        aCoder.encode(distance, forKey: PropertyKey.distanceKey)
        aCoder.encode(duration, forKey: PropertyKey.durationKey)
        aCoder.encode(address, forKey: PropertyKey.addressKey)
        
        aCoder.encode(timings, forKey: PropertyKey.timingsKey)
        aCoder.encode(types, forKey: PropertyKey.typesKey)
        
    }
    
}
