//
//  AuthorizationRequest.swift
//  
//  Created by Warwick McNaughton on 19/01/19.
//  Copyright © 2019 Warwick McNaughton. All rights reserved.
//  Adapted by Christopher G Prince on 7/24/21.
//

import Foundation
import AnyCodable
import SolidAuthSwiftTools

fileprivate let kResponseTypeKey = "response_type"
fileprivate let kClientIDKey = "client_id"
fileprivate let kClientSecretKey = "client_secret"
fileprivate let kScopeKey = "scope"
fileprivate let kRedirectURLKey = "redirect_uri"
fileprivate let kStateKey = "state"
fileprivate let kNonceKey = "nonce"
fileprivate let kCodeVerifierKey = "code_verifier"
fileprivate let kCodeChallengeKey = "code_challenge"
fileprivate let kCodeChallengeMethodKey = "code_challenge_method"
fileprivate let kAdditionalParametersKey = "additionalParameters"
fileprivate let OIDOAuthorizationRequestCodeChallengeMethodS256 = "S256"
fileprivate let kStateSizeBytes: Int = 32
fileprivate let kCodeVerifierBytes: Int = 32

public class AuthorizationRequest: NSObject, Codable  {
    enum AuthorizationRequestError: Error {
        case unsupportedResponseType(String)
        case badScopes
    }
        
    let configuration: ProviderConfiguration
    /*! @brief The expected response type.
     @remarks response_type
     @discussion Generally 'code' if pure OAuth, otherwise a space-delimited list of of response
     types including 'code', 'token', and 'id_token' for OpenID Connect.
     @see https://tools.ietf.org/html/rfc6749#section-3.1.1
     @see http://openid.net/specs/openid-connect-core-1_0.html#rfc.section.3
     */
    let responseType: Set<ResponseType>
    /*! @brief The client identifier.
     @remarks client_id
     @see https://tools.ietf.org/html/rfc6749#section-2.2
     */
    public let clientID: String
    /*! @brief The client secret.
     @remarks client_secret
     @discussion The client secret is used to prove that identity of the client when exchaning an
     authorization code for an access token.
     The client secret is not passed in the authorizationRequestURL. It is only used when
     exchanging the authorization code for an access token.
     @see https://tools.ietf.org/html/rfc6749#section-2.3.1
     */
    let clientSecret: String?
    /*! @brief The value of the scope parameter is expressed as a list of space-delimited,
     case-sensitive strings.
     @remarks scope
     @see https://tools.ietf.org/html/rfc6749#section-3.3
     */
    let scopes: Set<Scope>
    /*! @brief The client's redirect URI.
     @remarks redirect_uri
     @see https://tools.ietf.org/html/rfc6749#section-3.1.2
     */
    public let redirectURL: URL
    
    //  The converted code is limited to 2 KB.
    //  Upgrade your plan to remove this limitation.
    //
    /*! @brief An opaque value used by the client to maintain state between the request and callback.
     @remarks state
     @discussion If this value is not explicitly set, this library will automatically add state and
     perform appropriate validation of the state in the authorization response. It is recommended
     that the default implementation of this parameter be used wherever possible. Typically used
     to prevent CSRF attacks, as recommended in RFC6819 Section 5.3.5.
     @see https://tools.ietf.org/html/rfc6749#section-4.1.1
     @see https://tools.ietf.org/html/rfc6819#section-5.3.5
     */
    let state: String?
    /*! @brief String value used to associate a Client session with an ID Token, and to mitigate replay
     attacks. The value is passed through unmodified from the Authentication Request to the ID
     Token. Sufficient entropy MUST be present in the nonce values used to prevent attackers from
     guessing values.
     @remarks nonce
     @discussion If this value is not explicitly set, this library will automatically add nonce and
     perform appropriate validation of the nonce in the ID Token.
     @see https://openid.net/specs/openid-connect-core-1_0.html#AuthRequest
     */
    let nonce: String?
    /*! @brief The PKCE code verifier.
     @remarks code_verifier
     @discussion The code verifier itself is not included in the authorization request that is sent
     on the wire, but needs to be in the token exchange request.
     @c OIDAuthorizationResponse.tokenExchangeRequest will create a @c OIDTokenRequest that
     includes this parameter automatically.
     @see https://tools.ietf.org/html/rfc7636#section-4.1
     */
    public let codeVerifier: String?
    /*! @brief The PKCE code challenge, derived from #codeVerifier.
     @remarks code_challenge
     @see https://tools.ietf.org/html/rfc7636#section-4.2
     */
    let codeChallenge: String?
    /*! @brief The method used to compute the @c #codeChallenge
     @remarks code_challenge_method
     @see https://tools.ietf.org/html/rfc7636#section-4.3
     */
    let codeChallengeMethod: String?
    /*! @brief The client's additional authorization parameters.
     @see https://tools.ietf.org/html/rfc6749#section-3.1
     */
    let additionalParameters: [String : AnyCodable]?
    
    public init(configuration: ProviderConfiguration, clientID: String, clientSecret: String?, scopes: Set<Scope>, redirectURL: URL, responseType: Set<ResponseType>, state: String?, nonce: String?, codeVerifier: String?, codeChallenge: String?, codeChallengeMethod: String?, additionalParameters: [String : AnyCodable]?) throws {
        
        self.configuration = configuration
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.scopes = scopes
        self.redirectURL = redirectURL
        self.responseType = responseType
        
        guard responseType.count >= 1 else {
            throw AuthorizationRequestError.unsupportedResponseType("Empty response type")
        }
        
        if responseType.count == 1 && !responseType.contains(.code) {
            throw AuthorizationRequestError.unsupportedResponseType("The response_type \"\(responseType)\" isn't supported. AppAuth only supports the \"code\" or \"code id_token\" response_type.")
        }

        self.state = state
        self.nonce = nonce
        self.codeVerifier = codeVerifier
        self.codeChallenge = codeChallenge
        self.codeChallengeMethod = codeChallengeMethod
        self.additionalParameters = additionalParameters // copyItems: true
        
        super.init()
    }

    /**
     * Generates PKCE code verifier and challenge; sets a code challenge method of OIDOAuthorizationRequestCodeChallengeMethodS256
     */
    public convenience init(configuration: ProviderConfiguration, clientID: String, clientSecret: String? = nil, scopes: Set<Scope>, redirectURL: URL, responseType: Set<ResponseType>, additionalParameters: [String : AnyCodable]? = nil) throws {
        
        let codeVerifier = Self.generateCodeVerifier()
        let codeChallenge = Self.codeChallengeS256(forVerifier: codeVerifier)
        try self.init(configuration: configuration, clientID: clientID, clientSecret: clientSecret, scopes: scopes, redirectURL: redirectURL, responseType: responseType, state: Self.generateState(), nonce: Self.generateState(), codeVerifier: codeVerifier, codeChallenge: codeChallenge, codeChallengeMethod: OIDOAuthorizationRequestCodeChallengeMethodS256, additionalParameters: additionalParameters)
    }
    
    public convenience init(configuration: ProviderConfiguration, clientID: String, scopes: Set<Scope>, redirectURL: URL, responseType: Set<ResponseType>, additionalParameters: [String : AnyCodable]?) throws {
        try self.init(configuration: configuration, clientID: clientID, clientSecret: nil, scopes: scopes, redirectURL: redirectURL, responseType: responseType, additionalParameters: additionalParameters)
    }

    // MARK: - Codable
    
    class func generateCodeVerifier() -> String? {
        return TokenUtilities.randomURLSafeString(withSize: kCodeVerifierBytes)
    }
    
    class func generateState() -> String? {
        return TokenUtilities.randomURLSafeString(withSize: kStateSizeBytes)
    }
    
    class func codeChallengeS256(forVerifier codeVerifier: String?) -> String? {
        if codeVerifier == nil {
            return nil
        }
        // generates the code_challenge per spec https://tools.ietf.org/html/rfc7636#section-4.2
        // code_challenge = BASE64URL-ENCODE(SHA256(ASCII(code_verifier)))
        // NB. the ASCII conversion on the code_verifier entropy was done at time of generation.
        let sha256Verifier: Data? = TokenUtilities.sha256(codeVerifier)
        return TokenUtilities.encodeBase64urlNoPadding(sha256Verifier)
    }
    
    func authorizationRequestURL() throws -> URL? {
        let query = QueryUtilities()
        // Required parameters.
        let responseTypeString = ResponseType.toString(responseType)
        query.addParameter(kResponseTypeKey, value: responseTypeString)
        query.addParameter(kClientIDKey, value: clientID)
        // Add any additional parameters the client has specified.
        query.addParameters(additionalParameters)
        // Add optional parameters, as applicable.
        query.addParameter(kRedirectURLKey, value: redirectURL.absoluteString)
        let scopesString = Scope.toString(scopes)
        query.addParameter(kScopeKey, value: scopesString)
        if state != nil {
            query.addParameter(kStateKey, value: state)
        }
        if nonce != nil {
            query.addParameter(kNonceKey, value: nonce)
        }
        if codeChallenge != nil {
            query.addParameter(kCodeChallengeKey, value: codeChallenge)
        }
        if codeChallengeMethod != nil{
            query.addParameter(kCodeChallengeMethodKey, value: codeChallengeMethod)
        }
        // Construct the URL:
        return try query.urlByReplacingQuery(in: configuration.authorizationEndpoint)
    }
    
    func externalUserAgentRequestURL() throws -> URL? {
        return try authorizationRequestURL()
    }
    
    func redirectScheme() -> String? {
        return redirectURL.scheme
    }
}

