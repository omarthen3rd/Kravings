//
//  Restaurant.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-07-07.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import Foundation
import UIKit

class Restaurant: NSObject, NSCoding {
    
    var name: String
    var website: String
    var image: UIImage?
    var rating: Int
    var priceRange: String
    var phone: String
    var id: String
    var isClosed: Bool
    var category: String
    var reviewCount: Int
    var distance: Double
    
    var city: String
    var country: String
    var state: String
    var address: String
    var zipCode: String
    
    var transactions: [String]
    
    struct PropertyKey {
        static let nameKey = "name"
        static let websiteKey = "website"
        static let photoKey = "photo"
        static let ratingKey = "rating"
        static let priceRangeKey = "priceRange"
        static let phoneKey = "phone"
        static let idKey = "id"
        static let closedKey = "closed"
        static let categoryKey = "category"
        static let reviewCountKey = "reviewCount"
        static let distanceKey = "distance"
        static let cityKey = "city"
        static let countryKey = "country"
        static let stateKey = "state"
        static let addressKey = "address"
        static let zipcodeKey = "zipCode"
        static let transactionsKey = "transactions"
    }
    
    init(name: String, website: String, image: UIImage?, rating: Int, priceRange: String, phone: String, id: String, isClosed: Bool, category: String, reviewCount: Int, distance: Double, city: String, country: String, state: String, address: String, zipCode: String, transactions: [String]) {
        
        self.name = name
        self.website = website
        self.image = image
        self.rating = rating
        self.priceRange = priceRange
        self.phone = phone
        self.id = id
        self.isClosed = isClosed
        self.category = category
        self.reviewCount = reviewCount
        self.distance = distance
        self.city = city
        self.country = country
        self.state = state
        self.address = address
        self.zipCode = zipCode
        self.transactions = transactions
        
        super.init()
        
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        
        let name1 = aDecoder.decodeObject(forKey: PropertyKey.nameKey) as! String
        let website1 = aDecoder.decodeObject(forKey: PropertyKey.websiteKey) as! String
        let image1 = aDecoder.decodeObject(forKey: PropertyKey.photoKey) as? UIImage
        let rating1  = aDecoder.decodeInteger(forKey: PropertyKey.ratingKey)
        let priceRange1 = aDecoder.decodeObject(forKey: PropertyKey.priceRangeKey) as! String
        let phone1 = aDecoder.decodeObject(forKey: PropertyKey.phoneKey) as! String
        let id1 = aDecoder.decodeObject(forKey: PropertyKey.idKey) as! String
        let isClosed1 = aDecoder.decodeBool(forKey: PropertyKey.closedKey)
        let category1 = aDecoder.decodeObject(forKey: PropertyKey.categoryKey) as! String
        let reviewCount1 = aDecoder.decodeInteger(forKey: PropertyKey.reviewCountKey)
        let distance1 = aDecoder.decodeDouble(forKey: PropertyKey.distanceKey)
        let city1 = aDecoder.decodeObject(forKey: PropertyKey.cityKey) as! String
        let country1 = aDecoder.decodeObject(forKey: PropertyKey.countryKey) as! String
        let state1 = aDecoder.decodeObject(forKey: PropertyKey.stateKey) as! String
        let address1 = aDecoder.decodeObject(forKey: PropertyKey.addressKey) as! String
        let zipCode1 = aDecoder.decodeObject(forKey: PropertyKey.zipcodeKey) as! String
        let transactions1 = aDecoder.decodeObject(forKey: PropertyKey.transactionsKey) as! [String]
        
        self.init(name: name1, website: website1, image: image1, rating: rating1, priceRange: priceRange1, phone: phone1, id: id1, isClosed: isClosed1, category: category1, reviewCount: reviewCount1, distance: distance1, city: city1, country: country1, state: state1, address: address1, zipCode: zipCode1, transactions: transactions1)
        
    }
    
    deinit {
        print("")
    }
    
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(name, forKey: PropertyKey.nameKey)
        aCoder.encode(website, forKey: PropertyKey.websiteKey)
        aCoder.encode(image, forKey: PropertyKey.photoKey)
        aCoder.encode(rating, forKey: PropertyKey.ratingKey)
        aCoder.encode(priceRange, forKey: PropertyKey.priceRangeKey)
        aCoder.encode(phone, forKey: PropertyKey.phoneKey)
        aCoder.encode(id, forKey: PropertyKey.idKey)
        aCoder.encode(isClosed, forKey: PropertyKey.closedKey)
        aCoder.encode(category, forKey: PropertyKey.categoryKey)
        aCoder.encode(reviewCount, forKey: PropertyKey.reviewCountKey)
        aCoder.encode(distance, forKey: PropertyKey.distanceKey)
        aCoder.encode(city, forKey: PropertyKey.cityKey)
        aCoder.encode(country, forKey: PropertyKey.countryKey)
        aCoder.encode(state, forKey: PropertyKey.stateKey)
        aCoder.encode(address, forKey: PropertyKey.addressKey)
        aCoder.encode(zipCode, forKey: PropertyKey.zipcodeKey)
        aCoder.encode(transactions, forKey: PropertyKey.transactionsKey)
        
    }
    
}

class RestaurantHours: NSObject, NSCoding {
    
    var day: String
    var isOvernight: Bool
    var startTime: String
    var endTime: String
    
    init(day: String, isOvernight: Bool, startTime: String, endTime: String) {
        
        self.day = day
        self.isOvernight = isOvernight
        self.startTime = startTime
        self.endTime = endTime
        
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        let day = aDecoder.decodeObject(forKey: "day") as! String
        let isOvernight = aDecoder.decodeBool(forKey: "isOvernight")
        let startTime = aDecoder.decodeObject(forKey: "startTime") as! String
        let endTime = aDecoder.decodeObject(forKey: "endTime") as! String
        
        self.init(day: day, isOvernight: isOvernight, startTime: startTime, endTime: endTime)
        
    }
    
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(day, forKey: "day")
        aCoder.encode(isOvernight, forKey: "isOvernight")
        aCoder.encode(startTime, forKey: "startTime")
        aCoder.encode(endTime, forKey: "endTime")
        
    }
    
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
