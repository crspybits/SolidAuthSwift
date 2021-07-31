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

// grant_type=refresh_token
// See https://datatracker.ietf.org/doc/html/draft-ietf-oauth-dpop

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
        case refreshToken = "refresh_token"
        case codeVerifier = "code_verifier"
        case code
        case redirectUri = "redirect_uri"
        case clientId = "client_id"
    }
    
    let requestType: TokenRequestType
    let jwk: JWK
    let privateKey: String
    
    /**
     * Parameters:
     *   requestType: You should first make a .code request and then as needed with the resulting refresh token, do .refresh requests when the access token expires.
     *   jwk: The public key
     *   privateKey: The private key
     */
    public init(requestType: TokenRequestType, jwk: JWK, privateKey: String) {
        self.requestType = requestType
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
        let bodyClaims = BodyClaims(htu: requestType.basics.tokenEndpoint.absoluteString, htm: httpMethod, jti: UUID().uuidString)
        let dpop = DPoP(jwk: jwk, privateKey: privateKey, body: bodyClaims)
        
        let dpopHeader: String
        
        do {
            dpopHeader = try dpop.generate()
        } catch let error {
            callCompletion(.failure(error))
            return
        }

        let bodyData = self.body()
        
        var request = URLRequest(url: requestType.basics.tokenEndpoint)
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
//#if false
            if let data = data {
                let str = String(data: data, encoding: .utf8)
                print("String: \(String(describing: str))")
            }
//#endif
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
        var values = [URLQueryItem]()

        values += [
            URLQueryItem(name: Keys.grantType.rawValue, value: requestType.basics.grantType),
        ]
        
        switch requestType {
        case .code(let code):
            values += [
                URLQueryItem(name: Keys.codeVerifier.rawValue, value: code.codeVerifier),
                URLQueryItem(name: Keys.code.rawValue, value: code.code),
                URLQueryItem(name: Keys.redirectUri.rawValue, value: code.redirectUri),
            ]
        case .refresh(let refresh):
            values += [
                URLQueryItem(name: Keys.refreshToken.rawValue, value: refresh.refreshToken),
            ]
        }

        // Common body parameters
        values += [
            URLQueryItem(name: Keys.clientId.rawValue, value: requestType.basics.clientId),
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

