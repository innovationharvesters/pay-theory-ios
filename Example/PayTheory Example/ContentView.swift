//
//  ContentView.swift
//  PayTheory Example
//
//  Created by Austin Zani on 11/4/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import SwiftUI
import PayTheory

struct ContentView: View {
    
    @State private var confirmationMessage = ""
    @State private var showingConfirmation = false
    @State private var showingMessage = false
    
    func completion(result: Result<TokenizationResponse, FailureResponse>){
        switch result {
            case .success(let token):
                var total: Double {
                    let total = Double(token.amount)
                    let fee = Double(token.convenience_fee)
                    return (total + fee) / 100
                }
                self.confirmationMessage = "Are you sure you want to charge $\(String(format:"%.2f", total)) to the card starting in \(token.first_six)?"
                self.showingConfirmation = true
            case .failure(let error):
                self.confirmationMessage = "Your tokenization failed! \(error.localizedDescription)"
                self.showingConfirmation = true
            }
    }
    
    func confirmCompletion(result: Result<CompletionResponse, FailureResponse>){
        switch result {
        case .success(let token):
            var total: Double {
                let total = Double(token.amount)
                let fee = Double(token.convenience_fee)
                return (total + fee) / 100
            }
            self.confirmationMessage = "You charged $\(String(format:"%.2f", total)) to card ending in \(token.last_four)"
            self.showingMessage = true
        case .failure(let response):
            self.confirmationMessage = "The transaction failed to confirm \(response.type)"
            self.showingMessage = true
        }
    }
    
    func cancelCompletion(result: Result<AuthorizationResponse, FailureResponse>){
        switch result {
        case .success(_):
            self.confirmationMessage = "You cancelled the transaciton!"
            self.showingMessage = true
        case .failure(let response):
            self.confirmationMessage = "The transaction failed to confirm \(response.type)"
            self.showingMessage = true
        }
    }
    

    let pt = PayTheory(apiKey: "")

    let card = PaymentCard(number: "4242424242424242", expiration_year: "2022", expiration_month: "12", cvv: "222")
    
    var body: some View {
        Button("Tokenize") {
            pt.tokenize(card: card, amount: 1000, buyerOptions: nil, merchant: "", completion: completion)
        }
        .padding(15)
        .border(Color.blue, width: 1)
        .disabled(card.hasRequiredFields == false)
        .alert(isPresented: $showingConfirmation) {
            Alert(title: Text("Confirm:"), message: Text(confirmationMessage), primaryButton: .default(Text("Confirm"), action: {
                pt.confirm(completion: confirmCompletion)
            }), secondaryButton: .cancel(Text("Cancel"), action: {
                pt.cancel(completion: cancelCompletion)
            }))
        }
        
        Button("Transact") {
            pt.transact(card: card, amount: 1000, buyerOptions: nil, merchant: "", completion: confirmCompletion)
        }
        .padding(15)
        .border(Color.blue, width: 1)
        .alert(isPresented: $showingMessage) {
            Alert(title: Text("Success!"), message: Text(confirmationMessage), dismissButton: .default(Text("Ok!")))
        }

    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
