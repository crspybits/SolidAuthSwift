//
//  TokenRequest.swift
//  
//
//  Created by Christopher G Prince on 7/25/21.
//

import Foundation

// See https://solid.github.io/authentication-panel/solid-oidc-primer/#authorization-code-pkce-flow-step-14
/*
POST https://secureauth.example/token
Headers: {
  "DPoP": "eyJhbGciOiJFUzI1NiIsInR5cCI6ImRwb3Arand0IiwiandrIjp7Imt0eSI6IkVDIiwia2lkIjoiZkJ1STExTkdGbTQ4Vlp6RzNGMjVDOVJmMXYtaGdEakVnV2pEQ1BrdV9pVSIsInVzZSI6InNpZyIsImFsZyI6IkVDIiwiY3J2IjoiUC0yNTYiLCJ4IjoiOWxlT2gxeF9IWkhzVkNScDcyQzVpR01jek1nUnpDUFBjNjBoWldfSFlLMCIsInkiOiJqOVVYcnRjUzRLVzBIYmVteW1vRWlMXzZ1cko0TFFHZXJQZXVNaFNEaV80In19.eyJodHUiOiJodHRwczovL3NlY3VyZWF1dGguZXhhbXBsZS90b2tlbiIsImh0bSI6InBvc3QiLCJqdGkiOiI0YmEzZTllZi1lOThkLTQ2NDQtOTg3OC03MTYwZmE3ZDNlYjgiLCJpYXQiOjE2MDMzMDYxMjgsImV4cCI6MTYwMzMwOTcyOH0.2lbgLoRCkj0MsDc9BpquoaYuq0-XwRf_URdXru2JKrVzaWUqQfyKRK76_sQ0aJyVwavM3pPswLlHq2r9032O7Q",
  "content-type": "application/x-www-form-urlencoded"
}
Body:
  grant_type=authorization_code&
  code_verifier=JXPOuToEB7&
  code=m-OrTPHdRsm8W_e9P0J2Bt&
  redirect_uri=https%3A%2F%2Fdecentphotos.example%2Fcallback&
  client_id=https%3A%2F%2Fdecentphotos.example%2Fwebid%23this
headers.DPoP: "eyJhbGciOiJFUz...": The DPoP token we generated before. This will tell the OP what the client’s public key is.
headers.content-type: "application/x-www-form-urlencoded": Sets to body’s content type to application/x-www-form-urlencoded. Some OPs will accept other content types like application/json but they all must access urlencoded content types, so it’s safest to use that.
body.grant_type=authorization_code: Tells the OP that we are doing the authorization code flow.
body.code_verifier=JXPOuToEB7: Our code verifier that we stored in session storage
body.code=m-OrTPHdRsm8W_e9P0J2Bt: The code that we received from the OP upon redirect
body.redirect_uri: The app’s redirect url. In this case, this isn’t needed because we’re doing an AJAX request.
body.client_id=https%3A%2F%2Fdecentphotos.example%2Fwebid%23this: The app’s client id.
 */

public class TokenRequest {
    enum Keys: String {
        case grantType = "grant_type"
        case codeVerifier = "code_verifier"
        case code
        case redirectUri = "redirect_uri"
        case clientId = "client_id"
    }
    
    let codeVerifier: String
    let code: String
    let redirectUri: String
    let clientId: String

    public init(codeVerifier: String, code: String, redirectUri: String, clientId: String) {
        self.codeVerifier = codeVerifier
        self.code = code
        self.redirectUri = redirectUri
        self.clientId = clientId
    }
    
    func send() {
        
    }
}
