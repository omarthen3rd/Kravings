//
//  KravingUITests.swift
//  KravingUITests
//
//  Created by Omar Abbasi on 2017-07-07.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import XCTest

class KravingUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        
        let app = XCUIApplication()
        app.buttons["favourites"].tap()
        
        let rating24VotesElement = app.tables.otherElements["Rating 24 VOTES"]
        rating24VotesElement.tap()
        rating24VotesElement.swipeUp()
        
        let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element(boundBy: 1)
        element.tables.staticTexts["ADDRESS"].swipeUp()
        
        let reviewsButton = element.buttons["reviews"]
        reviewsButton.tap()
        reviewsButton.tap()
        app.navigationBars["Kraving.FavouritesDetailContainerView"].buttons["Favourites"].tap()
        app.navigationBars["Favourites"].buttons["Done"].tap()
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
}
