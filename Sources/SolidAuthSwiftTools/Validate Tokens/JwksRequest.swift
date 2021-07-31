//
//  JwksRequest.swift
//  
//
//  Created by Christopher G Prince on 7/27/21.
//

import Foundation
import JWTKit
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public class JwksRequest {
    enum JwksRequestError: Error {
        case noHTTPURLResponse
        case badStatusCode(Int)
        case noResponseData
    }
    
    let jwksURL: URL
    
    /**
     * Parameters:
     *  jwksURL: See jwks_uri in https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderMetadata
     *  and https://datatracker.ietf.org/doc/html/draft-ietf-jose-json-web-key
     */
    public init(jwksURL: URL) {
        self.jwksURL = jwksURL
    }
    
    /**
     * Retrieve the JWK public keys from the Pod server. Doesn't need authentication.
     */
    public func send(queue: DispatchQueue = .main, completion: @escaping (Result<JwksResponse, Error>) -> Void) {
    
        func callCompletion(_ result: Result<JwksResponse, Error>) {
            queue.async {
                completion(result)
            }
        }
        
        var request = URLRequest(url: jwksURL)
        request.httpMethod = "GET"

        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
        session.dataTask(with: request, completionHandler: { data, response, error in
            if let error = error {
                callCompletion(.failure(error))
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                callCompletion(.failure(JwksRequestError.noHTTPURLResponse))
                return
            }
            
            guard NetworkingExtras.statusCodeOK(response.statusCode) else {
                callCompletion(.failure(JwksRequestError.badStatusCode(response.statusCode)))
                return
            }
            
            guard let data = data else {
                callCompletion(.failure(JwksRequestError.noResponseData))
                return
            }
            
            // let string = String(data: data, encoding: .utf8)
            // print("jwksResponse: \(String(describing: string))")
            
            let jwks: JWKS
            do {
                jwks = try JSONDecoder().decode(JWKS.self, from: data)
            } catch let error {
                callCompletion(.failure(error))
                return
            }

            callCompletion(.success(JwksResponse(jwks: jwks)))
        }).resume()
    }
}
