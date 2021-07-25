//
//  Scopes.swift
//  
//
//  Created by Christopher G Prince on 7/24/21.
//

import Foundation

public enum Scope: String, Codable {
    enum ScopeError: Error {
        case someUnknownScopes
    }
    
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
    
    static func fromString(_ scopes: String) throws -> Set<Scope> {
        let splitScopes = scopes.split(separator: " ")
        let scopes = splitScopes.compactMap { Scope(rawValue: String($0))}
        guard splitScopes.count == splitScopes.count else {
            logger.error("Some of the scopes were not known: \(scopes)")
            throw ScopeError.someUnknownScopes
        }
        return Set<Scope>(scopes)
    }
}

