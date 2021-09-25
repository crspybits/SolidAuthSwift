//
//  BodyClaims.swift
//  
//
//  Created by Christopher G Prince on 7/25/21.
//

import Foundation
import SwiftJWT2

// From: https://solid.github.io/authentication-panel/solid-oidc-primer/#authorization-code-pkce-flow-step-13s
/*
Token Body:

{
    "htu": "https://secureauth.example/token",
    "htm": "POST",
    "jti": "4ba3e9ef-e98d-4644-9878-7160fa7d3eb8",
    "iat": 1603306128
}
"htu": "https://secureauth.example/token": htu limits the token for use only on the given url.
"htm": "POST": htm limits the token for use only on a specific http method, in this case POST.
"jti": "4ba3e9ef-e98d-4644-9878-7160fa7d3eb8": jti is a unique identifier for the DPoP token that can optionally be used by the server to defend against replay attacks
"iat": 1603306128: The date the token was issued, in this case October 21, 2020 15:52:33 GMT.
 */
public struct BodyClaims: Claims {
    enum BodyClaimsError: Error {
        case couldNotGetSHA
    }
    
    public let htu: String
    public let htm: String
    public let jti: String
    public let iat: Date?
    public let ath: String?
    
    // Create a new instance for each DPoP generated. This will assign the current Date to the `iat` field.
    // For ath: Only needed if you are sending an access token in the request. See https://datatracker.ietf.org/doc/html/draft-ietf-oauth-dpop-03#section-4.3 and https://github.com/SyncServerII/ServerSolidAccount/issues/5#issuecomment-927001056s
    public init(htu: String, htm: String, jti: String, ath: String?) {
        self.htu = htu
        self.htm = htm
        self.jti = jti
        self.iat = Date()
        self.ath = ath
    }
}

public extension BodyClaims {
    static func athFromAccessToken(_ accessToken: String) throws -> String {
        guard let data = EncodingUtils.sha256(accessToken) else {
            throw BodyClaimsError.couldNotGetSHA
        }
        
        return EncodingUtils.encodeBase64urlNoPadding(data)
    }
}
