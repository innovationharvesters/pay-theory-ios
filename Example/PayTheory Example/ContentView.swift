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
    let pt = PayTheory(apiKey: ProcessInfo.processInfo.environment["demo_api_key"]!, tags: ["Test Tag" : "Test Value"], environment: .DEMO)
    
    
    let buyer = Buyer(first_name: "Some", last_name: "Body", phone: "555-555-5555")
    
    @State private var type = 0
    private var types: [String] = ["Card", "ACH"]
    
    func completion(result: Result<[String: Any], FailureResponse>){
        switch result {
        case .success(let token):
            if let brand = token["brand"] {
                self.confirmationMessage = "Are you sure you want to charge $\(String(format:"%.2f", (Double(token["amount"] as! Int) / 100))) to the \(brand) card starting in \(token["first_six"] ?? "")?"
            } else {
                self.confirmationMessage = "Are you sure you want to charge $\(String(format:"%.2f", (Double(token["amount"] as! Int) / 100))) to the Bank Account ending in \(token["last_four"] ?? "")?"
            }
                self.showingConfirmation = true
            case .failure(let error):
                print(error.type, "completion error")
                self.confirmationMessage = "Your tokenization failed! \(error.type)"
                self.showingConfirmation = true
            }
    }
    
    func confirmCompletion(result: Result<[String: Any], FailureResponse>){
        switch result {
        case .success(let token):
            if let brand = token["brand"] {
                self.confirmationMessage = "You charged $\(String(format:"%.2f", (Double(token["amount"] as! Int) / 100))) to \(brand) card ending in \(token["last_four"] ?? "")"
            } else {
                self.confirmationMessage = "You charged $\(String(format:"%.2f", (Double(token["amount"] as! Int) / 100))) to Bank Account ending in \(token["last_four"] ?? "")"
            }
            self.showingMessage = true
            debugPrint(token["tags"] as! [String: Any])
        case .failure(let response):
            print(response.type, "completion error")
            self.confirmationMessage = "The transaction failed to confirm \(response.type)"
            self.showingMessage = true
        }
    }
    
    var body: some View {
            VStack{
                
                Picker("Account Type", selection: $type){
                    ForEach(0 ..< types.count){
                        Text(self.types[$0])
                    }
                }.pickerStyle(SegmentedPickerStyle())
                
                if type == 0 {
                    PTForm{
                    PTCardName().textFieldStyle()
                    PTCardNumber().textFieldStyle()
                    PTExp().textFieldStyle()
                    PTCvv().textFieldStyle()
                    PTCardLineOne().textFieldStyle()
                    PTCardCity().textFieldStyle()
                    PTCardState().textFieldStyle()
                    PTCardZip().textFieldStyle()
                    PTButton(amount: 5000, completion: completion).textFieldStyle()
                    }.environmentObject(pt)
                } else if type == 1 {
                    PTForm {
                    PTAchAccountName().textFieldStyle()
                    PTAchAccountNumber().textFieldStyle()
                    PTAchRoutingNumber().textFieldStyle()
                    PTAchAccountType()
                    PTButton(amount: 5000, completion: completion).textFieldStyle()
                }.environmentObject(pt)
                }
                
//                Text(pt.cardErrors["number"]!["isDirty"] as! Bool ? pt.cardErrors["number"]!["error"] as! String : "" )
            }
        .alert(isPresented: $showingConfirmation) {
            Alert(title: Text("Confirm:"), message: Text(confirmationMessage), primaryButton: .default(Text("Confirm"), action: {
                pt.capture(completion: confirmCompletion)
            }), secondaryButton: .cancel(Text("Cancel"), action: {
                pt.cancel()
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
