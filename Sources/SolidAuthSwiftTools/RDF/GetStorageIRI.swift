//
//  GetStorageIRI.swift
//  
//
//  Created by Christopher G Prince on 9/6/21.
//

import Foundation
import SerdParser

// The purpose of this class is to get the default storage "host URL" given a users webid. I'm not sure storage "host URL" is the right term, but I mean the base URL to use when forming requests to a users Pod. See also discussion here: https://github.com/SyncServerII/ServerSolidAccount/issues/4

public class GetStorageIRI {
    enum GetStorageIRIError: Error {
        case noHTTPURLResponse
        case badStatusCode(Int)
        case noResponseData
        case couldNotConvertDataToString
        case badURLForSpaceStorageIRI
        case noWebIdHost
    }
    
    private let webid: URL

    public init(webid: URL) {
        self.webid = webid
    }
    
    // If there is no storage IRI in the profile, this will return nil.
    public func get(queue: DispatchQueue = .main, completion: @escaping (Result<URL?, Error>)->()) {

        func callCompletion(_ result: Result<URL?, Error>) {
            queue.async {
                completion(result)
            }
        }
        
        let request = URLRequest(url: webid)

        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
        session.dataTask(with: request, completionHandler: { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                callCompletion(.failure(error))
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                callCompletion(.failure(GetStorageIRIError.noHTTPURLResponse))
                return
            }
            
            guard NetworkingExtras.statusCodeOK(response.statusCode) else {
                callCompletion(.failure(GetStorageIRIError.badStatusCode(response.statusCode)))
                return
            }
            
            guard let data = data else {
                callCompletion(.failure(GetStorageIRIError.noResponseData))
                return
            }
            
            guard let rdfString = String(data: data, encoding: .utf8) else {
                callCompletion(.failure(GetStorageIRIError.couldNotConvertDataToString))
                return
            }
            
            do {
                let storageURI = try self.getStorageURI(from: rdfString)
                callCompletion(.success(storageURI))
            } catch let error {
                callCompletion(.failure(error))
            }
        }).resume()
    }
    
    func getStorageURI(from rdf: String) throws -> URL? {
        let parser = SerdParser()

        var storage: String?
        
        try parser.parse(string: rdf) { (s, p, o) in
            if case .iri("http://www.w3.org/ns/pim/space#storage") = p {
                print("storage: s: \(s); p: \(p): \(o)")
                let object: RDFTerm = o
                switch object {
                case .blank(let str):
                    print("storage: blank: \(str)")
                case .datatype(let s1, let s2):
                    print("storage: datatype: \(s1), \(s2)")
                case .iri(let str):
                    // I expect this to be the one I get.
                    print("storage: iri: \(str)")
                    storage = str
                case .language(let s1, let s2):
                    print("storage: language: \(s1), \(s2)")
                }
            }
        }
        
        guard let storage = storage else {
            return nil
        }
        
        if storage == "/" {
            guard let host = webid.host else {
                throw GetStorageIRIError.noWebIdHost
            }
            
            guard let result = URL(string: host) else {
                throw GetStorageIRIError.badURLForSpaceStorageIRI
            }
            
            return result
        }
        
        guard let result = URL(string: storage) else {
            throw GetStorageIRIError.badURLForSpaceStorageIRI
        }
        
        return result
    }
}

