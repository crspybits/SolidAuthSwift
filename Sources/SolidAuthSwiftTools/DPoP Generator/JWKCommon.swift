//
//  JWKCommon.swift
//  
//
//  Created by Christopher G Prince on 7/26/21.
//

import Foundation

public protocol JWKCommon: Codable {
    var kty: String {get}
    var kid: String {get}
    var use: String {get}
    var alg: String {get}
}
