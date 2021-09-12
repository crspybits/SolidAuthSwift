//
//  RegistrationResponse.swift
//
//  Created by Warwick McNaughton on 18/01/19.
//  Copyright © 2019 Warwick McNaughton. All rights reserved.
//  Adapted by Christopher G Prince on 7/24/21.
//

import Foundation

let kResponseTypeCode = "code"
let kResponseTypeToken = "token"
let kResponseTypeIDToken = "id_token";

public class RegistrationResponse: NSObject {
    let ClientIDParam = "client_id"
    let ClientIDIssuedAtParam = "client_id_issued_at"
    let ClientSecretParam = "client_secret"
    let ClientSecretExpirestAtParam = "client_secret_expires_at"
    let RegistrationAccessTokenParam = "registration_access_token"
    let RegistrationClientURIParam = "registration_client_uri"
    
    public var clientID: String?
    public var clientIDIssuedAt: Date?
    public var clientSecret: String?
    public var clientSecretExpiresAt: Date?
    public var registrationAccessToken: String?
    public var registrationClientURI: URL?
    public var additionalParameters = [String : Any]()
    
    init(parameters: [String : Any]) {
        super.init()
        for parameter in parameters {
            switch parameter.key {
            case ClientIDParam:
                clientID = parameters[ClientIDParam] as? String
            case ClientIDIssuedAtParam:
                guard let rawDate = parameters[ClientIDIssuedAtParam] as? NSNumber else {
                    continue
                }
                clientIDIssuedAt = Date(timeIntervalSince1970: TimeInterval(Int64(truncating: rawDate)))
            case ClientSecretParam:
                clientSecret = parameters[ClientSecretParam] as? String
            case ClientSecretExpirestAtParam :
                guard let rawDate = parameters[ClientSecretExpirestAtParam] as? NSNumber else {
                    continue
                }
                clientSecretExpiresAt = Date(timeIntervalSinceNow: TimeInterval(Int64(truncating: rawDate)))
            case RegistrationAccessTokenParam:
                registrationAccessToken = parameters[RegistrationAccessTokenParam] as? String
            case RegistrationClientURIParam:
                guard let urlString = parameters[RegistrationClientURIParam] as? String else {
                    continue
                }
                registrationClientURI = URL(string: urlString)
            default:
                additionalParameters[parameter.key] = parameter.value
            }
        }
        //let additionalParameters = OIDFieldMapping.remainingParameters(withMap: RegistrationResponse.sharedFieldMap, parameters: parameters, instance: self)
        //self.additionalParameters = additionalParameters
        // If client_secret is issued, client_secret_expires_at is REQUIRED,
        // and the response MUST contain "[...] both a Client Configuration Endpoint
        // and a Registration Access Token or neither of them"
        if (clientSecret != nil && clientSecretExpiresAt == nil) {return}
        
        if (!(registrationClientURI != nil && registrationAccessToken != nil) && !(registrationClientURI == nil && registrationAccessToken == nil)) {
            return
        }
    }
        
    func description() -> String {
        let d =  "\n=============\nOIDRegistrationResponse \nclientID: \(String(describing: clientID)) \nclientIDIssuedAt: \(String(describing: clientIDIssuedAt)) \nclientSecret: \(String(describing: TokenUtilities.redact(clientSecret))) \nclientSecretExpiresAt: \(String(describing: clientSecretExpiresAt)) \nregistrationAccessToken: \(String(describing: TokenUtilities.redact(registrationAccessToken))) \nregistrationClientURI: \(String(describing: registrationClientURI)) \nadditionalParameters: \(additionalParameters) \n============="
        return d
    }
}
