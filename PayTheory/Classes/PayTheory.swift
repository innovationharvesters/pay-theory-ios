//
//  PayTheory.swift
//  PayTheory
//
//  Created by Austin Zani on 11/3/20.
//
import SwiftUI
import Foundation

import DeviceCheck
import CryptoKit

public func ??<T>(lhs: Binding<Optional<T>>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}
public enum Environment {
    case DEMO, PROD
    
    var value: String {
        switch self {
        case .DEMO:
            return "demo"
        case .PROD:
            return "prod"
    }
    }
}

public class PayTheory: ObservableObject {
    
    let service = DCAppAttestService.shared
    
    var apiKey: String
    public var environment: String
    var fee_mode: FEE_MODE
    var tags: [String: Any]
    var buttonClicked = false
    
    private var encodedChallenge: String = ""
    private var tokenResponse: [String: Any]?
    private var idempotencyResponse: IdempotencyResponse?
    private var passedBuyer: Buyer?
    
    public init(apiKey: String,
                tags: [String: Any] = [:],
                environment: Environment = .DEMO,
                fee_mode: FEE_MODE = .SURCHARGE) {
        
        self.apiKey = apiKey
        self.environment = environment.value
        self.fee_mode = fee_mode
        self.tags = tags
        self.envAch = BankAccount()
        self.envCard = PaymentCard()
        self.envBuyer = Buyer()
    }
    
    let envCard: PaymentCard
    let envBuyer: Buyer
    let envAch: BankAccount
    
    func tokenize(card: PaymentCard? = nil,
                  bank: BankAccount? = nil,
                  amount: Int,
                  buyerOptions: Buyer,
                  completion: @escaping (Result<[String: Any], FailureResponse>) -> Void ) {
        
        //Closure to run once the challenge has been retrieved from the PT Server
        func challengeClosure(response: Result<Challenge, Error>) {
            switch response {
            case .success(let challenge):
                service.generateKey { (keyIdentifier, error) in
                    guard error == nil else {
                        debugPrint(error ?? "")
                        return
                    }
                    let encodedChallengeData = challenge.challenge.data(using: .utf8)!
                    self.encodedChallenge = encodedChallengeData.base64EncodedString()
                    let hash = Data(SHA256.hash(data: encodedChallengeData))
                    self.service.attestKey(keyIdentifier!, clientDataHash: hash) { attestation, error in
                        guard error == nil else {
                            debugPrint(error!)
                            return
                        }
                        let attest = Attestation(attestation: attestation!.base64EncodedString(),
                                                 nonce: encodedChallengeData.base64EncodedString(),
                                                 key: keyIdentifier!,
                                                 currency: "USD",
                                                 amount: amount,
                                                 feeMode: self.fee_mode)
                        postIdempotency(body: attest,
                                        apiKey: self.apiKey,
                                        endpoint: self.environment,
                                        completion: idempotencyClosure)
                    }
                }
            
            case .failure(let error):
                completion(.failure(error as? FailureResponse ?? FailureResponse(type: "Unknown Error")))
                buttonClicked = false
            }
        }
        
        //Closure to run once the idempotency has been retrieved from the PT Server
        func idempotencyClosure(response: Result<IdempotencyResponse, Error>) {
            switch response {
            case .success(let response):
                if envCard.isValid {
                    idempotencyResponse = response
                    tokenResponse = ["receipt_number": response.idempotency,
                                     "first_six": envCard.firstSix,
                                     "brand": envCard.brand,
                                     "amount": response.payment.amount,
                                     "convenience_fee": response.payment.service_fee ]
                    
                    completion(.success(tokenResponse!))
                } else if envAch.isValid {
                    idempotencyResponse = response
                    tokenResponse = ["receipt_number": response.idempotency,
                                     "last_four": envAch.lastFour,
                                     "amount": response.payment.amount,
                                     "convenience_fee": response.payment.service_fee ]
                    
                    completion(.success(tokenResponse!))
                }
                
            case .failure(let error):
                completion(.failure(error as? FailureResponse ?? FailureResponse(type: "Unknown Error")))
                buttonClicked = false
            }
        }
        
        getChallenge(apiKey: apiKey, endpoint: environment, completion: challengeClosure)
    }
    
    // Calculated value that can allow someone to check if there is an active token
    public var isTokenized: Bool {
        if idempotencyResponse != nil {
            return true
        } else {
            return false
        }
    }
    
    
    //Public function that will void the authorization and relase any funds that may be held.

    public func cancel() {
        tokenResponse = nil
        idempotencyResponse = nil
        buttonClicked = false
    }
//
//
    //Public function that will complete the authorization and send a
    //Completion Response with all the transaction details to the completion handler provided

    public func capture(completion: @escaping (Result<[String: Any], FailureResponse>) -> Void) {
        var type: String = ""

        func captureCompletion(response: Result<[String: AnyObject], Error>) {
            switch response {
            case .success(let responseAuth):
                let complete: [String: Any]
                    
                if type == "card" {
                    complete = ["receipt_number": idempotencyResponse!.idempotency,
                                "last_four": envCard.lastFour,
                                "brand": envCard.brand,
                                "created_at": responseAuth["created_at"] as? String ?? "",
                                "amount": responseAuth["amount"] as? Int ?? 0,
                                "service_fee": responseAuth["service_fee"] as? Int ?? 0,
                                "state": responseAuth["state"] as? String ?? "",
                                "tags": responseAuth["tags"] as? [String: Any] ?? [:]]
                } else {
                    complete = ["receipt_number": idempotencyResponse!.idempotency,
                                "last_four": envAch.lastFour,
                                "created_at": responseAuth["created_at"] as? String ?? "",
                                "amount": responseAuth["amount"] as? Int ?? 0,
                                "service_fee": responseAuth["service_fee"] as? Int ?? 0,
                                "state": responseAuth["state"] as? String ?? "",
                                "tags": responseAuth["tags"] as? [String: Any] ?? [:]]
                }
                completion(.success(complete))
                tokenResponse = nil
                idempotencyResponse = nil
                envCard.clear()
                envBuyer.clear()
                envAch.clear()
                buttonClicked = false

            case .failure(let error):
                if let confirmed = error as? FailureResponse {
                    if type == "card" {
                        confirmed.brand = envCard.brand
                        confirmed.receiptNumber = idempotencyResponse!.idempotency
                        confirmed.lastFour = envCard.lastFour
                    } else {
                        confirmed.receiptNumber = idempotencyResponse!.idempotency
                        confirmed.lastFour = envAch.lastFour
                    }
                    completion(.failure(confirmed))
                    tokenResponse = nil
                    idempotencyResponse = nil
                    buttonClicked = false
                } else {
                    completion(.failure(FailureResponse(type: error.localizedDescription)))
                    tokenResponse = nil
                    idempotencyResponse = nil
                    buttonClicked = false
                }
            }
        }

        if let idempotency = idempotencyResponse {
            var payment: [String: Any] = [:]
            if envCard.isValid {
                payment = paymentCardToDictionary(card: envCard)
                type = "card"
            } else if envAch.isValid {
                payment = bankAccountToDictionary(account: envAch)
                type = "ach"
            }
            
            let decodedData = Data(base64Encoded: self.encodedChallenge)!
            let challengeString = String(data: decodedData, encoding: .utf8)!
            
            let body: [String: Any] = [
                "idempotencyToken": idempotency.response,
                "credId": idempotency.credId,
                "signature": idempotency.signature,
                "buyerOptions": buyerToDictionary(buyer: envBuyer),
                "challenge": challengeString,
                "payment": payment,
                "tags": self.tags
            ]
                postPayment(body: body,
                            apiKey: apiKey,
                            endpoint: self.environment,
                            completion: captureCompletion)
        } else {
            let error = FailureResponse(type: "There is no auth to capture")
            completion(.failure(error))
        }
    }
}

//These fields are for capturing the card info required to
//create a payment card associated with an identity to run a transaction

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
    public init(){
        
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
    public init(){
        
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
    public init(){
        
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
    public init(){
        
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
    public init(){
        
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
    public init(){
        
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
    public init(){
        
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
    public init(){
        
    }
    
    public var body: some View {
        TextField("Country", text: $card.address.country ?? "")
    }
}

/// Button that allows a payment to be tokenized once it has the necessary data
/// (Card Number, Expiration Date, and CVV)
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTButton: View {
    @EnvironmentObject var card: PaymentCard
    @EnvironmentObject var envBuyer: Buyer
    @EnvironmentObject var payTheory: PayTheory
    @EnvironmentObject var bank: BankAccount
    
    var completion: (Result<[String: Any], FailureResponse>) -> Void
    var amount: Int
    var text: String
    var buyer: Buyer?
    
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
                completion: @escaping (Result<[String: Any], FailureResponse>) -> Void) {
        
        self.completion = completion
        self.amount = amount
        self.text = text
    }
    
    func tokenizeCompletion(result: Result<[String: Any], FailureResponse>) {
        switch result {
        case .success:
            payTheory.capture(completion: completion)
        case .failure(let error):
            completion(.failure(error))
        }
    }
    
    
    public var body: some View {
        Button(text) {
            if payTheory.buttonClicked == false {
                payTheory.buttonClicked = true
                if let identity = buyer {
                    if card.isValid {
                        if payTheory.fee_mode == .SERVICE_FEE {
                            payTheory.tokenize(card: card,
                                               amount: amount,
                                               buyerOptions: identity,
                                               completion: completion)
                        } else {
                            payTheory.tokenize(card: card,
                                               amount: amount,
                                               buyerOptions: identity,
                                               completion: tokenizeCompletion)
                        }
                    } else if bank.isValid {
                        if  payTheory.fee_mode == .SERVICE_FEE {
                            payTheory.tokenize(bank: bank,
                                               amount: amount,
                                               buyerOptions: identity,
                                               completion: completion)
                        } else {
                            payTheory.tokenize(bank: bank,
                                               amount: amount,
                                               buyerOptions: identity,
                                               completion: tokenizeCompletion)
                        }
                    }
                } else {
                    if card.isValid {
                        if  payTheory.fee_mode == .SERVICE_FEE {
                            payTheory.tokenize(card: card,
                                               amount: amount,
                                               buyerOptions: envBuyer,
                                               completion: completion)
                        } else {
                            payTheory.tokenize(card: card,
                                               amount: amount,
                                               buyerOptions: envBuyer,
                                               completion: tokenizeCompletion)
                        }
                    } else if bank.isValid {
                        if  payTheory.fee_mode == .SERVICE_FEE {
                            payTheory.tokenize(bank: bank,
                                               amount: amount,
                                               buyerOptions: envBuyer,
                                               completion: completion)
                        } else {
                            payTheory.tokenize(bank: bank,
                                               amount: amount,
                                               buyerOptions: envBuyer,
                                               completion: tokenizeCompletion)
                        }
                    }
                }
            }
        }
        .disabled(card.isValid == false && bank.isValid == false)
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
    }

}



/// TextField that can be used to capture the First Name for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTBuyerFirstName: View {
    @EnvironmentObject var identity: Buyer
    public init() {
    }
   public var body: some View {
        TextField("First Name", text: $identity.firstName ?? "")
    }
}

/// TextField that can be used to capture the Last Name for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTBuyerLastName: View {
    @EnvironmentObject var identity: Buyer
    public init() {
    }
    public var body: some View {
        TextField("Last Name", text: $identity.lastName ?? "")
    }
}

/// TextField that can be used to capture the Phone for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTBuyerPhone: View {
    @EnvironmentObject var identity: Buyer
    public init() {
    }
    public var body: some View {
        TextField("Phone", text: $identity.phone ?? "")
    }
}

/// TextField that can be used to capture the Email for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTBuyerEmail: View {
    @EnvironmentObject var identity: Buyer
    public init() {
    }
    public var body: some View {
        TextField("Email", text: $identity.email ?? "")
    }
}

/// TextField that can be used to capture the Address Line 1 for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTBuyerLineOne: View {
    @EnvironmentObject var identity: Buyer
    public init() {
    }
    public var body: some View {
        TextField("Address Line 1", text: $identity.personalAddress.line1 ?? "")
    }
}

/// TextField that can be used to capture the Address Line 2 for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTBuyerLineTwo: View {
    @EnvironmentObject var identity: Buyer
    public init() {
    }
    public var body: some View {
        TextField("Address Line 2", text: $identity.personalAddress.line2 ?? "")
    }
}

/// TextField that can be used to capture the City for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTBuyerCity: View {
    @EnvironmentObject var identity: Buyer
    public init() {
    }
    public var body: some View {
        TextField("City", text: $identity.personalAddress.city ?? "")
    }
}

/// TextField that can be used to capture the State for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTBuyerState: View {
    @EnvironmentObject var identity: Buyer
    public init() {
    }
    public var body: some View {
        TextField("State", text: $identity.personalAddress.region ?? "")
    }
}

/// TextField that can be used to capture the Zip for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTBuyerZip: View {
    @EnvironmentObject var identity: Buyer
    public init() {
    }
    public var body: some View {
        TextField("Zip", text: $identity.personalAddress.postalCode ?? "")
    }
}

/// TextField that can be used to capture the Country for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTBuyerCountry: View {
    @EnvironmentObject var identity: Buyer
    public init() {
    }
    public var body: some View {
        TextField("Country", text: $identity.personalAddress.country ?? "")
    }
}

/// TextField that can be used to capture the Country for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTAchAccountName: View {
    @EnvironmentObject var account: BankAccount
    public init(){
        
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
    public init(){
        
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
    public init(){
        
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
    public init(){
        
    }
    
    public var body: some View {
        TextField("Routing Number", text: $account.bankCode)
            .keyboardType(.decimalPad)
    }
}
