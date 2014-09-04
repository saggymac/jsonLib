//
//  json.swift
//  json
//
//  Created by Scott A. Guyer on 8/25/14.
//  Copyright (c) 2014 Scott A. Guyer. All rights reserved.
//

import Foundation


class JSScanner {
    var idx: String.Index
    let str: String
    
    init( _ chunk: String ) {
        str = chunk
        idx = str.startIndex
    }
    

    // It is up to the caller to make sure they call canScan() before
    // they call readCharacter() | peekCharacter(). It might hurt otherwise.
    //
    func canScan() -> Bool {
        return idx < str.endIndex
    }
    
    func readCharacter() -> Character {
        let chr = str[idx]
        idx = idx.successor()
        return chr
    }
    
    func peekCharacter() -> Character {
        return str[idx]
    }
    
    func index() -> String.Index {
        return idx
    }
}


extension Character
{
    func unicodeScalarCodePoint() -> UInt32
    {
        let characterString = String(self)
        let scalars = characterString.unicodeScalars

        return scalars[scalars.startIndex].value
    }
}


enum JSStateType: String, Printable {
    case Init = "init"
    case Key = "key"
    case Value = "value"
    case JSString = "string"
    case CharacterEscape = "charescape"
    case Unicode = "unicode"
    case JSNumber = "number"
    case JSBool = "bool"
    case JSLiteral = "literal"
    case Colon = "colon"
    case Comma = "comma"
    case Property = "prop"
    case JSObject = "object"
    case JSArray = "array"
    case Final = "final"
    
    var description : String {
        get {
            return self.toRaw()
        }
    }
}


class JSState: Printable {
    var state: JSStateType
    var str: String?
    var accum: Any?      // Any of the value types: object, array, string, number
    var handler: JSHandler
    var array: JSArray?  // TODO: I had to add this because there were problems append()'ing to an array when stored in Accum 
    
    init( state aState: JSStateType, handler h: JSHandler ) {
        state = aState
        str = nil
        accum = nil
        handler = h
        array = nil
    }

    var description : String {
        get {
            return state.toRaw() + ", str: " + (str != nil ? str! : "nil") 
        }
    }  

    func append( char: Character ) {
        str?.append( char)
    }
}



typealias JSHandler = (JSContext, Character) -> Bool
public typealias JSObject = [String : Any?]
public typealias JSArray = Array<Any?>

//
// This is the state for the parser
// It keeps a parser state, a string accumulator, and a value accumulator
//
class JSContext {
    var stack: Array<JSState>
    
    init( state: JSState ) {
        stack = [ state ]
    }
    
    func push( state: JSState ) {
        println( "PUSH: \(state)")
        stack.append( state)
    }
    
    func pop() -> JSState? {
        if !stack.isEmpty {
            let old = stack.removeLast()
            println( "POP: \(old)")
            return old
        } else {
            return nil
        }
    }
    
    func top() -> JSState? {
        if ( stack.isEmpty ) {
            return nil
        } else {
            return stack.last
        }
    }
}




public class JSDecoder {

    lazy var numberFormatter: NSNumberFormatter = NSNumberFormatter()


    public init () {}
    
    
    func whitespace( char: Character ) -> Bool {

        // NOTE: I found the compiler would infloop if I tried to comma sep
        // the case values
        // Also, this is kinda the suck. But there is no nice set representation that
        // I have seen for swift yet. Might have to build one.

        switch char {
        case " ":
            return true
        case "\t":
            return true
        case "\n":
            return true
        case "\r":
            return true
        default:
            return false
        }


        // TODO: spec defines more valid whitespace chars ... need to add them
    }


    func isnumber( char: Character ) -> Bool {
        let codepoint = char.unicodeScalarCodePoint()
        if ( codepoint >= 48 && codepoint < 58 ) {
            return true
        } else {
            return false
        }
    }


    func ishex( char: Character ) -> Bool {
        // This code is duplicated a little bit because I didn't
        // want to incur the expense of recomputing the unicodeScalarCodePoint()
        // again by just reusing isnumber()
        let codepoint = char.unicodeScalarCodePoint()
        if ( codepoint >= 48 && codepoint < 58 ) {
            return true
        }
        else if ( (codepoint >= 65) && (codepoint < 71) ) {
            return true
        }
        else if ( (codepoint >= 97) && (codepoint < 103) ) {
            return true
        } 
        else {
            return false
        }
    }


    func endValue( context: JSContext ) -> Bool {

        // We just finished a string, number, or other value type
        // Now we roll up the data

        var valueContext = context.pop()
        
        if var top = context.top() {
            
            switch top.state {
            case .JSObject:
                if var dict = top.accum as? JSObject {
                    if let key = top.str {
                        dict[ key] = valueContext?.accum
                        top.accum = dict
                        top.str = nil
                        var newState = JSState( state: .Comma, handler:commaHandler)
                        context.push( newState)
                        return true
                    }                    
                }                

            case .JSArray:

                top.array?.append( valueContext?.accum)
                var newState = JSState( state: .Comma, handler:commaHandler)
                context.push( newState)                                      
                return true


            default:
                return false
            }

        }
        
        return false
    }
    


    func endContainer( context: JSContext ) -> Bool {

        var objContext = context.pop()!

        if var top = context.top() {
            switch top.state {

            case .JSObject:
                if var obj = top.accum as? JSObject {
                    if let key = top.str {
                        
                        obj[ key] = ( (objContext.array != nil) ? objContext.array : objContext.accum ) as Any?
                        top.str = nil
                        top.accum = obj
                        var newState = JSState( state: .Comma, handler:commaHandler)
                        context.push( newState)
                        return true
                    }
                }
           

            case .JSArray:
                if (objContext.array != nil) || (objContext.accum != nil) {
                    top.array?.append( ( (objContext.array != nil) ? objContext.array : objContext.accum ))
                }
                
                return endContainer( context)


            case .Value:
                context.pop()
                context.push( objContext)
                return endContainer( context)


            case .Init:
                top.array = objContext.array
                top.accum = objContext.accum
                top.state = .Final
                top.handler = finalHandler
                return true

                
            default:
                return false
            }
        }
        

        return false
    }



    func commaHandler( context: JSContext, char: Character ) -> Bool {
        println( "\(__FUNCTION__)(\(char))")

        // If we got here, we just finished a valueHandler, and that was
        // either for a dictionary or an array. 

        switch char {
            
        case ",":
            context.pop() // pop this comma state
            if let top = context.top() {
                switch top.state {
                case .JSObject:
                    top.handler = objectHandler
                case .JSArray:
                    var valContext = JSState( state: JSStateType.Value, handler:valueHandler)
                    context.push( valContext)
                default:
                    return false
                }
            }
    

        case "}":
            context.pop()        
            return endContainer( context)

            
        case "]":
            context.pop()
            return endContainer( context)


        case let s where whitespace(s):
            break // eat it


        default:
            return false
        }


        return true
    }


    func finalHandler( context: JSContext, char: Character ) -> Bool {
        println( "\(__FUNCTION__)(\(char))")        
        switch char {

        case let s where whitespace(s):
            return true
            
        default:
            println( "trailing junk: \(char)")
            return false
        }
    }

    
    // 
    // This is proving to be a real pain
    //
    func unicodeScalarFromString( escapeString: String ) -> UnicodeScalar {
        println( "\(__FUNCTION__): Not implemented yet")
        return UnicodeScalar(0)
    }
    
    
    
    #if false
    func unicodeScalarFromString( escapeString: String ) -> UnicodeScalar {
        
        let chars = escapeString.unicodeScalars
        let charCount = countElements( chars)
        
        println( "CHAR COUNT: \(charCount)")
                
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
        
        return UnicodeScalar( scalar)
    }
    #endif
    
    
    
    // 
    // Exactly 4 hex chars make up the unicode escape
    //
    func unicodeHandler( context: JSContext, char: Character ) -> Bool {
        println( "\(__FUNCTION__)(\(char))")

        if !ishex( char) {
            println( "invalid character in unicode character escape: \(char)")
            return false
        }

        if var top = context.top() {
            let numChars = countElements( top.str!)

            switch numChars {
                
            case 3:
                top.append( char)
                
                let unescaped = Character( unicodeScalarFromString( top.str!))
                
                context.pop() // pops the unicode context
                context.pop() // pops the escape context
                
                // store the converted escape sequence in the string context that is
                // now top
                if var strContext = context.top() {
                    strContext.append( unescaped)
                }
               
               return true

            default:
                top.append( char)
                return true
            }

        }
        else {
            println( "\(__FUNCTION__): internal error")
        }
        
        
        return false
    }
    
    
    func unEscape( char: Character ) -> Character? {
        switch char {
        case "\"":
            return "\""
        case "\\":
            return "\\"
        case "/":
            return "/"
        case "b":
            return "\u{0008}"  // backspace
        case "f":
            return "\u{000c}"  // formfeed
        case "n":
            return "\n"
        case "r":
            return "\r"
        case "t":
            return "\t"
            
        default:
            return nil
        }
    }
    
    
    func isEscape( char: Character ) -> Bool {
        switch char {
        case "\"":
            return true
        case "\\":
            return true
        case "/":
            return true
        case "b":
            return true
        case "f":
            return true
        case "n":
            return true
        case "r":
            return true
        case "t":
            return true
            
        default:
            return false
        }
    }
    
    //
    // If we are in this state, we were accumulating a string value and encountered 
    // a '\' escape character. Now we accumulate the escape sequence, and then push
    // it back into the string in which this escape was found
    //
    // JSON only supports the following escapes
    //
    //    \"
    //    \\
    //    \/
    //    \b
    //    \f
    //    \n
    //    \r
    //    \t
    //    \u four-hex-digits
    //
    //
    //  Interestingly, the Swift language spec only seems to support the 
    // following character escapes:
    //
    //  \0­  \\­  \t­  \n­  \r­  \"­  \'­
    //  
    //  So \f and \b are not supported inherently; will use unicode escapes
    //  for these.
    //
    func escapeHandler( context: JSContext, char: Character ) -> Bool {
        println( "\(__FUNCTION__)(\(char))")
        
        let lambdaAppend = { (char: Character) -> Bool in
            context.pop()
            if var top = context.top() {
                if let unescaped = self.unEscape( char) {
                    top.str?.append( unescaped)
                    return true
                }
            }

            return false
        }

        
        switch char {
        case "u":
            let uni = JSState( state: JSStateType.Unicode, handler: unicodeHandler)
            uni.str = String()
            context.push( uni)
            return true
        
        case let c where isEscape( c):
            return lambdaAppend( c)
            
        default:
            println( "unexpected character in escape sequence: \(char)")
            return false
        }
    
    }


    func stringHandler( context: JSContext, char: Character ) -> Bool {
        println( "\(__FUNCTION__)(\(char))")

        switch char {
        case "\"" :
            var strContext = context.pop()
            if var top = context.top() {
                top.accum = strContext?.str
                return endValue( context)
            }
            
            
        case "\\":
            let escapeContext = JSState(state: JSStateType.CharacterEscape, handler: escapeHandler)
            escapeContext.str = String()
            context.push( escapeContext)


        default:
            if var state = context.top() {
                state.append( char)
            }
        }
        
        return true
    }


    func literalHandler( context: JSContext, char: Character ) -> Bool {
        println( "\(__FUNCTION__)(\(char))")

        if var top = context.top() {
            let literal = top.accum! as String
            top.append( char)

            if literal == top.str! {
                context.pop() 
                if var top = context.top() {

                    switch literal {
                    case "null":
                        top.accum = nil
                    case "true":
                        top.accum = true
                    case "false":
                        top.accum = false
                    default:
                        println("unknown literal")
                        return false
                    }

                    // store nil value in the value context 
                    // and let the endValue() function clean up
                
                    return endValue( context)                    
                }
                
            }

            if  literal.hasPrefix( top.str!) {                
                return true
            } else {
                println( "unexpected character \(char) while scanning for \(top.accum)")
                return false
            }
        }
        
        return false        
    }


    func convertNumberFromString( num: String ) -> Double? {
        // JSON itself does not spec a limitation on the length of its
        // number strings. But Javascript itself is specifies that all decimal
        // or floating point types are 64bit (IEEE 754). That means Double
        // in Swift. 
        //
        // Note that as with Javascript, this should cover our integral values
        // with precision up to 53 bits (far more than a Int32, which is the default
        // size for Int on a armv7 device).
        //

        if let parsedNumber = numberFormatter.numberFromString( num) {
            return parsedNumber.doubleValue as Double
        }
        else {
            return nil
        }
    }



    func endNumberContext( context: JSContext ) -> Bool {
        if let top = context.pop() {
            if let num = convertNumberFromString( top.str! ) {
                if var top = context.top() {
                    top.accum = num
                    return endValue( context)
                }      
            } 
        }

        return false        
    }



    func numberHandler( context: JSContext, char: Character ) -> Bool {

        // This one is going to be different. It is terminated by any of:
        //  whitespace, ',', '}', ']'
        //

        if let top = context.top() {

            switch char {

            case ",":
                if endNumberContext( context) {
                    return commaHandler( context, char: char)
                } else {
                    return false
                }
                
            case "}":
            if endNumberContext( context) {
                    return commaHandler( context, char: char)
                } else {
                    return false
                }
                
            case "]":
                if endNumberContext( context) {
                   
                    return commaHandler( context, char: char)
                } else {
                    return false
                }


            case let s where whitespace( char):
                return endNumberContext( context)


            default:
                if var state = context.top() {
                    state.append( char)
                }

            }
        }

        return true
    }


    func valueHandler( context: JSContext, char: Character ) -> Bool {
        println( "\(__FUNCTION__)(\(char))")

        switch char {
            
        // If we are in an array context, it is possible to get a terminating ] immediately
        case "]":
            return endContainer( context)

        case "\"": 
            var strContext = JSState( state: JSStateType.JSString, handler: stringHandler)
            strContext.str = ""
            context.push( strContext)

        case "{":
            var objContext = JSState( state: JSStateType.JSObject, objectHandler)
            objContext.accum = JSObject()
            context.push( objContext)
        
        case "[":
            var arrContext = JSState( state: JSStateType.JSArray, commaHandler)
            arrContext.array = JSArray()
            context.push( arrContext)
            var valContext = JSState( state: JSStateType.Value, valueHandler)
            context.push( valContext)


        case "t":
            var ctxt = JSState( state: .JSLiteral, handler: literalHandler)
            ctxt.accum = "true"
            ctxt.str = "t"
            context.push( ctxt)                            

        case "f":
            var ctxt = JSState( state: .JSLiteral, handler: literalHandler)
            ctxt.accum = "false"
            ctxt.str = "f"
            context.push( ctxt)                    

        case "n":
            var ctxt = JSState( state: .JSLiteral, handler: literalHandler)
            ctxt.accum = "null"
            ctxt.str = "n"
            context.push( ctxt)
            
        case "-":
            var ctxt = JSState( state: .JSNumber, handler: numberHandler)
            ctxt.str = String(char)
            context.push( ctxt)        

        case let d where isnumber(d):
            var ctxt = JSState( state: .JSNumber, handler: numberHandler)
            ctxt.str = String(char) 
            context.push( ctxt)        
        

        case let s where whitespace(s):
            break

        default:
            return false
        }

        return true
    }
    
    func colonHandler( context: JSContext, char: Character ) -> Bool {
        println( "\(__FUNCTION__)(\(char))")

        switch char {
        case ":":
            var valContext = JSState( state: JSStateType.Value, handler: valueHandler)
            context.push( valContext)

        case let s where whitespace(s):
            break

        default:
            println( "unexpetcted character: \(char)")
            return false
        }

        return true
    }
    
    func keyHandler( context: JSContext, char: Character ) -> Bool {
        println( "\(__FUNCTION__)(\(char))")

        switch char {
        case "\"" :
            let keyContext = context.pop()
            if var objContext = context.top() {
                objContext.str = keyContext?.str
                objContext.handler = colonHandler
            }

        case let s where whitespace(s):
            break
            
        default:
            if var state = context.top() {
                state.append( char)
            }
        }
        
        return true
    }
    
    
    func objectHandler( context: JSContext, char: Character ) -> Bool {
        println( "\(__FUNCTION__)(\(char))")

        switch char {

        case "}":
            return endContainer( context)
        
        case "\"":
            var keyCtxt = JSState( state: JSStateType.Key, keyHandler)
            keyCtxt.str = String()
            context.push( keyCtxt)

            
        case let s where whitespace(s):
            break

        default:
            println( "unexpected character")
            return false
        }
        
        return true
    }
        

 
    // In the initial state, we are eaching whitespace and looking for an
    // opening "{" or "[" character
    //
    func initialHandler( context: JSContext, char: Character ) -> Bool {
        println( "\(__FUNCTION__)(\(char))")
 
        switch char {

        case "{":
            var objContext = JSState( state: JSStateType.JSObject, objectHandler)
            objContext.accum = JSObject()
            context.push( objContext)
        
        case "[":
            var arrContext = JSState( state: JSStateType.JSArray, commaHandler)
            arrContext.array = JSArray()
            context.push( arrContext)
            var valContext = JSState( state: JSStateType.Value, valueHandler)
            context.push( valContext)

            
        case let s where whitespace(s):
            break
        
        default:
            println( "unexpected character")
            return false
        }
        
        return true
    }
    

    //
    // I'm returning continuation:Any? here because I'm trying to hide the details from the user. It
    // should be opaque to them. Might be a better way to do this in Swift.
    //
    public func decodeChunk( someData: NSData!, continuation: Any? ) -> (continuation: Any?, result: Any?) {

        var ctxt: JSContext

        if ( continuation == nil ) {
            var startState = JSState( state: JSStateType.Init, handler: initialHandler)
            ctxt = JSContext( state: startState)
        } else {
            ctxt = continuation as JSContext
        }
        
        let str = NSString( data: someData, encoding: NSUTF8StringEncoding) as String
        let s = JSScanner( str)
        
        
        while ( s.canScan() ) {
            let ch = s.readCharacter()
            
                if let currentState = ctxt.top() {
                if !currentState.handler( ctxt, ch) {
                    println( "error")
                    break
                }
            }
        }


        var result: Any? = nil

        if let currentState = ctxt.top() {
            if ( currentState.state == JSStateType.Final ) {
                
                if let a = currentState.array {
                    result = a
                }

                if let d = currentState.accum {
                    result = d
                }

                return (nil, result)
            } else {
                return (ctxt, nil)
            }
        } 

        return (nil,nil) // an error, shouldn't get here
    }
    
    
    public func decode( someData: NSData! ) -> Any? {

        let (cont, result) = decodeChunk( someData, continuation: nil)

        return result
    }
    
}
