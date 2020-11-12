//
//  ContentView.swift
//  PayTheory Example
//
//  Created by Austin Zani on 11/4/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import SwiftUI
import PayTheory
import DeviceCheck
import CryptoKit

extension String {
//: ### Base64 encoding a string
    func base64Encoded() -> String? {
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString()
        }
        return nil
    }

//: ### Base64 decoding a string
    func base64Decoded() -> String? {
        if let data = Data(base64Encoded: self, options: .ignoreUnknownCharacters) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}

struct ContentView: View {
    
    @State private var confirmationMessage = ""
    @State private var showingConfirmation = false
    @State private var showingMessage = false
    
    let service = DCAppAttestService.shared
    
    func completion(result: Result<TokenizationResponse, FailureResponse>){
        switch result {
        case .success(let token):
                self.confirmationMessage = "Are you sure you want to charge $\(String(format:"%.2f", (Double(token.amount) / 100))) to the card starting in \(token.first_six)?"
                self.showingConfirmation = true
            case .failure(let error):
                self.confirmationMessage = "Your tokenization failed! \(error.localizedDescription)"
                self.showingConfirmation = true
            }
    }
    
    func confirmCompletion(result: Result<CompletionResponse, FailureResponse>){
        switch result {
        case .success(let token):
            self.confirmationMessage = "You charged $\(String(format:"%.2f", (Double(token.amount) / 100))) to card ending in \(token.last_four)"
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
    

    let pt = PayTheory(apiKey: "pt-sandbox-dev-d9de9154964990737db2f80499029dd6")

    let card = PaymentCard(number: "4242424242424242", expiration_year: "2022", expiration_month: "12", cvv: "222")
    
    var body: some View {
        Button("Tokenize") {
            pt.tokenize(card: card, amount: 1000, buyerOptions: nil, completion: completion)
        }
        .padding(15)
        .border(Color.blue, width: 1)
        .disabled(card.isValid == false)
        .alert(isPresented: $showingConfirmation) {
            Alert(title: Text("Confirm:"), message: Text(confirmationMessage), primaryButton: .default(Text("Confirm"), action: {
                pt.confirm(completion: confirmCompletion)
            }), secondaryButton: .cancel(Text("Cancel"), action: {
                pt.cancel(completion: cancelCompletion)
            }))
        }
        
//        Button("Transact") {
//            pt.transact(card: card, amount: 1000, buyerOptions: nil, merchant: "ID6VwLEBUieGoFJ5v6Vhrmdx", completion: confirmCompletion)
//        }
//        .padding(15)
//        .border(Color.blue, width: 1)
        HStack{
            
        }
        .alert(isPresented: $showingMessage) {
            Alert(title: Text("Success!"), message: Text(confirmationMessage), dismissButton: .default(Text("Ok!")))
        }
//        
//        Button("Attestation") {
//            service.generateKey { (keyIdentifier, error) in
//                guard error == nil else {
//                    debugPrint(error ?? "")
//                    return
//                }
//                let challenge = "4uMA76Bl+L+ecspHfr8gox0BKyJws52530FzLBMzejbN2UF5pAm2rz/JLT9QbQHDgb9GfGG53L0A8SaoEmy6HxaC3Pb8kpYaY8vrC/CTDjXbzeZNsYbX6nBGzkMSK7EZDcXEEHW9q6dVbzbdtLlUm/J5c5U7XOEmibAZoU2IU0o=".data(using: .utf8)!
//                let hash = Data(SHA256.hash(data: challenge))
//                service.attestKey(keyIdentifier!, clientDataHash: hash) { attestation, error in
//                    guard error == nil else {
//                        debugPrint(error ?? "")
//                        return
//                    }
//
//                    debugPrint(attestation!.base64EncodedString())
//                }
//            }
//        }
//        .padding(15)
//        .border(Color.blue, width: 1)

    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
