//
//  SignInConfiguration.swift
//  
//
//  Created by Christopher G Prince on 7/25/21.
//

import Foundation

public struct SignInConfiguration {
    // e.g., "https://solidcommunity.net"
    public let issuer: String
    
    // E.g., "biz.SpasticMuffin.Neebla.demo:/mypath"
    public let redirectURI: String

    // It looks like this should up in the sign in UI for the Pod. But not seeing it yet when using solidcommunity.net.
    public let clientName: String
    
    // e.g., [.openid, .profile, .webid, .offlineAccess]
    public let scopes: Set<Scope>
    
    public init(issuer: String, redirectURI: String, clientName: String, scopes: Set<Scope>) {
        self.issuer = issuer
        self.redirectURI = redirectURI
        self.clientName = clientName
        self.scopes = scopes
    }
}
