//
//  jsonLibTests.swift
//  jsonLibTests
//
//  Created by Scott A. Guyer on 8/27/14.
//  Copyright (c) 2014 Scott A. Guyer. All rights reserved.
//

import Cocoa
import XCTest
import jsonLib


class jsonLibTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSimpleObject() {
        var result: Any? = nil
        
        if let data = loadResourceFile( "simpleObject.json") {
            let p = JSDecoder()
            result = p.decode( data)
        }
        
        XCTAssert( result != nil, "result should not be nil")
        XCTAssert( result! is JSObject, "result should be a JSObject")
    }
    
    
    
    func testSimpleArray() {
        
        var result: Any? = nil
        
        if let data = loadResourceFile( "simpleArray.json") {
            let p = JSDecoder()
            result = p.decode( data)
            println( "RESULT: \(result)")
        }
        
        XCTAssert( result != nil, "result should not be nil")
        XCTAssert( result! is JSArray, "result should be a JSArray")
    }
    
    

    func testNullLiteral() {
        
        var result: Any? = nil
        
        if let data = loadResourceFile( "null.json") {
            let p = JSDecoder()
            result = p.decode( data)
        }

        XCTAssert( result != nil, "result should not be nil")
        XCTAssert( result! is JSArray, "result should be a JSArray")
        
        let arr = result! as JSArray
        XCTAssert( arr.count == 1, "result array should have 1 elmenet")
        
        XCTAssert( arr[0] == nil, "array should contain a nil")
    }
    
    
    func testTrueLiteral() {
        var result: Any? = nil
        
        if let data = loadResourceFile( "true.json") {
            let p = JSDecoder()
            result = p.decode( data)
        }
        
        XCTAssert( result != nil, "result should not be nil")
        XCTAssert( result! is JSArray, "result should be a JSArray")
        
        let arr = result! as JSArray
        
        XCTAssert( arr.count == 1, "result array should have 1 elmenet")
        
        let val = arr[0]
        XCTAssert( val != nil, "element should not be nil")
        XCTAssert( val! is Bool, "element should be boolean")

        let t = val! as Bool
        XCTAssert( t, "element should be true")
    }
    
    
    func testFalseLiteral() {
        var result: Any? = nil
        
        if let data = loadResourceFile( "false.json") {
            let p = JSDecoder()
            result = p.decode( data)
        }
        
        XCTAssert( result != nil, "result should not be nil")
        XCTAssert( result! is JSArray, "result should be a JSArray")
        
        let arr = result! as JSArray
        
        XCTAssert( arr.count == 1, "result array should have 1 elmenet")
        
        let val = arr[0]
        XCTAssert( val != nil, "element should not be nil")
        XCTAssert( val! is Bool, "element should be boolean")
        
        let t = val! as Bool
        XCTAssert( !t, "element should be false")
    }
    
    
    func testNestedArray() {
        var result: Any? = nil
        
        if let data = loadResourceFile( "nestedArray.json") {
            let p = JSDecoder()
            result = p.decode( data)
            println( "RESULT: \(result)")
        }
        
        XCTAssert( result != nil, "result should not be nil")
        XCTAssert( result! is JSObject, "result should be a JSObject")
        
        let jsObj = result! as JSObject
        
        let arrValue = jsObj[ "test"]
        XCTAssert( arrValue != nil, "value for test field should not be nil")
        XCTAssert( arrValue! is JSArray, "value for test field should be JSArray")
    }
    
    
    func testNestedObject() {
        var result: Any? = nil
        
        if let data = loadResourceFile( "nestedObject.json") {
            let p = JSDecoder()
            result = p.decode( data)
            println( "RESULT: \(result)")
        }
        
        XCTAssert( result != nil, "result should not be nil")
        XCTAssert( result! is JSObject, "result should be a JSObject")
        
        let jsObj = result! as JSObject
        
        let objValue = jsObj[ "test"]
        XCTAssert( objValue != nil, "value for test field should not be nil")
        XCTAssert( objValue! is JSObject, "value for test field should be JSObject")
        
    }

    
}
