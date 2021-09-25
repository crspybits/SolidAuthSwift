//
//  TokenUtilities.swift
//  POD browser
//
//  Created by Warwick McNaughton on 19/01/19.
//  Copyright © 2019 Warwick McNaughton. All rights reserved.
//  Adapted by Christopher G Prince on 7/24/21.
//

import Foundation
import CommonCrypto
import SolidAuthSwiftTools

private let kFormUrlEncodedAllowedCharacters = " *-._0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

class TokenUtilities: NSObject {
    class func base64urlNoPaddingDecode(_ base64urlNoPaddingString: String?) -> Data? {
        var body = base64urlNoPaddingString
        // Converts base64url to base64.
        let range = NSRange(location: 0, length: base64urlNoPaddingString?.count ?? 0)
        if let subRange = Range<String.Index>(range, in: body!) { body = body?.replacingOccurrences(of: "-", with: "+", options: .literal, range: subRange) }
        if let subRange = Range<String.Index>(range, in: body!) { body = body?.replacingOccurrences(of: "_", with: "/", options: .literal, range: subRange) }
        // Converts base64 no padding to base64 with padding
        while (body?.count ?? 0) % 4 != 0 {
            body?.append("=")
        }
        // Decodes base64 string.
        let decodedData = Data(base64Encoded: body ?? "", options: [])
        return decodedData
    }

    class func randomURLSafeString(withSize size: Int) -> String? {
        //       var randomData = Data(count: size)  // TODO:  Use cssm_data ???
        var randomData = Data(count: size)
        let dataCount = randomData.count
        let result = randomData.withUnsafeMutableBytes {
            (mutableBytes: UnsafeMutablePointer<UInt8>) -> Int32 in
            SecRandomCopyBytes(kSecRandomDefault, (dataCount), mutableBytes)
        }
        //        var randomByteArray = [Int8](repeating: 0, count: size)
        //        let result = SecRandomCopyBytes(kSecRandomDefault, (randomData.count ), &randomByteArray)
        if result != errSecSuccess {
            return nil
        }
        return EncodingUtils.encodeBase64urlNoPadding(randomData)
    }
    
    class func redact(_ inputString: String?) -> String? {
        if inputString == nil {
            return nil
        }
        switch (inputString?.count ?? 0) {
        case 0:
            return ""
        case 1...8:
            return "[redacted]"
        case 9:
            fallthrough
        default:
            return ((inputString as NSString?)?.substring(to: 6) ?? "") + ("...[redacted]")
        }
    }
    
    class func formUrlEncode(_ inputString: String?) -> String {
        // https://www.w3.org/TR/html5/sec-forms.html#application-x-www-form-urlencoded-encoding-algorithm
        // Following the spec from the above link, application/x-www-form-urlencoded percent encode all
        // the characters except *-._A-Za-z0-9
        // Space character is replaced by + in the resulting bytes sequence
        if (inputString?.count ?? 0) == 0 {
            return inputString!
        }
        let allowedCharacters = CharacterSet(charactersIn: kFormUrlEncodedAllowedCharacters)
        // Percent encode all characters not present in the provided set.
        let encodedString = inputString?.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
        // Replace occurences of space by '+' character
        return (encodedString?.replacingOccurrences(of: " ", with: "+"))!
    }
    
    
    class func parseJWTSection(_ sectionString: String?) -> [String : NSObject]? {
        let decodedData: Data? = self.base64urlNoPaddingDecode(sectionString)
        // Parses JSON.
        var object: Any? = nil
        if let aData = decodedData {
            do {
                object = try JSONSerialization.jsonObject(with: aData, options: [])
            }
            catch {
                print("Error \(error) parsing token payload \(String(describing: sectionString))")
            }
        }
        
        if (object is [String : NSObject]) {
            return object as? [String : NSObject]
        }
        return nil
    }
    
    

}

