//
//  Restaurant.swift
//  Kraving
//
//  Created by Omar Abbasi on 2017-07-07.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import Foundation

class Restaurant: NSObject, NSCoding {
    
    var name: String
    var website: String
    var imageURL: String
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
    
    init(name: String, website: String, imageURL: String, rating: Int, priceRange: String, phone: String, id: String, isClosed: Bool, category: String, reviewCount: Int, distance: Double, city: String, country: String, state: String, address: String, zipCode: String, transactions: [String]) {
        
        self.name = name
        self.website = website
        self.imageURL = imageURL
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
        
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        
        let name = aDecoder.decodeObject(forKey: "name") as! String
        let website = aDecoder.decodeObject(forKey: "website") as! String
        let imageURL = aDecoder.decodeObject(forKey: "imageURL") as! String
        let rating  = aDecoder.decodeInteger(forKey: "rating")
        let priceRange = aDecoder.decodeObject(forKey: "priceRange") as! String
        let phone = aDecoder.decodeObject(forKey: "phone") as! String
        let id = aDecoder.decodeObject(forKey: "id") as! String
        let isClosed = aDecoder.decodeBool(forKey: "isClosed")
        let category = aDecoder.decodeObject(forKey: "category") as! String
        let reviewCount = aDecoder.decodeInteger(forKey: "reviewCount")
        let distance = aDecoder.decodeDouble(forKey: "distance")
        let city = aDecoder.decodeObject(forKey: "city") as! String
        let country = aDecoder.decodeObject(forKey: "country") as! String
        let state = aDecoder.decodeObject(forKey: "state") as! String
        let address = aDecoder.decodeObject(forKey: "address") as! String
        let zipCode = aDecoder.decodeObject(forKey: "zipCode") as! String
        let transactions = aDecoder.decodeObject(forKey: "transactions") as! [String]
        
        self.init(name: name, website: website, imageURL: imageURL, rating: rating, priceRange: priceRange, phone: phone, id: id, isClosed: isClosed, category: category, reviewCount: reviewCount, distance: distance, city: city, country: country, state: state, address: address, zipCode: zipCode, transactions: transactions)
        
    }
    
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(name, forKey: "name")
        aCoder.encode(website, forKey: "website")
        aCoder.encode(imageURL, forKey: "imageURL")
        aCoder.encode(rating, forKey: "rating")
        aCoder.encode(priceRange, forKey: "priceRange")
        aCoder.encode(phone, forKey: "phone")
        aCoder.encode(id, forKey: "id")
        aCoder.encode(isClosed, forKey: "isClosed")
        aCoder.encode(category, forKey: "category")
        aCoder.encode(reviewCount, forKey: "reviewCount")
        aCoder.encode(distance, forKey: "distance")
        aCoder.encode(city, forKey: "city")
        aCoder.encode(country, forKey: "country")
        aCoder.encode(state, forKey: "state")
        aCoder.encode(address, forKey: "address")
        aCoder.encode(zipCode, forKey: "zipCode")
        aCoder.encode(transactions, forKey: "transactions")
        
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
