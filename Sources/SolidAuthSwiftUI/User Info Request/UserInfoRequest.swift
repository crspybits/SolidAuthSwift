//
//  UserInfoRequest.swift
//  
//
//  Created by Christopher G Prince on 9/19/21.
//

import Foundation

// See https://openid.net/specs/openid-connect-core-1_0.html#UserInfo

// Note that at least as of 9/19/21, this is not working on NSS: See https://github.com/solid/node-solid-server/issues/1490 and comments below. And for https://broker.pod.inrupt.com, it's not returning a webid.

public class UserInfoRequest {
    let endpoint: URL
    let accessToken: String
    
    enum UserInfoRequestError: Error {
        case noUserInfoEndpoint
        case noResponseData
        case badStatusCode(Int)
        case noHTTPURLResponse
    }
    
    public init(accessToken: String, configuration: ProviderConfiguration) throws {
        guard let endpoint = configuration.userinfoEndpoint else {
            throw UserInfoRequestError.noUserInfoEndpoint
        }
        
        self.endpoint = endpoint
        self.accessToken = accessToken
    }
    
    // "5.3.1. UserInfo Request" (https://openid.net/specs/openid-connect-core-1_0.html#UserInfo)
    // NSLocalizedDescription=The request timed out., NSErrorFailingURLStringKey=https://solidcommunity.net/userinfo, NSErrorFailingURLKey=https://solidcommunity.net/userinfo, _kCFStreamErrorDomainKey=4}
    // NSLocalizedDescription=The request timed out., NSErrorFailingURLStringKey=https://inrupt.net/userinfo, NSErrorFailingURLKey=https://inrupt.net/userinfo, _kCFStreamErrorDomainKey=4}
    // From https://broker.pod.inrupt.com I get: Response: UserInfoResponse(sub: "crspybits", website: nil, name: nil, given_name: nil, family_name: nil, preferred_username: nil, email: nil)
    public func send(queue: DispatchQueue = .main, completion: @escaping (Result<UserInfoResponse, Error>) -> Void) {
    
        func callCompletion(_ result: Result<UserInfoResponse, Error>) {
            queue.async {
                completion(result)
            }
        }

        let kBearer = "Bearer"
        let kHTTPAuthorizationHeaderKey = "Authorization"
        let httpMethod = "GET"
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = httpMethod
        request.setValue("\(kBearer) \(accessToken)", forHTTPHeaderField: kHTTPAuthorizationHeaderKey)

        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
        session.dataTask(with: request, completionHandler: { data, response, error in
            if let error = error {
                callCompletion(.failure(error))
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                callCompletion(.failure(UserInfoRequestError.noHTTPURLResponse))
                return
            }
            
            if let data = data {
                let str = String(data: data, encoding: .utf8)
                print("String: \(String(describing: str))")
            }
            
            guard NetworkingExtras.statusCodeOK(response.statusCode) else {
                callCompletion(.failure(UserInfoRequestError.badStatusCode(response.statusCode)))
                return
            }
            
            guard let data = data else {
                callCompletion(.failure(UserInfoRequestError.noResponseData))
                return
            }
            
            let userInfoResponse: UserInfoResponse
            do {
                userInfoResponse = try JSONDecoder().decode(UserInfoResponse.self, from: data)
            } catch let error {
                callCompletion(.failure(error))
                return
            }
            
            callCompletion(.success(userInfoResponse))
        }).resume()
    }
}
