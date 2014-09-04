//
//  escapeTests.swift
//  json
//
//  Created by Scott A. Guyer on 9/4/14.
//  Copyright (c) 2014 Scott A. Guyer. All rights reserved.
//

import Cocoa
import XCTest
import jsonLib


class escapeTests: XCTestCase {

    override func setUp() {
        super.setUp()

    }
    
    override func tearDown() {

        super.tearDown()
    }



    
    func testNewlineEscape() {
        
        var result: Any? = nil
        
        if let data = loadResourceFile( "newlineEscape.json") {
            let p = JSDecoder()
            result = p.decode( data)
        }
        
        XCTAssert( result != nil, "result should not be nil")
        XCTAssert( result! is JSArray, "result should be a JSArray")
        
        let arr = result as JSArray
        XCTAssert( arr.count == 1, "result array should have one value")
        
        let valueObj: Any? = arr[0]
        XCTAssert( valueObj != nil, "value should not be nil")
        XCTAssert( valueObj! is String, "value should be a string")

        let str = valueObj as NSString
        XCTAssert( str.containsString( "\n"), "value should contain a newline character")
    }


    func testUnicodeEscape() {
        
        var result: Any? = nil
        
        if let data = loadResourceFile( "unicodeEscape.json") {
            let p = JSDecoder()
            result = p.decode( data)
        }
        
        XCTAssert( result != nil, "result should not be nil")
        XCTAssert( result! is JSArray, "result should be a JSArray")
        
        let arr = result as JSArray
        XCTAssert( arr.count == 1, "result array should have one value")
        
        let valueObj: Any? = arr[0]
        XCTAssert( valueObj != nil, "value should not be nil")
        XCTAssert( valueObj! is String, "value should be a string")
        
        let str = valueObj as NSString
        XCTAssert( str.containsString( "\u{263A}"), "value should contain a happy face")
    }
    
    
    
}
