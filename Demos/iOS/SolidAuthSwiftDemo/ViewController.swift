//
//  ViewController.swift
//  SolidAuthSwiftDemo
//
//  Created by Christopher G Prince on 7/24/21.
//

import UIKit
import SolidAuthSwiftUI
import Logging

class ViewController: UIViewController {
    let config = SignInConfiguration(
        issuer: "https://solidcommunity.net",
        redirectURI: "biz.SpasticMuffin.Neebla.demo:/mypath",
        clientName: "Neebla",
        scopes: [.openid, .profile, .webid, .offlineAccess],
        responseTypes:  [.code, .token])
    var controller: SignInController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let controller = try? SignInController(config: config) else {
            logger.error("Could not initialize Controller")
            return
        }
        
        // Retain the controller because it does async operations.
        self.controller = controller
        
        controller.start() { result in
            switch result {
            case .failure(let error):
                logger.error("Sign In Controller failed: \(error)")
                
            case .success(let response):
                logger.debug("**** Sign In Controller succeeded ****: \(response)")
            }
        }
    }
}
