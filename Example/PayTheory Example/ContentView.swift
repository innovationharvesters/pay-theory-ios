//
//  ContentView.swift
//  PayTheory Example
//
//  Created by Austin Zani on 11/4/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import SwiftUI
import PayTheory

struct TextField: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(15)
            .font(Font.system(size: 15, weight: .medium, design: .serif))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 2))
    }
}

extension View {
    func textFieldStyle() -> some View {
        self.modifier(TextField())
    }
}


struct ContentView: View {
    
    @State private var confirmationMessage = ""
    @State private var showingConfirmation = false
    @State private var showingMessage = false
    
    let buyer = Buyer(first_name: "Some", last_name: "Body", phone: "513-658-8121")
    
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
    
    func cancelCompletion(result: Result<Bool, FailureResponse>){
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
    
    var body: some View {
            VStack{
                PTCardName().textFieldStyle()
                PTCardNumber().textFieldStyle()
                PTExpYear().textFieldStyle()
                PTExpMonth().textFieldStyle()
                PTCvv().textFieldStyle()
                PTTokenizeButton(amount: 5000, PT: pt, buyer: buyer, tags: ["test": 1234, "Test Again": "This is a test"], completion: completion).textFieldStyle()
            }
        .alert(isPresented: $showingConfirmation) {
            Alert(title: Text("Confirm:"), message: Text(confirmationMessage), primaryButton: .default(Text("Confirm"), action: {
                pt.capture(completion: confirmCompletion)
            }), secondaryButton: .cancel(Text("Cancel"), action: {
                pt.cancel(completion: cancelCompletion)
            }))
        }
        HStack{
            
        }
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
