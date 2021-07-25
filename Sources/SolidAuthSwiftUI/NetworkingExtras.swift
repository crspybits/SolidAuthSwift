//
//  NetworkingExtras.swift.swift
//  
//
//  Created by Christopher G Prince on 7/24/21.
//

import Foundation

class NetworkingExtras {
    static func statusCodeOK(_ statusCode: Int) -> Bool {
        guard statusCode >= 200 && statusCode < 300 else {
            return false
        }
        return true
    }
}
