//
//  SignInConfiguration.swift
//  
//
//  Created by Christopher G Prince on 7/25/21.
//

import Foundation
import AuthenticationServices
import SolidAuthSwiftTools

public struct SignInConfiguration {
    // e.g., "https://solidcommunity.net"
    public let issuer: String
    
    // E.g., "biz.SpasticMuffin.Neebla.demo:/mypath"
    public let redirectURI: String
    
    var redirectURL: URL? {
        return URL(string: redirectURI)
    }
    
    var redirectScheme:String? {
        return redirectURL?.scheme
    }
    
    public let postLogoutRedirectURI: String?

    var postLogoutRedirectURL: URL? {
        guard let postLogoutRedirectURI = postLogoutRedirectURI else {
            return nil
        }
        return URL(string: postLogoutRedirectURI)
    }
    
    var postLogoutRedirectScheme:String? {
        return postLogoutRedirectURL?.scheme
    }
    
    // It looks like this should up in the sign in UI for the Pod. But not seeing it yet when using solidcommunity.net.
    public let clientName: String
    
    // e.g., [.openid, .profile, .webid, .offlineAccess]
    public let scopes: Set<Scope>
    
    // e.g., [.code, .token]
    let responseTypes: Set<ResponseType>
    
    let grantTypes: Set<GrantType>
    
    let authenticationMethod: TokenEndpointAuthenticationMethod
    
    // Can be used to provide context when presenting the sign in screen.
    let presentationContextProvider: ASWebAuthenticationPresentationContextProviding?
    
    // TODO: Enable presentationContextProvider for signout as well.
    
    public init(issuer: String, redirectURI: String, postLogoutRedirectURI: String? = nil, clientName: String, scopes: Set<Scope>, responseTypes: Set<ResponseType>, grantTypes: Set<GrantType>, authenticationMethod: TokenEndpointAuthenticationMethod, presentationContextProvider: ASWebAuthenticationPresentationContextProviding? = nil) {
        self.issuer = issuer
        self.redirectURI = redirectURI
        self.postLogoutRedirectURI = postLogoutRedirectURI
        self.clientName = clientName
        self.scopes = scopes
        self.responseTypes = responseTypes
        self.grantTypes = grantTypes
        self.authenticationMethod = authenticationMethod
        self.presentationContextProvider = presentationContextProvider
    }
}
