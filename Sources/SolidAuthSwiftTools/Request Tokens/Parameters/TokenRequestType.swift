//
//  TokenRequestType.swift
//  
//
//  Created by Christopher G Prince on 7/27/21.
//

import Foundation

public protocol ParametersBasics {
    var tokenEndpoint: URL { get }
    var grantType: String { get }
    var clientId: String { get }
    var clientSecret: String { get }

    // This must be the same as that used in the registration request.
    var authenticationMethod: TokenEndpointAuthenticationMethod { get }
}

public enum TokenRequestType {
    // Generate access token / id token
    case code(CodeParameters)
    
    // Refresh the access token
    case refresh(RefreshParameters)
    
    var basics: ParametersBasics {
        switch self {
        case .code(let code):
            return code
        case .refresh(let refresh):
            return refresh
        }
    }
}
