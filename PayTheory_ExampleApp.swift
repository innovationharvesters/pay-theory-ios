//
//  PayTheory_ExampleApp.swift
//  PayTheory Example
//
//  Created by Austin Zani on 11/4/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import SwiftUI
import PayTheory

@main
struct PayTheory_ExampleApp: App {
    let pt = PayTheory(apiKey: "pt-sandbox-dev-f992c4a57b86cb16aefae30d0a450237", tags: ["Test Tag" : "Test Value"], environment: .DEV, fee_mode: .SERVICE_FEE)
    
    
    var body: some Scene {
        WindowGroup {
            PTForm{
                ContentView()
            }.environmentObject(pt)
        }
    }
}
