// Playground - noun: a place where people can play

import Cocoa
import Foundation

let code = "263A"
let uniStr = "\\u{\(code)}"

let uc = UnicodeScalar.convertFromExtendedGraphemeClusterLiteral( "\u{263A}")
let another = UnicodeScalar.convertFromExtendedGraphemeClusterLiteral( uniStr)
let c = Character( uc)



func unicodeScalarFromString( escapeString: String ) -> UInt32 {
    
    let chars = escapeString.unicodeScalars
    let charCount = countElements( chars)
    
    if charCount < 1 {
        return 0
    }

    var exp = UInt8( charCount - 1)
    var scalar: UInt32 = 0
    
    for idx in chars.startIndex ..< chars.endIndex {
        
        var value: UInt32 = 0
        
        let cs = chars[idx].value
        
        if ( (cs >= 48) && (cs < 58) ) {
            value = UInt32(cs - 48)
        }
        else if ( (cs >= 97) && (cs < 103) ) {
            value = UInt32(cs - 97 + 10)
        }
        else if ( (cs >= 65) && (cs < 71) ) {
            value = UInt32(cs - 65 + 10)
        }
        
        scalar = scalar + ( value * UInt32( powf( 16, Float( exp))))

        --exp
    }
    
    return scalar
}













