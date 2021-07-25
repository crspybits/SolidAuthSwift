//
//  File.swift
//  
//
//  Created by Christopher G Prince on 7/24/21.
//

import Foundation

public enum ResponseType: String, Codable {
    case code
    case idToken = "id_token"
    
    // To a string, separated with blanks
    static func toString(_ types: Set<ResponseType>) -> String {
        types.map { $0.rawValue}.joined(separator: " ")
    }
}
