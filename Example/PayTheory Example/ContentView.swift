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
    var valid: Bool
    func body(content: Content) -> some View {
        content
            .font(Font.custom("Trebuchet MS Bold", size: 15))
            .foregroundColor(Color(hex: "8E868F"))
            .padding(12)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: valid ? "#8E868F" : "#FF0000"), lineWidth: 1))
    }
}

struct CombinedTextField: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Font.custom("Trebuchet MS Bold", size: 15))
            .foregroundColor(Color(hex: "8E868F"))
    }
}

struct ButtonField: ViewModifier {
    var disabled: Bool
    
    func body(content: Content) -> some View {
        if disabled {
            content
                .frame(maxWidth: .infinity)
                .padding(12)
                .font(Font.custom("Trebuchet MS", size: 15))
                .background(Color.gray)
                .foregroundColor(Color.secondary)
                .cornerRadius(10)
        } else {
            content
                .frame(maxWidth: .infinity)
                .padding(12)
                .font(Font.custom("Trebuchet MS", size: 15))
                .background(LinearGradient(gradient: Gradient(colors: [Color(hex: "#7C2CDD"), Color(hex: "#DB367D")]), startPoint: .leading, endPoint: .trailing ))
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension View {
    func textFieldStyle(valid: Bool = true) -> some View {
        self.modifier(TextField(valid: valid))
    }
    
    func combinedStyle() -> some View {
        self.modifier(CombinedTextField())
    }
    
    func buttonStyle(disabled: Bool) -> some View {
        self.modifier(ButtonField(disabled: disabled))
    }
}

func makePt(payTheory: PayTheory) -> PayTheory {
    return payTheory
}

func formatMoney(val: Double) -> String {
    return "$\(val / 100)"
}

struct ContentView: View {
    @State private var confirmationMessage = ""
    @State private var showingConfirmation = false
    @State private var showingMessage = false
    @ObservedObject var ptObject = PayTheory(apiKey: ProcessInfo.processInfo.environment["api_key"] ?? "",
                                             fee_mode: .SERVICE_FEE)


    let buyer = Buyer(firstName: "Swift", lastName: "Demo", phone: "555-555-5555")
    @State private var type = 0
    @State private var amount = 0
    private var types: [String] = ["Card", "ACH", "Cash"]
    private var amounts: [Double] = [37, 39]
    
    func completion(result: Result<[String: Any], FailureResponse>) {
        switch result {
        case .success(let token):
            if token["brand"] as? String ?? "" != "ACH" {
                self.confirmationMessage = """
                                            Are you sure you want to charge
                                            $\(String(format: "%.2f", (Double(token["amount"] as? Int ?? 0) / 100)))
                                            to the \(token["brand"] as? String ?? "") card starting in
                                            \(token["first_six"] ?? "")?
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
            } else if let barcode = token["barcode"] {
                print(token)
                self.confirmationMessage = barcode as? String ?? "Oops"
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
        VStack(spacing: 10) {
                Spacer().frame(height: 50)
                Text("$54.20").bold()
                    .font(Font.custom("Trebuchet MS Bold", size: 45))
                Text("SCHOOL FEES")
                    .font(Font.custom("Trebuchet MS", size: 20))
                Spacer().frame(height: 30)
                Text("PAYMENT METHOD")
                    .font(Font.custom("Arial Black", size: 20))
                Picker("Payment Method", selection: $type) {
                    ForEach(0 ..< types.count) {
                        Text(self.types[$0])
                    }
                }.pickerStyle(SegmentedPickerStyle())
                
                if type == 0 {
                    PTForm {
                        PTCardName().textFieldStyle()
                        
                        PTCombinedCard().textFieldStyle(valid: (ptObject.cardNumber.isValid || ptObject.cardNumber.isEmpty) &&
                                                            (ptObject.exp.isValid || ptObject.exp.isEmpty) &&
                                                            (ptObject.cvv.isValid || ptObject.cvv.isEmpty))

                    Spacer().frame(height: 25)
                        PTButton(amount: 1250, text: "PAY $54.20", buyerOptions: buyer, completion: completion).buttonStyle(disabled: ptObject.buttonDisabled)
                    }.environmentObject(ptObject)
                } else if type == 1 {
                    PTForm {
                        PTAchAccountName().textFieldStyle(valid: ptObject.achAccountName.isValid || ptObject.achAccountName.isEmpty)
                        PTAchAccountNumber().textFieldStyle(valid: ptObject.achAccountNumber.isValid || ptObject.achAccountNumber.isEmpty)
                        PTAchRoutingNumber().textFieldStyle(valid: ptObject.achRoutingNumber.isValid || ptObject.achRoutingNumber.isEmpty)
                        PTAchAccountType()
                        Spacer().frame(height: 25)
                        PTButton(amount: 1000, text: "PAY $54.20", completion: completion).buttonStyle(disabled: ptObject.buttonDisabled)
                        .frame(minWidth: 100, maxWidth: .infinity, minHeight: 44)
                    }.environmentObject(ptObject)
                } else if type == 2 {
                    PTForm {
                    PTCashName().textFieldStyle(valid: ptObject.cashName.isValid || ptObject.cashName.isEmpty)
                    PTCashContact().textFieldStyle(valid: ptObject.cashContact.isValid || ptObject.cashContact.isEmpty)
                    Spacer().frame(height: 25)
                    PTButton(amount: 1000, text: "PAY $54.20", completion: confirmCompletion).buttonStyle(disabled: ptObject.buttonDisabled)
                    .frame(minWidth: 100, maxWidth: .infinity, minHeight: 44)
                    }.environmentObject(ptObject)
                }
            }
            .padding()
            .frame(
                  minWidth: 0,
                  maxWidth: .infinity,
                  minHeight: 0,
                  maxHeight: .infinity,
                  alignment: .topLeading
                )
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
            Spacer().frame(height: 50)
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
