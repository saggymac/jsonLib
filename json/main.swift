//
//  main.swift
//  json
//
//  Created by Scott A. Guyer on 8/25/14.
//  Copyright (c) 2014 Scott A. Guyer. All rights reserved.
//

import Foundation
import jsonLib


var filePath: String = String()


let switches = [
	"-f" : {(arg: String) in filePath = arg}
]


let args = Process.arguments
var idx = 1
let max = args.count

while ( idx < max ) {
	let option = args[idx]
	if let handler = switches[ option] {
		idx += 1
		handler( args[idx])
	}
    
    idx += 1
}



let data = NSData( contentsOfFile: filePath)
let p = JSDecoder()	
if let result = p.decode( data) {
    println( "RESULT: \(result)")    
} else {
    println( "no result")
}





