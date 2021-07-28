//
//  TokenRequestType.swift
//  
//
//  Created by Christopher G Prince on 7/27/21.
//

import Foundation

public enum TokenRequestType {
    // Generate access token / id token
    case code(authorizationCode: String)
    
    // Refresh the access token
    case refresh(refreshToken: String)
}
