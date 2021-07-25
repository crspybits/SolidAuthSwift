//
//  AuthorizationResponse.swift
//  POD browser
//
//  Created by Warwick McNaughton on 19/01/19.
//  Copyright © 2019 Warwick McNaughton. All rights reserved.
//  Adapted by Christopher G Prince on 7/24/21.
//

import Foundation

fileprivate let kAuthorizationCodeKey = "code"
fileprivate let kStateKey = "state"
fileprivate let kAccessTokenKey = "access_token"
fileprivate let kExpiresInKey = "expires_in"
fileprivate let kTokenTypeKey = "token_type"
fileprivate let kIDTokenKey = "id_token"
fileprivate let kScopeKey = "scope"
fileprivate let kAdditionalParametersKey = "additionalParameters"
fileprivate let kRequestKey = "request"
fileprivate let kTokenExchangeRequestException = """
Attempted to create a token exchange request from an authorization response with no \
authorization code.
"""

public class AuthorizationResponse: NSObject, Codable  {
    public var authorizationCode: String?
    /*! @brief REQUIRED if the "state" parameter was present in the client authorization request. The
     exact value received from the client.
     @remarks state
     */
    public var state: String?
    /*! @brief The access token generated by the authorization server.
     @discussion Set when the response_type requested includes 'token'.
     @remarks access_token
     @see http://openid.net/specs/openid-connect-core-1_0.html#ImplicitAuthResponse
     */
    public private(set) var accessToken: String?
    
    /*! @brief The approximate expiration date & time of the access token.
     @discussion Set when the response_type requested includes 'token'.
     @remarks expires_in
     @seealso OIDAuthorizationResponse.accessToken
     @see http://openid.net/specs/openid-connect-core-1_0.html#ImplicitAuthResponse
     */
    public private(set) var accessTokenExpirationDate: Date?
    /*! @brief Typically "Bearer" when present. Otherwise, another token_type value that the Client has
     negotiated with the Authorization Server.
     @discussion Set when the response_type requested includes 'token'.
     @remarks token_type
     @see http://openid.net/specs/openid-connect-core-1_0.html#ImplicitAuthResponse
     */
    public private(set) var tokenType: String?
    /*! @brief ID Token value associated with the authenticated session.
     @discussion Set when the response_type requested includes 'id_token'.
     @remarks id_token
     @see http://openid.net/specs/openid-connect-core-1_0.html#IDToken
     @see http://openid.net/specs/openid-connect-core-1_0.html#ImplicitAuthResponse
     */
    public private(set) var idToken: String?
    /*! @brief The scope of the access token. OPTIONAL, if identical to the scopes requested, otherwise,
     REQUIRED.
     @remarks scope
     @see https://tools.ietf.org/html/rfc6749#section-5.1
     */
    public private(set) var scope: Set<Scope>?
    /*! @brief Additional parameters returned from the authorization server.
     */
    public private(set) var additionalParameters: [String : NSObject]?
    
    // MARK: - Initializers
    public init(parameters: [String : NSObject]) {
        for parameter in parameters {
            switch parameter.key {
            case kStateKey:
                state = parameters[kStateKey] as? String
            case kAuthorizationCodeKey:
                authorizationCode = parameters[kAuthorizationCodeKey] as? String
            case kAccessTokenKey:
                accessToken = parameters[kAccessTokenKey] as? String
            case kExpiresInKey:
                guard let rawDate = parameters[kExpiresInKey] as? NSNumber else {
                    continue
                }
                accessTokenExpirationDate = Date(timeIntervalSinceNow: TimeInterval(Int64(truncating: rawDate)))
            case kTokenTypeKey:
                tokenType = parameters[kTokenTypeKey] as? String
            case kIDTokenKey:
                idToken = parameters[kIDTokenKey] as? String
            case kScopeKey:
                guard let scopesString = parameters[kScopeKey] as? String else {
                    continue
                }
                scope = try? Scope.fromString(scopesString)
            default:
                additionalParameters = [:]
                additionalParameters![parameter.key] = parameter.value
            }
        }
        
        super.init()
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case additionalParameters
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let paramData = try NSKeyedArchiver.archivedData(withRootObject: additionalParameters as Any, requiringSecureCoding: true)
        try container.encode(paramData, forKey: .additionalParameters)
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let paramData = try container.decode(Data.self, forKey: .additionalParameters)
        additionalParameters = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(paramData) as? [String : NSObject]
        super.init()
    }
}
