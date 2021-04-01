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

//import Sodium

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

public class PayTheory: ObservableObject, WebSocketProtocol {
    func receiveMessage(message: String) {
        print("handle receiveMessage")
        print(message)
    }
    
    func handleConnect() {
        print("handle connected")
        let hostToken: [String: Any] = [
            "ptToken": ptToken!,
            "origin": "native",
            "attestation":attestationString!,
            "timing": Date().millisecondsSince1970
            
        ]
        print("sending host token")
        session!.sendMessage(action: HOST_TOKEN, messageBody: hostToken, requiresResponse: session!.REQUIRE_RESPONSE)
    }
    
    func handleError(error: Error) {
        print("handle error")
        print(error)
    }
    
    func handleDisconnect() {
        print("handle disconnected")
    }
    
    let service = DCAppAttestService.shared
    var apiKey: String
    public var environment: String
    var fee_mode: FEE_MODE
    var tags: [String: Any]
    var buttonClicked = false
    var transaction = Transaction()
    
    private var encodedChallenge: String = ""
    private var tokenResponse: [String: Any]?
    private var idempotencyResponse: IdempotencyResponse?
    private var isConnected = false
    private var passedBuyer: Buyer?
    private var socket: URLSessionWebSocketTask!
    private var ptToken: String?
    private var session: WebSocketSession?
    private var attestationString: String?{
        didSet {
            let provider = WebSocketProvider()
            session = WebSocketSession()
            session!.prepare(_provider: provider, _handler: self)
            session!.open(ptToken:ptToken!)
            let notificationCenter = NotificationCenter.default
            notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
            notificationCenter.addObserver(self, selector: #selector(appCameToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
                
        }
           
    }
    



    @objc func appMovedToBackground() {
        session!.close()
    }
    
    @objc func appCameToForeground() {
        getToken(apiKey: apiKey, endpoint: "finix", completion: ptTokenClosure)
    }
    
    func ptTokenClosure(response: Result<[String: AnyObject], Error>) {
        switch response {
            case .success(let token):
                ptToken = token["pt-token"] as? String ?? ""
                if let challenge = token["challengeOptions"]?["challenge"] as? String {
                service.generateKey { (keyIdentifier, error) in
                    guard error == nil else {
                        debugPrint(error ?? "")
                        return
                    }
                    let encodedChallengeData = challenge.data(using: .utf8)!
                    self.encodedChallenge = encodedChallengeData.base64EncodedString()
                    let hash = Data(SHA256.hash(data: encodedChallengeData))
                    self.service.attestKey(keyIdentifier!, clientDataHash: hash) { attestation, error in
                        guard error == nil else {
                            debugPrint(error!)
                            return
                        }
                        self.attestationString = attestation!.base64EncodedString()
                    }
                }
                }
            case .failure(_):
                print("failed to fetch pt-token")
        }
    }
    
    
    public init(apiKey: String,
                tags: [String: Any] = [:],
                environment: Environment = .DEMO,
                fee_mode: FEE_MODE = .SERVICE_FEE) {
        
        self.apiKey = apiKey
        self.environment = environment.value
        self.fee_mode = fee_mode
        self.tags = tags
        self.envAch = BankAccount()
        self.envCard = PaymentCard()
        self.envBuyer = Buyer()
        self.transaction.feeMode = fee_mode
        self.transaction.apiKey = apiKey
        self.transaction.tags = tags
        
        getToken(apiKey: apiKey, endpoint: environment.value, completion: ptTokenClosure)
    }
    
    public init(apiKey: String,
                tags: [String: Any] = [:],
                fee_mode: FEE_MODE = .SERVICE_FEE,
                dev: String) {
        
        self.apiKey = apiKey
        self.environment = dev
        self.fee_mode = fee_mode
        self.tags = tags
        self.envAch = BankAccount()
        self.envCard = PaymentCard()
        self.envBuyer = Buyer()
        self.transaction.feeMode = fee_mode
        self.transaction.apiKey = apiKey
        self.transaction.tags = tags
        
        getToken(apiKey: apiKey, endpoint: dev, completion: ptTokenClosure)
    }
    
    let envCard: PaymentCard
    let envBuyer: Buyer
    let envAch: BankAccount

    
    func tokenize(card: PaymentCard? = nil,
                  bank: BankAccount? = nil,
                  amount: Int,
                  buyerOptions: Buyer,
                  completion: @escaping (Result<[String: Any], FailureResponse>) -> Void ) {
        if buttonClicked == false {
            self.transaction.buttonCompletion = completion
            self.transaction.amount = amount
            buttonClicked = true
            if let creditCard = card {
                let body = transaction.createInstrumentBody(instrument: paymentCardToDictionary(card: creditCard)) ?? [:]
                sendMessage(socket: socket, action: PT_INSTRUMENT, messageBody: body, transaction: transaction)
            } else if let bankAccount = bank {
                let body = transaction.createInstrumentBody(instrument: bankAccountToDictionary(account: bankAccount)) ?? [:]
                sendMessage(socket: socket, action: PT_INSTRUMENT, messageBody: body, transaction: transaction)
            }
        }
    }
    
    // Calculated value that can allow someone to check if there is an active token
    var isTokenized: Bool {
        if transaction.paymentToken != nil {
            return true
        } else {
            return false
        }
    }
    
    var isReady: Bool {
        if transaction.hostToken != nil {
            return true
        } else {
            return false
        }
    }
    
    func resetTokenClosure(response: Result<[String: AnyObject], Error>) {
        switch response {
            case .success(let token):
                ptToken = token["pt-token"] as? String ?? ""
                let hostToken: [String: Any] = [
                    "ptToken": ptToken ?? "",
                    "origin": "native",
                    "timing": Date().millisecondsSince1970,
                    "attestation": attestationString ?? ""
                ]
                sendMessage(socket: socket, action: HOST_TOKEN, messageBody: hostToken, transaction: transaction)
                
            case .failure(_):
                print("failed to fetch pt-token")
        }
    }
    
    //Public function that will void the authorization and relase any funds that may be held.
    public func cancel() {
        buttonClicked = false
        transaction.resetTransaction()
        getToken(apiKey: apiKey, endpoint: environment, completion: ptTokenClosure)
    }
    
    //Public function that will complete the authorization and send a
    //Completion Response with all the transaction details to the completion handler provided

    public func capture(completion: @escaping (Result<[String: Any], FailureResponse>) -> Void) {
        
        if isTokenized && fee_mode == .SERVICE_FEE {
            transaction.captureCompletion = completion
            sendMessage(socket: socket, action: TRANSFER, messageBody: transaction.createTransferBody()!, transaction: transaction)
        } else {
            let error = FailureResponse(type: "There is no payment authorization to capture")
            print("The capture function should only be used with the .SERVICE_FEE fee mode")
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
    @EnvironmentObject var transaction: Transaction
    
    var completion: (Result<[String: Any], FailureResponse>) -> Void
    var amount: Int
    var text: String
    var buyer: Buyer?
    var onClick: () -> Void
    
    func defaultClick() {
        print("PTButton has been clicked")
    }
    
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
                onClick: @escaping () -> Void = {return},
                completion: @escaping (Result<[String: Any], FailureResponse>) -> Void) {
        
        self.completion = completion
        self.amount = amount
        self.text = text
        self.onClick = onClick
    }
    
    public var body: some View {
        Button(text) {
                onClick()
                if let identity = buyer {
                    if card.isValid {
                            payTheory.tokenize(card: card,
                                               amount: amount,
                                               buyerOptions: identity,
                                               completion: completion)
                    } else if bank.isValid {
                            payTheory.tokenize(bank: bank,
                                               amount: amount,
                                               buyerOptions: identity,
                                               completion: completion)
                    }
                } else {
                    if card.isValid {
                            payTheory.tokenize(card: card,
                                               amount: amount,
                                               buyerOptions: envBuyer,
                                               completion: completion)
                    } else if bank.isValid {
                            payTheory.tokenize(bank: bank,
                                               amount: amount,
                                               buyerOptions: envBuyer,
                                               completion: completion)
                    }
                }
        }
        .disabled((card.isValid == false && bank.isValid == false) || transaction.hostToken == nil)
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
    }
}
