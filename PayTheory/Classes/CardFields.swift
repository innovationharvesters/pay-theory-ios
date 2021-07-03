//
//  CardFields.swift
//  PayTheory
//
//  Created by Austin Zani on 3/15/21.
//
import SwiftUI
import Foundation

/// TextField that can be used to capture the Name for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCardName: View {
    @EnvironmentObject var card: PaymentCard
    public init() {
    }

    public var body: some View {
        TextField("Name on Card", text: $card.name ?? "")
            .autocapitalization(UITextAutocapitalizationType.words)
    }
}

/// TextField that can be used to capture the Card Number for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
///  - Important: This is required to be able to run a transaction.
///
public struct PTCardNumber: View {
    @EnvironmentObject var card: PaymentCard
    public init() {
        
    }
    public var body: some View {
        TextField("Card Number", text: $card.number)
            .keyboardType(.decimalPad)
            
    }
}

/// TextField that can be used to capture the Expiration Year for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
///  - Important: This is required to be able to run a transaction.
///
public struct PTExp: View {
    @EnvironmentObject var card: PaymentCard
    public init() {
        
    }
    public var body: some View {
        TextField("MM / YY", text: $card.expirationDate)
            .keyboardType(.decimalPad)
    }
}

/// TextField that can be used to capture the CVV for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
///  - Important: This is required to be able to run a transaction.
///
public struct PTCvv: View {
    @EnvironmentObject var card: PaymentCard
    public init() {
        
    }
    public var body: some View {
        TextField("CVV", text: $card.securityCode)
            .keyboardType(.decimalPad)
    }
}

/// TextField that can be used to capture the Address Line 1 for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCardLineOne: View {
    @EnvironmentObject var card: PaymentCard
    public init() {
        
    }
    
    public var body: some View {
        TextField("Address Line 1", text: $card.address.line1 ?? "")
            .autocapitalization(UITextAutocapitalizationType.words)
    }
}

/// TextField that can be used to capture the Address Line 2 for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCardLineTwo: View {
    @EnvironmentObject var card: PaymentCard
    public init() {
        
    }
    
    public var body: some View {
        TextField("Address Line 2", text: $card.address.line2 ?? "")
    }
}

/// TextField that can be used to capture the City for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCardCity: View {
    @EnvironmentObject var card: PaymentCard
    public init() {
        
    }
    
    public var body: some View {
        TextField("City", text: $card.address.city ?? "")
    }
}

/// TextField that can be used to capture the State for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCardState: View {
    @EnvironmentObject var card: PaymentCard
    public init() {
        
    }
    
    public var body: some View {
        TextField("State", text: $card.address.region ?? "")
            .autocapitalization(UITextAutocapitalizationType.allCharacters)
            .disableAutocorrection(true)
    }
}

/// TextField that can be used to capture the Zip for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCardZip: View {
    @EnvironmentObject var card: PaymentCard
    public init() {
        
    }
    
    public var body: some View {
        TextField("Zip", text: $card.address.postalCode ?? "")
            .keyboardType(.decimalPad)
    }
}

/// TextField that can be used to capture the Country for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCardCountry: View {
    @EnvironmentObject var card: PaymentCard
    public init() {
        
    }
    
    public var body: some View {
        TextField("Country", text: $card.address.country ?? "")
    }
}

/// TextField that can be used to capture the Country for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCombinedCard: View {
    public init() {
        
    }
    
    public var body: some View {
        HStack() {
            PTCardNumber()
                .frame(minWidth: 200)
            Spacer()
            HStack {
                PTExp()
            Spacer()
                PTCvv()
            }
        }
    }
}
