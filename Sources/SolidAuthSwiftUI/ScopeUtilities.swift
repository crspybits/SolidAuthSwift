//
//  ScopeUtilities.swift
//  POD browser
//
//  Created by Warwick McNaughton on 26/01/19.
//  Copyright © 2019 Warwick McNaughton. All rights reserved.
//  Adapted by Christopher G Prince on 7/24/21.

import Foundation

let kScopeOpenID = "openid"
let kScopeProfile = "profile"
let kScopeWebID = "webid"
let kScopeEmail = "email"
let kScopeAddress = "address"
let kScopePhone = "phone"
let kScopeOfflineAccess = "offline_access"

class ScopeUtilities: NSObject {
    enum ScopeUtilitiesError: Error {
        case illegalEmptyString
        case illegalCharacters
    }
    
    static let disallowedScopeCharacters: CharacterSet? = {
        var disallowedCharacters = CharacterSet()
        var allowedCharacters = CharacterSet()
        //        var allowedCharacters = NSMutableCharacterSet(range: NSMakeRange(0x23, 0x5B - 0x23 + 1))
        //        allowedCharacters.addCharacters(in: NSMakeRange(0x5D, 0x7E - 0x5D + 1))
        //        allowedCharacters.addCharacters(in: "0x21")
        allowedCharacters.insert(charactersIn: "\u{0023}"..."\u{005B}")
        allowedCharacters.insert(charactersIn: "\u{005D}"..."\u{007E}")
        allowedCharacters.insert("\u{0021}")
        disallowedCharacters = allowedCharacters.inverted
        return disallowedCharacters
    }()
    
    class func scopes(withArray scopes: [String]) throws -> String? {
        let disallowedCharacters = ScopeUtilities.disallowedScopeCharacters
        
        for scope in scopes {
            guard scope.count != 0 else {
                throw ScopeUtilitiesError.illegalEmptyString
            }

            if let aCharacters = disallowedCharacters {
                guard Int((scope as NSString?)?.rangeOfCharacter(from: aCharacters).location ?? 0) == NSNotFound else {
                    throw ScopeUtilitiesError.illegalCharacters
                }
            }
        }
        
        let scopeString = scopes.joined(separator: " ")
        return scopeString
    }
    
    class func scopesArray(with scopes: String?) -> [String]? {
        return scopes?.components(separatedBy: " ")
    }
}

