//
//  PayTheory.swift
//  PayTheory
//
//  Created by Austin Zani on 11/3/20.
//
import SwiftUI
import Foundation
import Combine

import DeviceCheck
import CryptoKit

public class PayTheory: ObservableObject, WebSocketProtocol {
    func receiveMessage(message: String) {
        print("handle receiveMessage")
        onMessage(response: message)
    }
    
    func handleConnect() {
        print("handle connected")
        var message: [String: Any] = ["action": HOST_TOKEN]
        let hostToken: [String: Any] = [
            "ptToken": ptToken!,
            "origin": "native",
            "attestation":attestationString!,
            "timing": Date().millisecondsSince1970
        ]
        message["encoded"] = stringify(jsonDictionary: hostToken).data(using: .utf8)!.base64EncodedString()
        session!.sendMessage(messageBody: stringify(jsonDictionary: message), requiresResponse: session!.REQUIRE_RESPONSE)
    }
    
    func handleError(error: Error) {
        print("handle error")
        print(error)
    }
    
    func handleDisconnect() {
        print("handle disconnected")
    }
    
    var envCard: PaymentCard
    var envBuyer: Buyer
    var envAch: BankAccount
    var envCash: Cash
    public var cashName: CashName
    public var cashContact: CashContact
    public var cardNumber: CardNumber
    public var cvv: CardCvv
    public var exp: CardExp
    public var achAccountNumber: ACHAccountNumber
    public var achAccountName: ACHAccountName
    public var achRoutingNumber: ACHRoutingNumber
    
    
    let service = DCAppAttestService.shared
    var apiKey: String
    var environment: String
    var stage: String
    var fee_mode: FEE_MODE
    var tags: [String: Any]
    var buttonClicked = false
    @ObservedObject var transaction = Transaction()
    @Published public var buttonDisabled = true
    private var buttonDisabledCancellable: AnyCancellable!
    
    private var encodedChallenge: String = ""
    private var isConnected = false
    private var passedBuyer: Buyer?
    private var ptToken: String?
    private var session: WebSocketSession?
    private var attestationString: String?{
        didSet {
            let provider = WebSocketProvider()
            session = WebSocketSession()
            session!.prepare(_provider: provider, _handler: self)
            session!.open(ptToken:ptToken!, environment: environment, stage: stage)
            let notificationCenter = NotificationCenter.default
            notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
            notificationCenter.addObserver(self, selector: #selector(appCameToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        }
           
    }
    
    func onMessage(response: String) {
        if let dictionary = convertStringToDictionary(text: response) {

            if let hostToken = dictionary["hostToken"] {
                DispatchQueue.main.async {
                    self.transaction.hostToken = hostToken as? String ?? ""
                }
                transaction.sessionKey = dictionary["sessionKey"] as? String ?? ""
                let key = dictionary["publicKey"] as? String ?? ""
                self.transaction.publicKey = convertStringToByte(string: key)

            } else if let instrument = dictionary["pt-instrument"] {
                transaction.ptInstrument = instrument as? String ?? ""
                session?.sendMessage(messageBody: transaction.createIdempotencyBody()!, requiresResponse: session!.REQUIRE_RESPONSE)

            } else if let _ = dictionary["payment-token"] {
                transaction.paymentToken = dictionary
                if transaction.feeMode == .SURCHARGE {
                session?.sendMessage(messageBody: transaction.createTransferBody()!, requiresResponse: session!.REQUIRE_RESPONSE)
                } else {
                    transaction.completionHandler?(.success(transaction.createTokenizationResponse()!))
                }

            } else if let state = dictionary["state"] {
                transaction.transferToken = dictionary
                if state as? String ?? "" == "FAILURE" {
                    transaction.completionHandler?(.failure(transaction.createFailureResponse()))
                    resetTransaction()
                } else {
                    transaction.completionHandler?(.success(transaction.createCompletionResponse()!))
                    transaction.resetTransaction()
                }
            } else if let _ = dictionary["barcode"] {
                transaction.completionHandler?(.success(dictionary))
            } else if let error = dictionary["error"] {
                print(error)
                transaction.completionHandler?(.failure(FailureResponse(type: error as? String ?? "")))
                resetTransaction()
            }
        } else {
            print("Could not convert the response to a Dictionary")
        }
    }


    @objc func appMovedToBackground() {
        session!.close()
    }
    
    @objc func appCameToForeground() {
        getToken(apiKey: apiKey, environment: environment, stage: stage, completion: ptTokenClosure)
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
                fee_mode: FEE_MODE = .SURCHARGE) {
        
        self.apiKey = apiKey
        let apiParts = apiKey.split{$0 == "-"}.map { String($0) }
        
        if apiParts.count != 3 {
            fatalError("API Key should be formatted '{partner}-{paytheorystage}-{number}'")
        }

        self.environment = apiParts[0]
        self.stage = apiParts[1]
        self.fee_mode = fee_mode
        self.tags = tags
        self.envAch = BankAccount()
        self.envCard = PaymentCard()
        self.envBuyer = Buyer()
        self.envCash = Cash()
        self.cashName = CashName(cash: self.envCash)
        self.cashContact = CashContact(cash: self.envCash)
        self.achAccountName = ACHAccountName(bank: self.envAch)
        self.achAccountNumber = ACHAccountNumber(bank: self.envAch)
        self.achRoutingNumber = ACHRoutingNumber(bank: self.envAch)
        self.cvv = CardCvv(card: self.envCard)
        self.exp = CardExp(card: self.envCard)
        self.cardNumber = CardNumber(card: self.envCard)
        self.transaction.feeMode = fee_mode
        self.transaction.apiKey = apiKey
        self.transaction.tags = tags
        buttonDisabledCancellable = buttonDisabledPublisher.sink { buttonDisabled in
            self.buttonDisabled = buttonDisabled
        }
        
        
        getToken(apiKey: apiKey, environment: self.environment, stage: self.stage, completion: ptTokenClosure)
    }
    
    @available(*, deprecated, message: "environment in init is deprecated")
    public convenience init(apiKey: String,
                tags: [String: Any] = [:],
                environment: Environment,
                fee_mode: FEE_MODE = .SURCHARGE) {
        self.init(apiKey: apiKey,tags: tags,fee_mode: fee_mode)
    }
    
    @available(*, deprecated, message: "dev in init is deprecated")
    public convenience init(apiKey: String,
                tags: [String: Any] = [:],
                fee_mode: FEE_MODE = .SURCHARGE,
                dev:String) {
        self.init(apiKey: apiKey,tags: tags,fee_mode: fee_mode)
    }
    
    var buttonDisabledPublisher: AnyPublisher<Bool,Never> {
        return Publishers.CombineLatest4(envCard.$isValid, envAch.$isValid, transaction.$hostToken, envCash.$isValid)
            .map { validCard, validAch, hostToken, validCash in
                return !((validCard || validAch || validCash) && hostToken != nil)
            }
            .eraseToAnyPublisher()
    }
    
    func tokenize(card: PaymentCard? = nil,
                  bank: BankAccount? = nil,
                  cash: Cash? = nil,
                  amount: Int,
                  buyerOptions: Buyer,
                  completion: @escaping (Result<[String: Any], FailureResponse>) -> Void ) {
        if buttonClicked == false {
            self.transaction.completionHandler = completion
            self.transaction.amount = amount
            self.transaction.buyerOptions = buyerOptions
            buttonClicked = true
            if let creditCard = card {
                let body = transaction.createInstrumentBody(instrument: paymentCardToDictionary(card: creditCard)) ?? ""
                session?.sendMessage(messageBody: body, requiresResponse: session!.REQUIRE_RESPONSE)
            } else if let bankAccount = bank {
                let body = transaction.createInstrumentBody(instrument: bankAccountToDictionary(account: bankAccount)) ?? ""
                session?.sendMessage(messageBody: body, requiresResponse: session!.REQUIRE_RESPONSE)
            } else if let cashObject = cash {
                let body = transaction.createCashBody(payment: cashToDictionary(cash: cashObject)) ?? ""
                session?.sendMessage(messageBody: body, requiresResponse: session!.REQUIRE_RESPONSE)
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
    
    //Used to reset when a transaction fails or an error is returned. Also used by cancel function.
    func resetTransaction() {
        buttonClicked = false
        transaction.resetTransaction()
        getToken(apiKey: apiKey, environment: environment, stage: stage, completion: ptTokenClosure)
    }
    
    //Public function that will void the authorization and relase any funds that may be held.
    public func cancel() {
       resetTransaction()
    }
    
    //Public function that will complete the authorization and send a
    //Completion Response with all the transaction details to the completion handler provided

    public func capture(completion: @escaping (Result<[String: Any], FailureResponse>) -> Void) {
        
        if isTokenized && fee_mode == .SERVICE_FEE {
            transaction.completionHandler = completion
            session?.sendMessage(messageBody: transaction.createTransferBody()!, requiresResponse: session!.REQUIRE_RESPONSE)
        } else {
            let error = FailureResponse(type: "There is no payment authorization to capture")
            print("The capture function should only be used with the .SERVICE_FEE fee mode")
            completion(.failure(error))
        }
    }
    
    func resetPT() {
        self.envAch.clear()
        self.envCard.clear()
        self.envBuyer.clear()
        self.envCash.clear()
        getToken(apiKey: apiKey, environment: self.environment, stage: self.stage, completion: ptTokenClosure)
    }
}


