//
//  SolidAuthSwiftDemoApp.swift
//  SolidAuthSwiftDemo
//
//  Created by Christopher G Prince on 7/28/21.
//

import SwiftUI
import Logging
import SolidAuthSwiftUI

@main
struct SolidAuthSwiftDemoApp: App {
    init() {
        logger = createLogger(label: "")
        logger.logLevel = .debug
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    func createLogger(label: String) -> Logger {
        LoggingSystem.bootstrap { label in
            let handlers:[LogHandler] = [
                StreamLogHandler.standardOutput(label: label)
            ]

            return MultiplexLogHandler(handlers)
        }
        
        return Logger(label: label)
    }
}
