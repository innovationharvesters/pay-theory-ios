//
//  ACHFields.swift
//  PayTheory
//
//  Created by Austin Zani on 3/15/21.
//
import SwiftUI
import Foundation
import Combine

class BankAccount: ObservableObject, Equatable {
    static func == (lhs: BankAccount, rhs: BankAccount) -> Bool {
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
    private var isValidCancellable: AnyCancellable!
    private var type = "BANK_ACCOUNT"
    
    var validBankCode: AnyPublisher<Bool,Never> {
        return $bankCode
            .map { code in
                if code.count != 9 {
                    return false
                }
                
                var number = 0
                for num in stride(from: 0, to: code.count, by: 3) {
                    if let first = Int(code[num]) {
                        number += (first * 3)
                    } else {
                        return false
                    }
                    
                    if let second = Int(code[num + 1]) {
                        number += (second * 7)
                    } else {
                        return false
                    }
                    
                    if let third = Int(code[num + 2]) {
                        number += (third * 1)
                    } else {
                        return false
                    }
                }
                
                return number > 0 && number % 10 == 0
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
    
    var isValidPublisher: AnyPublisher<Bool,Never> {
        return Publishers.CombineLatest4($name, $accountType, validBankCode, validAccountNumber)
            .map { name, type, validCode, validNumber in
                if validCode == false || validNumber == false || name.isEmpty || type > 1 {
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
