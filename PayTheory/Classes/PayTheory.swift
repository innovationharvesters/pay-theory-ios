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

public func ?? <T>(lhs: Binding<T?>, rhs: T) -> Binding<T> {
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
    
    //idempotencyClosre and challengeClosure used for the tokenize function
    
    //Closure to run once the idempotency has been retrieved from the PT Server
    func idempotencyClosure(completion: @escaping (Result<[String: Any], FailureResponse>) -> Void) ->
                            (_ response: Result<IdempotencyResponse, Error>) -> Void {
            return { [self]response in
                switch response {
                case .success(let response):
                    if envCard.isValid {
                        idempotencyResponse = response
                        tags["pt-number"] = response.idempotency
                        tags["pay-theory-environment"] = environment
                        tokenResponse = ["receipt_number": response.idempotency,
                                         "first_six": envCard.firstSix,
                                         "brand": envCard.brand,
                                         "amount": response.payment.amount,
                                         "convenience_fee": response.payment.service_fee ]
                        
                        completion(.success(tokenResponse!))
                    } else if envAch.isValid {
                        idempotencyResponse = response
                        tags["pt-number"] = response.idempotency
                        tags["pay-theory-environment"] = environment
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
    }
    
    //Closure to run once the challenge has been retrieved from the PT Server
    func challengeClosure(amount: Int,
                          completion: @escaping (Result<[String: Any], FailureResponse>) -> Void) ->
                        (Result<Challenge, Error>) -> Void {
       { [self]response in
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
                                             fee_mode: self.fee_mode)
                    postIdempotency(body: attest,
                                    apiKey: self.apiKey,
                                    endpoint: self.environment,
                                    completion: idempotencyClosure(completion: completion))
                }
            }
        
        case .failure(let error):
            completion(.failure(error as? FailureResponse ?? FailureResponse(type: "Unknown Error")))
            buttonClicked = false
        }
       }
    }
    
    func tokenize(card: PaymentCard? = nil,
                  bank: BankAccount? = nil,
                  amount: Int,
                  buyerOptions: Buyer,
                  completion: @escaping (Result<[String: Any], FailureResponse>) -> Void ) {
        
        getChallenge(apiKey: apiKey,
                     endpoint: environment,
                     completion: challengeClosure(amount: amount, completion: completion))
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
    
    //Completion used for the capture function
    func captureCompletion(type: String,
                           completion: @escaping (Result<[String: Any], FailureResponse>) -> Void)
                            -> (Result<[String: AnyObject], Error>) -> Void {
        { [self]response in
            switch response {
            case .success(let responseAuth):
                var complete: [String: Any] = ["receipt_number": idempotencyResponse!.idempotency,
                                              "last_four": envAch.lastFour,
                                              "created_at": responseAuth["created_at"] as? String ?? "",
                                              "amount": responseAuth["amount"] as? Int ?? 0,
                                              "service_fee": responseAuth["service_fee"] as? Int ?? 0,
                                              "state": responseAuth["state"] as? String ?? "",
                                              "tags": responseAuth["tags"] as? [String: Any] ?? [:]]
                    
                if type == "card" {
                    complete["brand"] = envCard.brand
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
    }
    
    //Public function that will complete the authorization and send a
    //Completion Response with all the transaction details to the completion handler provided

    public func capture(completion: @escaping (Result<[String: Any], FailureResponse>) -> Void) {
        var type: String = ""

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
                            completion: captureCompletion(type: type, completion: completion))
        } else {
            let error = FailureResponse(type: "There is no auth to capture")
            completion(.failure(error))
        }
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
