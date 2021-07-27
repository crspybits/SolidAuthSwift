//
//  TokenRequest.swift
//  
//
//  Created by Christopher G Prince on 7/25/21.
//

import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

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

// Subclass of NSObject for URLSessionDelegate conformance.

public class TokenRequest<JWK: JWKCommon>: NSObject {
    enum TokenRequestError: Error {
        case couldNotConvertBodyToData
        case noHTTPURLResponse
        case badStatusCode(Int)
        case noResponseData
        case jsonDeserialization
        case noBody
    }
    
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
    let tokenEndpoint: URL
    let jwk: JWK
    let privateKey: String
    
    public init(tokenEndpoint: URL, codeVerifier: String, code: String, redirectUri: String, clientId: String, jwk: JWK, privateKey: String) {
        self.codeVerifier = codeVerifier
        self.code = code
        self.redirectUri = redirectUri
        self.clientId = clientId
        self.tokenEndpoint = tokenEndpoint
        self.jwk = jwk
        self.privateKey = privateKey
    }

    public func send(queue: DispatchQueue = .main, completion: @escaping (Result<TokenResponse, Error>) -> Void) {
    
        func callCompletion(_ result: Result<TokenResponse, Error>) {
            queue.async {
                completion(result)
            }
        }
        
        let httpMethod = "POST"
        let bodyClaims = BodyClaims(htu: tokenEndpoint.absoluteString, htm: httpMethod, jti: UUID().uuidString)
        let dpop = DPoP(jwk: jwk, privateKey: privateKey, body: bodyClaims)
        
        let dpopHeader: String
        
        do {
            dpopHeader = try dpop.generate()
        } catch let error {
            callCompletion(.failure(error))
            return
        }

        let bodyData = self.body()
        
        var request = URLRequest(url: tokenEndpoint)
        request.httpMethod = httpMethod
        request.httpBody = bodyData
        
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "content-type")
        request.addValue(dpopHeader, forHTTPHeaderField: DPoPHttpHeaderKey)
        
        // print("request.allHTTPHeaderFields: \(String(describing: request.allHTTPHeaderFields))")

        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
        session.dataTask(with: request, completionHandler: { data, response, error in
            if let error = error {
                callCompletion(.failure(error))
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                callCompletion(.failure(TokenRequestError.noHTTPURLResponse))
                return
            }
            
            // DEBUGGING
#if false
            if let data = data {
                let str = String(data: data, encoding: .utf8)
                print("String: \(String(describing: str))")
            }
#endif
            // DEBUGGING
            
            guard NetworkingExtras.statusCodeOK(response.statusCode) else {
                callCompletion(.failure(TokenRequestError.badStatusCode(response.statusCode)))
                return
            }
            
            guard let data = data else {
                callCompletion(.failure(TokenRequestError.noResponseData))
                return
            }
            
            let tokenResponse: TokenResponse
            do {
                tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            } catch let error {
                callCompletion(.failure(error))
                return
            }
            
            callCompletion(.success(tokenResponse))
        }).resume()
    }

    func body() -> Data {
        let values = [
            URLQueryItem(name: Keys.grantType.rawValue, value: "authorization_code"),
            URLQueryItem(name: Keys.codeVerifier.rawValue, value: codeVerifier),
            URLQueryItem(name: Keys.code.rawValue, value: code),
            URLQueryItem(name: Keys.redirectUri.rawValue, value: redirectUri),
            URLQueryItem(name: Keys.clientId.rawValue, value: clientId),
        ]
        
        let pieces = values.map(self.urlEncode)
        
        let bodyString = pieces.joined(separator: "&")
        
        print("Body: \(bodyString)")
        
        return Data(bodyString.utf8)
    }

    // Adapted from https://davedelong.com/blog/2020/06/30/http-in-swift-part-3-request-bodies/
    private func urlEncode(_ queryItem: URLQueryItem) -> String {
        let value = queryItem.value ?? ""
        return "\(queryItem.name)=\(value)"
    }

    private func urlEncode(_ string: String) -> String {
        var allowedCharacters = CharacterSet.alphanumerics
        allowedCharacters.insert(".")
        return string.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? ""
    }
}

