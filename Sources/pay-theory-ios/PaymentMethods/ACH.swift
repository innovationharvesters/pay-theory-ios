//
//  ACHFields.swift
//  PayTheory
//
//  Created by Austin Zani on 3/15/21.
//
import SwiftUI
import Foundation
import Combine

class ACH: ObservableObject, Equatable {
    static func == (lhs: ACH, rhs: ACH) -> Bool {
        if lhs.name == rhs.name &&
        lhs.accountNumber == rhs.accountNumber &&
        lhs.accountType == rhs.accountType &&
        lhs.bankCode == rhs.bankCode &&
        lhs.country == rhs.country &&
        lhs.identity == rhs.identity &&
            lhs.type == rhs.type {
            return true
        }
        
        return false
    }
    
    @Published var name = ""
    @Published var accountNumber = ""
    @Published var accountType = 0
    @Published var bankCode = ""
    @Published var country: String?
    @Published var identity = ""
    @Published var isValid: Bool = false
    @Published var isVisible: Bool = false
    private var isValidCancellable: AnyCancellable!
    private var type = "ach"
    
    var validBankCode: AnyPublisher<Bool,Never> {
        return $bankCode
            .map { code in
                return isValidRoutingNumber(code: code)
            }
            .eraseToAnyPublisher()
    }
    
    var validAccountNumber: AnyPublisher<Bool,Never> {
        return $accountNumber
            .map { number in
                let num = Int(number)
                return num != nil && number.isEmpty == false
            }
            .eraseToAnyPublisher()
    }
    
    var validAccountName: AnyPublisher<Bool,Never> {
        return $name
            .map { name in
                return !name.isEmpty
            }
            .eraseToAnyPublisher()
    }
    
    var isValidPublisher: AnyPublisher<Bool,Never> {
        return Publishers.CombineLatest4(validAccountName, $accountType, validBankCode, validAccountNumber)
            .map { name, type, validCode, validNumber in
                if validCode == false || validNumber == false || name == false || type > 1 {
                    return false
                }
                return true
            }
            .eraseToAnyPublisher()
    }
    
    var lastFour: String {
        return String(accountNumber.suffix(4))
    }
    
    init() {
        isValidCancellable = isValidPublisher.sink { isValid in
                    self.isValid = isValid
                }
    }
    
    deinit {
        isValidCancellable.cancel()
    }
    
    func clear() {
        self.name = ""
        self.accountType = 0
        self.accountNumber = ""
        self.bankCode = ""
    }
    
}

/// TextField that can be used to capture the Country for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTAchAccountName: View {
    @EnvironmentObject var account: ACH
    let placeholder: String
    
    /// Initializes a new instance of the view with a placeholder text.
    ///
    /// - Parameter placeholder: A `String` that represents the placeholder text for the text field. The default value is "Name on Account".
    public init(placeholder: String = "Name on Account") {
        self.placeholder = placeholder
    }
    
    public var body: some View {
        TextField(placeholder, text: $account.name)
            .autocapitalization(UITextAutocapitalizationType.words)
    }
}

/// TextField that can be used to capture the Country for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTAchAccountNumber: View {
    @EnvironmentObject var account: ACH
    let placeholder: String
    
    /// Initializes a new instance of the view with a placeholder text.
    ///
    /// - Parameter placeholder: A `String` that represents the placeholder text for the text field. The default value is "Account Number".
    public init(placeholder: String = "Account Number") {
        self.placeholder = placeholder
    }
    
    public var body: some View {
        TextField(placeholder, text: $account.accountNumber)
            .keyboardType(.decimalPad)
    }
}

/// TextField that can be used to capture the Country for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTAchAccountType: View {
    @EnvironmentObject var account: ACH
    var types = ["Checking", "Savings"]
    public init() {
    }
    
    public var body: some View {
        Picker("Account Type", selection: $account.accountType) {
            ForEach(types, id: \.self) {type in
                Text(type)
            }
        }.pickerStyle(SegmentedPickerStyle())
    }
}

/// TextField that can be used to capture the Country for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTAchRoutingNumber: View {
    @EnvironmentObject var account: ACH
    let placeholder: String
    
    /// Initializes a new instance of the view with a placeholder text.
    ///
    /// - Parameter placeholder: A `String` that represents the placeholder text for the text field. The default value is "Routing Number".
    public init(placeholder: String = "Routing Number") {
        self.placeholder = placeholder
    }
    
    public var body: some View {
        TextField(placeholder, text: $account.bankCode)
            .keyboardType(.decimalPad)
            .onAppear {
                account.isVisible = true
            }
            .onDisappear {
                account.isVisible = false
            }
    }
}
