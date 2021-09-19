//
//  ContentView.swift
//  SolidAuthSwiftDemo
//
//  Created by Christopher G Prince on 7/28/21.
//

import SwiftUI

struct DemoButton: View {
    let spacerHeight: CGFloat?
    let text: String
    let action:()->()
    
    var body: some View {
        if let spacerHeight = spacerHeight {
            Spacer().frame(height: spacerHeight)
        }
        
        Button(action: {
            action()
        }, label: {
            Text(text)
                .font(.title)
        })
    }
}

struct ContentView: View {
    @StateObject var client = Client()
    @StateObject var server = Server()
    let spacerHeight: CGFloat = 25
    
    var body: some View {
        VStack {
            Spacer().frame(height: spacerHeight)
            Text("Testing Solid Auth Swift")
                .font(.largeTitle)
            
            Spacer()
            
            VStack {
                DemoButton(spacerHeight: nil, text: "Sign In") {
                    client.start() { refreshParameters in
                        server.refreshParams = refreshParameters
                    }
                }
                .disabled(!client.initialized)

                DemoButton(spacerHeight: spacerHeight, text: "Validate access token") {
                    if let accessToken = client.accessToken,
                        let jwksURL = client.response?.parameters.jwksURL {
                        server.validateToken(accessToken, jwksURL: jwksURL)
                    }
                }
                .disabled(!client.initialized || client.response == nil)
                        
                DemoButton(spacerHeight: spacerHeight, text: "Validate id token") {
                    if let idToken = client.idToken,
                        let jwksURL = client.response?.parameters.jwksURL {
                        server.validateToken(idToken, jwksURL: jwksURL)
                    }
                }
                .disabled(!client.initialized || client.response == nil)

                DemoButton(spacerHeight: spacerHeight, text: "Request user info") {
                    if let accessToken = client.accessToken,
                        let providerConfig = client.controller.providerConfig {
                        server.requestUserInfo(accessToken: accessToken, configuration: providerConfig)
                    }
                }
                .disabled(!client.initialized || client.response == nil)
                
                DemoButton(spacerHeight: spacerHeight, text: "Refresh tokens") {
                    if let refreshParams = server.refreshParams {
                        server.refreshTokens(params: refreshParams)
                    }
                }
                .disabled(!client.initialized || client.response == nil || server.refreshParams == nil)
        
                DemoButton(spacerHeight: spacerHeight, text: "Logout") {
                    client.logout()
                }
                .disabled(!client.initialized || client.response == nil ||
                    client.idToken == nil)
            }
            
            Spacer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
