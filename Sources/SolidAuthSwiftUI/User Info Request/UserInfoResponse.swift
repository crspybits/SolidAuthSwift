//
//  UserInfoResponse.swift
//  
//
//  Created by Christopher G Prince on 9/19/21.
//

import Foundation

// See "5.3.2.  Successful UserInfo Response" in https://openid.net/specs/openid-connect-core-1_0.html#UserInfo

public struct UserInfoResponse: Codable {
    // "The sub (subject) Claim MUST always be returned in the UserInfo Response." (https://openid.net/specs/openid-connect-core-1_0.html#UserInfo)
    // I'm assuming this will a webid in the case of Solid.
    public let sub: String
    
    // But: "Once the UserInfo response is received by the Relying Party, the standard website claim should be used as the WebID URI by that RP." (https://github.com/solid/webid-oidc-spec#deriving-webid-uri-from-id-token)
    public let website: String?

    public let name: String?
    public let given_name: String?
    public let family_name: String?
    public let preferred_username: String?
    public let email: String?
}
