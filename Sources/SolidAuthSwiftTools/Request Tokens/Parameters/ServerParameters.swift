//
//  ServerParameters.swift
//  
//
//  Created by Christopher G Prince on 9/18/21.
//

import Foundation

// Typical parameters to send to a server
// See https://github.com/crspybits/SolidAuthSwift/issues/6

public struct ServerParameters: Codable {
    public let refresh: RefreshParameters
    
    // This should be something like "https://crspybits.trinpod.us", "https://crspybits.inrupt.net", or "https://pod.inrupt.com/crspybits".
    // Aka. host URL; see https://github.com/SyncServerII/ServerSolidAccount/issues/4
    // If this is nil (i.e., it could not be obtained here), and your app needs it, you'll need to prompt the user for it. If it is not nil, you might want to confirm the specific storage location your app plans to use with the user anyways. E.g., your app might want to use "https://pod.inrupt.com/crspybits/YourAppPath/".
    public let storageIRI: URL?
    
    // https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderMetadata
    // URL of the OP's JSON Web Key Set [JWK] document.
    // This is needed on the server to verify the id token.
    public let jwksURL: URL
    
    // See https://github.com/solid/webid-oidc-spec#deriving-webid-uri-from-id-token
    // and https://solidproject.org/faqs#what-is-a-webid
    // I'm making this non-optional so that a server can be assured to have a unique way to identify Solid users.
    public let webid: String
    
    public init(refresh: RefreshParameters, storageIRI: URL?, jwksURL: URL, webid: String) {
        self.refresh = refresh
        self.storageIRI = storageIRI
        self.jwksURL = jwksURL
        self.webid = webid
    }
}
