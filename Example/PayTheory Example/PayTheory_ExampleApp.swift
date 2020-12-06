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
    let pt = PayTheory(apiKey: "pt-sandbox-dev-d9de9154964990737db2f80499029dd6")
    
    
    var body: some Scene {
        WindowGroup {
            PTForm{
                ContentView()
            }.environmentObject(pt)
        }
    }
}
