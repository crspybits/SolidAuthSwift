//
//  GrantType.swift
//  
//
//  Created by Christopher G Prince on 9/13/21.
//

import Foundation

public enum GrantType: String, Codable {
    case authorizationCode = "authorization_code"
    case implicit
    case refreshToken = "refresh_token"
    
    // To a string, separated with blanks
    static func toString(_ types: Set<GrantType>) -> String {
        types.map { $0.rawValue}.joined(separator: " ")
    }
    
    static func toArray(_ types: Set<GrantType>) -> [String] {
        return types.map { $0.rawValue}
    }
}
