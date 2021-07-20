//
//  CashFields.swift
//  PayTheory
//
//  Created by Austin Zani on 7/20/21.
//

import SwiftUI

/// TextField that can be used to capture the Name for Cash to be used in a Pay Theory barcode creation
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCashName: View {
    @EnvironmentObject var cash: Cash
    public init() {
    }
    
    public var body: some View {
        TextField("Full Name", text: $cash.name)
            .autocapitalization(UITextAutocapitalizationType.words)
    }
}

/// TextField that can be used to capture the Contact for Cash to be used in a Pay Theory barcode creation
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCashContact: View {
    @EnvironmentObject var cash: Cash
    public init() {
    }
    
    public var body: some View {
        TextField("Phone or Email", text: $cash.contact)
    }
}


