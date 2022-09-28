//
//  CommonUI.swift
//  PayTheory
//
//  Created by Austin Zani on 7/23/21.
//

import SwiftUI

/// This is used to wrap an ancestor view to allow the TextFields and Buttons to access the data needed.
///
/// - Requires: Needs to have the PayTheory Object that was initialized with the API Key passed as an EnvironmentObject
///
/**
  ````
 let pt = PayTheory(apiKey: 'your-api-key')

 PTForm{
     AncestorView()
 }.EnvironmentObject(pt)
  ````
 */
public struct PTForm<Content>: View where Content: View {

    let content: () -> Content
    @EnvironmentObject var payTheory: PayTheory

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        Group {
            content()
        }.environmentObject(payTheory.envCard)
        .environmentObject(payTheory.envPayor)
        .environmentObject(payTheory.envAch)
        .environmentObject(payTheory.envCash)
    }
}
