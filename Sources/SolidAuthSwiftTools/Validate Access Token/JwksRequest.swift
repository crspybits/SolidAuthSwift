//
//  JwksRequest.swift
//  
//
//  Created by Christopher G Prince on 7/27/21.
//

import Foundation

public struct JwksRequest {
    enum JwksRequestError: Error {
        case noHTTPURLResponse
        case badStatusCode(Int)
        case noResponseData
    }
    
    let jwksURL: URL
    
    public init(jwksURL: URL) {
        self.jwksURL = jwksURL
    }
    
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
            
            let jwksResponse: JwksResponse
            do {
                jwksResponse = try JSONDecoder().decode(JwksResponse.self, from: data)
            } catch let error {
                callCompletion(.failure(error))
                return
            }
            
            callCompletion(.success(jwksResponse))
        }).resume()
    }
}
