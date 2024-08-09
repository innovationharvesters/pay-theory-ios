//
//  CashFields.swift
//  PayTheory
//
//  Created by Austin Zani on 7/20/21.
//

import SwiftUI
import Combine

class Cash: ObservableObject, PaymentMethod {
    @Published var name = ""
    @Published var contact = ""
    @Published var isValid: Bool = false
    @Published var isVisible: Bool = false
    private var isValidCancellable: AnyCancellable!
    
    var validName: AnyPublisher<Bool,Never> {
        return $name
            .map { name in
                return name.length > 0
              }
            .eraseToAnyPublisher()
    }
    
    var validContact: AnyPublisher<Bool,Never> {
        return $contact
            .map { contact in
                let validEmail = isValidEmail(value: contact)
                let validPhone = isValidPhone(value: contact)
                return validPhone || validEmail
              }
            .eraseToAnyPublisher()
    }
    
    var isValidPublisher: AnyPublisher<Bool,Never> {
        return Publishers.CombineLatest(validName, validContact)
            .map { name, contact in
                if name == false || contact == false {
                    return false
                }
                return true
            }
            .eraseToAnyPublisher()
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
        self.contact = ""
    }
}


/// TextField that can be used to capture the Name for Cash to be used in a Pay Theory barcode creation
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCashName: View {
    @EnvironmentObject var cash: Cash
    let placeholder: String
    
    /// Initializes a new instance of the view with a placeholder text.
    ///
    /// - Parameter placeholder: A `String` that represents the placeholder text for the text field. The default value is "Full Name".
    public init(placeholder: String = "Full Name") {
        self.placeholder = placeholder
    }
    
    public var body: some View {
        TextField(placeholder, text: $cash.name)
            .autocapitalization(UITextAutocapitalizationType.words)
            .trackVisibility(cash)
    }
}

/// TextField that can be used to capture the Contact for Cash to be used in a Pay Theory barcode creation
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCashContact: View {
    @EnvironmentObject var cash: Cash
    let placeholder: String
    
    /// Initializes a new instance of the view with a placeholder text.
    ///
    /// - Parameter placeholder: A `String` that represents the placeholder text for the text field. The default value is "Phone or Email".
    public init(placeholder: String = "Phone or Email") {
        self.placeholder = placeholder
    }
    
    public var body: some View {
        TextField(placeholder, text: $cash.contact)
    }
}


