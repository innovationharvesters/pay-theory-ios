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

func makePt(payTheory: PayTheory) -> PayTheory {
    payTheory.environment = "finix"
    return payTheory
}

func formatMoney(val: Double) -> String {
    return "$\(val / 100)"
}

struct ContentView: View {
    @State private var confirmationMessage = ""
    @State private var showingConfirmation = false
    @State private var showingMessage = false
    let ptObject = PayTheory(apiKey: "pt-sandbox-finix-3f77175085e9834c6f514a77eddfdb87",
                                         tags: ["Test Tag": "Test Value"],
                                         fee_mode: .SERVICE_FEE,
                                         dev: "finix")

    let buyer = Buyer(firstName: "Some", lastName: "Body", phone: "555-555-5555")
    @State private var type = 0
    @State private var amount = 0
    private var types: [String] = ["Card", "ACH"]
    private var amounts: [Double] = [37, 39]
    
    func completion(result: Result<[String: Any], FailureResponse>) {
        switch result {
        case .success(let token):
            if let brand = token["brand"] {
                self.confirmationMessage = """
                                            Are you sure you want to charge
                                            $\(String(format: "%.2f", (Double(token["amount"] as? Int ?? 0) / 100)))
                                            to the \(brand) card starting in \(token["first_six"] ?? "")?
                                            """
            } else {
                self.confirmationMessage = """
                                            Are you sure you want to charge
                                            $\(String(format: "%.2f", (Double(token["amount"] as? Int ?? 0) / 100)))
                                            to the Bank Account ending in \(token["last_four"] ?? "")?
                                            """
            }
                self.showingConfirmation = true
        case .failure(let error):
                self.confirmationMessage = "Your tokenization failed! \(error.type)"
                self.showingConfirmation = true
            }
    }
    
    func confirmCompletion(result: Result<[String: Any], FailureResponse>) {
        switch result {
        case .success(let token):
            if let brand = token["brand"] {
                self.confirmationMessage = """
                                            You charged $\(String(format:"%.2f",
                                            (Double(token["amount"] as? Int ?? 0) / 100)))
                                            to \(brand) card ending in \(token["last_four"] ?? "")
                                            """
            } else {
                self.confirmationMessage = """
                                            You charged $\(String(format:"%.2f",
                                            (Double(token["amount"] as? Int ?? 0) / 100)))
                                            to Bank Account ending in \(token["last_four"] ?? "")
                                            """
            }
            self.showingMessage = true
        case .failure(let response):
            self.confirmationMessage = "The transaction failed to confirm \(response.type)"
            self.showingMessage = true
        }
    }
    
    var body: some View {
            VStack {
                Picker("Amount", selection: $amount) {
                    ForEach(0 ..< amounts.count) {
                        Text(formatMoney(val: self.amounts[$0]))
                    }
                }.pickerStyle(SegmentedPickerStyle())
                
                Picker("Account Type", selection: $type) {
                    ForEach(0 ..< types.count) {
                        Text(self.types[$0])
                    }
                }.pickerStyle(SegmentedPickerStyle())
                
                if type == 0 {
                    PTForm {
                    PTCardNumber().textFieldStyle()
                    PTExp().textFieldStyle()
                    PTCvv().textFieldStyle()
                    PTButton(amount: 33, completion: completion).textFieldStyle()
                    }.environmentObject(ptObject)
                } else if type == 1 {
                    PTForm {
                    PTAchAccountName().textFieldStyle()
                    PTAchAccountNumber().textFieldStyle()
                    PTAchRoutingNumber().textFieldStyle()
                    PTAchAccountType()
                    PTButton(amount: 33, completion: completion).textFieldStyle()
                }.environmentObject(ptObject)
                }
            }
        .alert(isPresented: $showingConfirmation) {
            Alert(title: Text("Confirm:"),
                  message: Text(confirmationMessage),
                  primaryButton: .default(Text("Confirm"),
                                          action: {
                ptObject.capture(completion: confirmCompletion)
            }), secondaryButton: .cancel(Text("Cancel"), action: {
                ptObject.cancel()
            }))
        }
        HStack {
            
        }
        .alert(isPresented: $showingMessage) {
            Alert(title: Text("Success!"),
                  message: Text(confirmationMessage),
                  dismissButton: .default(Text("Ok!")))
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
