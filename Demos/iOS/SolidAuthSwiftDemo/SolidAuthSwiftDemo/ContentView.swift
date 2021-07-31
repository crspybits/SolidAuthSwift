//
//  ContentView.swift
//  SolidAuthSwiftDemo
//
//  Created by Christopher G Prince on 7/28/21.
//

import SwiftUI

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
                Button(action: {
                    client.start()
                }, label: {
                    Text("Sign In")
                        .font(.title)
                        .disabled(!client.initialized)
                })
                
                Spacer().frame(height: spacerHeight)
                
                Button(action: {
                    if let params = client.response?.parameters {
                        server.requestTokens(params: params)
                    }
                }, label: {
                    Text("Request tokens")
                        .font(.title)
                        .disabled(!client.initialized || client.response == nil)
                })

                Spacer().frame(height: spacerHeight)
                    
                Button(action: {
                    if let jwksURL = client.response?.parameters.jwksURL {
                        server.validateAccessToken(jwksURL: jwksURL)
                    }
                }, label: {
                    Text("Validate tokens")
                        .font(.title)
                        .disabled(!client.initialized || client.response == nil)
                })
                
                Spacer().frame(height: spacerHeight)

                Button(action: {
                    if let refreshParams = server.refreshParams {
                        server.refreshTokens(params: refreshParams)
                    }
                }, label: {
                    Text("Refresh tokens")
                        .font(.title)
                        .disabled(!client.initialized || client.response == nil || server.refreshParams == nil)
                })
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
