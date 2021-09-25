//
//  EncodingUtils.swift
//  
//  Created by Warwick McNaughton on 19/01/19.
//  Copyright © 2019 Warwick McNaughton. All rights reserved.
//  Adapted by Christopher G Prince on 9/24/21.
//

import Foundation
import CommonCrypto

public class EncodingUtils {
    public static func encodeBase64urlNoPadding(_ data: Data) -> String {
        var base64string = data.base64EncodedString(options: [])
        // converts base64 to base64url
        base64string = base64string.replacingOccurrences(of: "+", with: "-")
        base64string = base64string.replacingOccurrences(of: "/", with: "_")
        // strips padding
        base64string = base64string.replacingOccurrences(of: "=", with: "")
        return base64string
    }
    
    public static func sha256(_ inputString: String) -> Data? {
        guard let data = inputString.data(using: .utf8) as NSData? else {
            return nil
        }
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hashValue = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(data.bytes, CC_LONG(data.length), &hashValue)
        return NSData(bytes: hashValue, length: digestLength) as Data
    }
}
