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

// grant_type=authorization_code
// See https://solid.github.io/authentication-panel/solid-oidc-primer/#authorization-code-pkce-flow-step-14

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
    
    enum Values: String {
        case authorizationCode = "authorization_code"
        case refreshToken = "refresh_token"
    }
    
    let parameters: TokenRequestParameters
    let jwk: JWK
    let privateKey: String
    
    public init(parameters: TokenRequestParameters, jwk: JWK, privateKey: String) {
        self.parameters = parameters
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
        let bodyClaims = BodyClaims(htu: parameters.tokenEndpoint.absoluteString, htm: httpMethod, jti: UUID().uuidString)
        let dpop = DPoP(jwk: jwk, privateKey: privateKey, body: bodyClaims)
        
        let dpopHeader: String
        
        do {
            dpopHeader = try dpop.generate()
        } catch let error {
            callCompletion(.failure(error))
            return
        }

        let bodyData = self.body()
        
        var request = URLRequest(url: parameters.tokenEndpoint)
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
            URLQueryItem(name: Keys.codeVerifier.rawValue, value: parameters.codeVerifier),
            URLQueryItem(name: Keys.code.rawValue, value: parameters.code),
            URLQueryItem(name: Keys.redirectUri.rawValue, value: parameters.redirectUri),
            URLQueryItem(name: Keys.clientId.rawValue, value: parameters.clientId),
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

