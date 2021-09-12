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

public enum TokenEndpointAuthenticationMethod: String, Codable {
    case basic = "client_secret_basic"
    case post = "client_secret_post"
    // Not implementing jwt yet. And not sure what to use for `TokenEndpointAuthenticationMethod` if I use the DPoP header as indicated in https://solid.github.io/solid-oidc/primer/#authorization-code-pkce-flow-step-14
}

extension TokenEndpointAuthenticationMethod {
    // Use this for `TokenEndpointAuthenticationMethod` `basic`
    // See "1.4. client_secret_basic" of https://darutk.medium.com/oauth-2-0-client-authentication-4b5f929305d4
    // and section 3.1.3.1 of https://openid.net/specs/openid-connect-core-1_0.html#ClientAuthentication
    func basicAuthorizationHeaderValue(clientId: String, clientSecret: String) -> String {
        let string = "\(clientId):\(clientSecret)"
        let base64 = Data(string.utf8).base64EncodedString()
        return "Basic \(base64)"
    }
}
    
// grant_type=authorization_code
// https://solid.github.io/solid-oidc/primer/#authorization-code-pkce-flow-step-14

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
        case clientSecret = "client_secret"
        case authorization
        case contentType = "content-type"
    }
    
    let requestType: TokenRequestType
    let jwk: JWK
    let privateKey: String
    
    /**
     * Parameters:
     *   requestType:
     *      You should first make a .code request and then as needed with the resulting refresh token, do .refresh requests when the access token expires.
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

        let bodyData: Data
        do {
            bodyData = try self.body()
        } catch let error {
            callCompletion(.failure(error))
            return
        }
        
        var request = URLRequest(url: requestType.basics.tokenEndpoint)
        request.httpMethod = httpMethod
        request.httpBody = bodyData
        
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: Keys.contentType.rawValue)
                
        switch requestType.basics.authenticationMethod {
        case .basic:
            let headerValue = requestType.basics.authenticationMethod.basicAuthorizationHeaderValue(clientId: requestType.basics.clientId, clientSecret: requestType.basics.clientSecret)
            request.addValue(headerValue, forHTTPHeaderField: Keys.authorization.rawValue)
        case .post:
            break
        }
        
        // Not sure what authentication method should cause this to happen.
        /*
        do {
            try addDPoPHeader(to: &request, tokenEndpoint: requestType.basics.tokenEndpoint, httpMethod: httpMethod)
        } catch let error {
            callCompletion(.failure(error))
            return
        }
        */
        
        print("request: \(String(describing: request.url))")
        print("request.allHTTPHeaderFields: \(String(describing: request.allHTTPHeaderFields))")

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
            
            if let data = data {
                let str = String(data: data, encoding: .utf8)
                print("String: \(String(describing: str))")
            }
            
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

    func body() throws -> Data {
        var values = [URLQueryItem]()

        values += [
            URLQueryItem(name: Keys.grantType.rawValue, value: requestType.basics.grantType),
        ]
        
        switch requestType.basics.authenticationMethod {
        case .basic:
            break
        case .post:            
            values += [
                URLQueryItem(name: Keys.clientSecret.rawValue, value: requestType.basics.clientSecret),
            ]
        }
        
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

extension TokenRequest {
    func addDPoPHeader(to request: inout URLRequest, tokenEndpoint: URL, httpMethod: String) throws {
        let htu = tokenEndpoint.absoluteString

        let bodyClaims = BodyClaims(htu: htu, htm: httpMethod, jti: UUID().uuidString)
        let dpop = DPoP(jwk: jwk, privateKey: privateKey, body: bodyClaims)

        let dpopHeader = try dpop.generate()
        
        request.addValue(dpopHeader, forHTTPHeaderField: DPoPHttpHeaderKey)
    }
}
