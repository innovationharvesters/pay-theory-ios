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
    @ObservedObject var ptObject = PayTheory(apiKey: "austin-paytheorylab-d7dbe665f5565fe8ae8a23eab45dd285")
    
    var body: some Scene {
        WindowGroup {
            PTForm{
                ContentView()
            }
            .environmentObject(ptObject)
        }
    }
}
