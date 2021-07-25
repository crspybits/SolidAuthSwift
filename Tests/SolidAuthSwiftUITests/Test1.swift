//
//  SolidAuthSwiftUITests.swift
//  
//
//  Created by Christopher G Prince on 7/24/21.
//

import Foundation
import SolidAuthSwiftUI
import XCTest

final class SolidAuthSwiftUITests: XCTestCase {
    let validAuthConfig = AuthorizationConfiguration(issuer: "https://solidcommunity.net")
    let invalidAuthConfig = AuthorizationConfiguration(issuer: "https://google.com")

    // MARK: AuthenticationConfiguration
    
    func testAuthorizationConfigurationWorks() {
        let exp = expectation(description: "exp")
        
        validAuthConfig.fetch { result in
            switch result {
            case .success(let config):
                XCTAssertNotNil(config.authorizationEndpoint)
                XCTAssertNotNil(config.tokenEndpoint)
                XCTAssertNotNil(config.issuer)
                XCTAssertNotNil(config.registrationEndpoint)
               
            case .failure(let error):
                XCTFail("\(error)")
            }
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testAuthorizationConfigurationFails() {
        let exp = expectation(description: "exp")
        
        invalidAuthConfig.fetch { result in
            switch result {
            case .success:
                XCTFail()
               
            case .failure:
                break
            }
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
}
