//
//  Scopes.swift
//  
//
//  Created by Christopher G Prince on 7/24/21.
//

import Foundation

public enum Scope: String, Codable {
    case openid
    case profile
    case webid
    case email
    case address
    case phone
    case offlineAccess = "offline_access"
    
    // To a string, separated with blanks
    static func toString(_ types: Set<Scope>) -> String {
        types.map { $0.rawValue}.joined(separator: " ")
    }
}

