//
//  CommonUI.swift
//  PayTheory
//
//  Created by Austin Zani on 7/23/21.
//

import SwiftUI

/// Button that allows a payment to be tokenized once it has the necessary data
/// (Card Number, Expiration Date, and CVV)
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///  - Parameters:
///   - amount: Payment amount that should be charged to the card in cents.
///   - text: String that will be the label for the button.
///   - completion: Function that will handle the result of the
///   tokenization response once it has been returned from the server.
public struct PTButton: View {
    @EnvironmentObject var card: PaymentCard
    @EnvironmentObject var envBuyer: Buyer
    @EnvironmentObject var payTheory: PayTheory
    @EnvironmentObject var bank: BankAccount
    @EnvironmentObject var transaction: Transaction
    @EnvironmentObject var cash: Cash
    
    var completion: (Result<[String: Any], FailureResponse>) -> Void
    var amount: Int
    var text: String
    var buyer: Buyer?
    var onClick: () -> Void
    
    /// Button that allows a payment to be tokenized once it has the necessary data
    /// (Card Number, Expiration Date, and CVV)
    ///
    /// - Parameters:
    ///   - amount: Payment amount that should be charged to the card in cents.
    ///   - text: String that will be the label for the button.
    ///   - completion: Function that will handle the result of the
    ///   tokenization response once it has been returned from the server.
    public init(amount: Int,
                text: String = "Confirm",
                buyerOptions: Buyer? = nil,
                onClick: @escaping () -> Void = {return},
                completion: @escaping (Result<[String: Any], FailureResponse>) -> Void) {
        
        self.completion = completion
        self.amount = amount
        self.text = text
        self.onClick = onClick
        self.buyer = buyerOptions
    }
    
    public var body: some View {
        Button {
                onClick()
                if card.isValid {
                        payTheory.tokenize(card: card,
                                           amount: amount,
                                           buyerOptions: buyer ?? envBuyer,
                                           completion: completion)
                } else if bank.isValid {
                        payTheory.tokenize(bank: bank,
                                           amount: amount,
                                           buyerOptions: buyer ?? envBuyer,
                                           completion: completion)
                } else if cash.isValid {
                        payTheory.tokenize(cash: cash,
                                           amount: amount,
                                           buyerOptions: buyer ?? envBuyer,
                                           completion: completion)
                }
        } label: {
            HStack {
                Spacer()
                Text(text)
                Spacer()
            }
        }
        .disabled(payTheory.buttonDisabled)
    }
}

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
        .environmentObject(payTheory.envBuyer)
        .environmentObject(payTheory.envAch)
        .environmentObject(payTheory.transaction)
        .environmentObject(payTheory.envCash)
    }
}
