//
//  ACHFields.swift
//  PayTheory
//
//  Created by Austin Zani on 3/15/21.
//
import SwiftUI
import Foundation

/// TextField that can be used to capture the Country for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTAchAccountName: View {
    @EnvironmentObject var account: BankAccount
    public init() {
        
    }
    
    public var body: some View {
        TextField("Name on Account", text: $account.name)
            .autocapitalization(UITextAutocapitalizationType.words)
    }
}

/// TextField that can be used to capture the Country for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTAchAccountNumber: View {
    @EnvironmentObject var account: BankAccount
    public init() {
        
    }
    
    public var body: some View {
        TextField("Account Number", text: $account.accountNumber)
            .keyboardType(.decimalPad)
    }
}

/// TextField that can be used to capture the Country for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTAchAccountType: View {
    @EnvironmentObject var account: BankAccount
    var types = ["Checking", "Savings"]
    public init() {
        
    }
    
    public var body: some View {
        Picker("Account Type", selection: $account.accountType) {
            ForEach(0 ..< types.count) {
                Text(self.types[$0])
            }
        }.pickerStyle(SegmentedPickerStyle())
    }
}

/// TextField that can be used to capture the Country for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTAchRoutingNumber: View {
    @EnvironmentObject var account: BankAccount
    public init() {
        
    }
    
    public var body: some View {
        TextField("Routing Number", text: $account.bankCode)
            .keyboardType(.decimalPad)
    }
}
