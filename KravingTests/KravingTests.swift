//
//  KravingTests.swift
//  KravingTests
//
//  Created by Omar Abbasi on 2017-07-07.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import XCTest
@testable import Kraving

class KravingTests: XCTestCase {
    
    var restaurant1: Restaurant!
    var restaurant2: Restaurant!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        restaurant1 = Restaurant(name: "My Restaurant", website: "www.google.ca", image: nil, rating: 5, priceRange: "$$$$", phone: "5555555555", id: "restaurant-1", isClosed: false, category: "Afghan", reviewCount: 93, distance: 4, city: "Mississauga", country: "Canada", state: "Ontario", address: "4816 Yorkshire Ave", zipCode: "L4Z4H3", transactions: [""])
        
        restaurant2 = Restaurant(name: "My Restaurant2", website: "www.google.ca", image: nil, rating: 5, priceRange: "$$$", phone: "5555555555", id: "restaurant-2", isClosed: false, category: "Afghan", reviewCount: 93, distance: 7, city: "Mississauga", country: "Canada", state: "Ontario", address: "4816 Yorkshire Ave", zipCode: "L4Z4H3", transactions: [""])
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
        restaurant1 = nil
        restaurant2 = nil
        
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        XCTAssertTrue(restaurant1.distance < restaurant2.distance)
        
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
