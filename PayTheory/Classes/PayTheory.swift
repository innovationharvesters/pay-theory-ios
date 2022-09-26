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
            "origin": "ios",
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
    var envPayor: Payor
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
    var monitor: NetworkMonitor
    var initialized = false
    @ObservedObject var transaction = Transaction()
    
    private var encodedChallenge: String = ""
    private var isConnected = false
    private var passedPayor: Payor?
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
            print(dictionary, "dictionary")
            let type = dictionary["type"] as? String ?? ""
            if type == HOST_TOKEN_TYPE {
                let body = dictionary["body"] as? [String: AnyObject] ?? [:]
                let hostToken = body["hostToken"] as? String ?? ""
                DispatchQueue.main.async {
                    self.transaction.hostToken = hostToken
                }
                transaction.sessionKey = body["sessionKey"] as? String ?? ""
                let key = body["publicKey"] as? String ?? ""
                self.transaction.publicKey = convertStringToByte(string: key)
            }
            
            if var body = dictionary["body"] as? String {
                if ENCRYPTED_MESSAGES.contains(type) {
                    print("we gonna decrypt")
                    let publicKey = dictionary["public_key"] as? String ?? ""
                    body = transaction.decryptBody(body: body, publicKey: publicKey)
                }
                if type == ERROR_TYPE {
                    transaction.completionHandler?(.failure(FailureResponse(type: body)))
                    resetTransaction()
                } else if var parsedbody = convertStringToDictionary(text: body)  {
                    if type == TRANSFER_CONFIRMATION_TYPE {
                        transaction.idempotencyToken = parsedbody
                        transaction.completionHandler?(.success(transaction.createTokenizationResponse()!))
                    } else if type == TRANSFER_COMPLETE_TYPE {
                        transaction.transferToken = parsedbody
                        if parsedbody["state"] as? String ?? "" == "FAILURE" {
                            transaction.completionHandler?(.failure(transaction.createFailureResponse()))
                            resetTransaction()
                        } else {
                            transaction.completionHandler?(.success(transaction.createCompletionResponse()!))
                            transaction.resetTransaction()
                        }
                    } else if type == BARCODE_COMPLETE_TYPE {
                        parsedbody["mapUrl"] = "https://pay.vanilladirect.com/pages/locations" as AnyObject
                        transaction.completionHandler?(.success(parsedbody))
                    }
                }
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
    
    func ptTokenClosure(response: Result<[String: AnyObject], NetworkError>) {
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
    
    public init(apiKey: String) {
        
        self.apiKey = apiKey
        let apiParts = apiKey.split{$0 == "-"}.map { String($0) }
        
        if apiParts.count != 3 {
            fatalError("API Key should be formatted '{partner}-{paytheorystage}-{number}'")
        }

        environment = apiParts[0]
        stage = apiParts[1]
        envAch = BankAccount()
        envCard = PaymentCard()
        envPayor = Payor()
        envCash = Cash()
        cashName = CashName(cash: envCash)
        cashContact = CashContact(cash: envCash)
        achAccountName = ACHAccountName(bank: envAch)
        achAccountNumber = ACHAccountNumber(bank: envAch)
        achRoutingNumber = ACHRoutingNumber(bank: envAch)
        cvv = CardCvv(card: envCard)
        exp = CardExp(card: envCard)
        cardNumber = CardNumber(card: envCard)
        monitor = NetworkMonitor()
        transaction.apiKey = apiKey
        
        getToken(apiKey: apiKey, environment: environment, stage: stage, completion: ptTokenClosure)
    }
    
    public func initialize(amount: Int,
                           payor: Payor? = nil,
                           payorId: String? = nil,
                           feeMode: FEE_MODE = FEE_MODE.INTERCHANGE,
                           fee: Int? = nil,
                           accountCode: String? = nil,
                           reference: String? = nil,
                           paymentParameters: String? = nil,
                           invoiceId: String? = nil,
                           recurringId: String? = nil,
                           sendReceipt: Bool = false,
                           receiptDescription: String? = nil,
                           confirmation: Bool = false,    
                           completion: @escaping (Result<[String: Any], FailureResponse>) -> Void ) {
        if initialized == false {
            self.transaction.completionHandler = completion
            self.transaction.amount = amount
            self.transaction.payor = payor
            self.transaction.feeMode = feeMode
            self.transaction.confirmation = confirmation
            self.transaction.payTheoryData = [
                "account_code": accountCode ?? "",
                "reference": reference ?? "",
                "payment_parameters": paymentParameters ?? "",
                "payor_id": payorId ?? "",
                "send_receipt": sendReceipt,
                "receipt_description": receiptDescription ?? "",
                "invoice_id": invoiceId ?? "",
                "recurring_id": recurringId ?? "",
                "timezone": TimeZone.current.identifier,
                "fee": fee ?? 0
            ]
            initialized = true
            if (envCard.isVisible && envCard.isValid) && !envCash.isVisible && !envAch.isVisible {
                print("card message sent")
                let body = transaction.createTransferPartOneBody(instrument: paymentCardToDictionary(card: envCard)) ?? ""
                session?.sendMessage(messageBody: body, requiresResponse: session!.REQUIRE_RESPONSE)
            } else if (envAch.isVisible && envCard.isValid) && !envCash.isVisible && !envCard.isVisible {
                print("ach message sent")
                let body = transaction.createTransferPartOneBody(instrument: bankAccountToDictionary(account: envAch)) ?? ""
                session?.sendMessage(messageBody: body, requiresResponse: session!.REQUIRE_RESPONSE)
            } else if (envCash.isVisible && envCash.isValid) && !envCard.isVisible && !envAch.isVisible {
                print("cash message sent")
                let body = transaction.createCashBody(payment: cashToDictionary(cash: envCash)) ?? ""
                session?.sendMessage(messageBody: body, requiresResponse: session!.REQUIRE_RESPONSE)
            } else {
                initialized = false
                completion(.failure(FailureResponse(type: "No Visible and Valid PayTheory Fields to Initialize")))
            }
        }
    }
    
    // Calculated value that can allow someone to check if there is an active token
    var isTokenized: Bool {
        if transaction.idempotencyToken != nil {
            return true
        } else {
            return false
        }
    }
    
    //Used to reset when a transaction fails or an error is returned. Also used by cancel function.
    func resetTransaction() {
        initialized = false
        transaction.resetTransaction()
        getToken(apiKey: apiKey, environment: environment, stage: stage, completion: ptTokenClosure)
    }
    
    //Public function that will void the authorization and relase any funds that may be held.
    public func cancel() {
        if isTokenized {
            print("cancel")
            let body = transaction.createCancelBody() ?? ""
            session?.sendMessage(messageBody: body, requiresResponse: session!.REQUIRE_RESPONSE)
        }
        resetTransaction()
    }
    
    //Public function that will complete the authorization and send a
    //Completion Response with all the transaction details to the completion handler provided

    public func capture(completion: @escaping (Result<[String: Any], FailureResponse>) -> Void) {
        
        if isTokenized {
            transaction.completionHandler = completion
            let body = transaction.createTransferPartTwoBody() ?? ""
            session?.sendMessage(messageBody: body, requiresResponse: session!.REQUIRE_RESPONSE)
        } else {
            let error = FailureResponse(type: "There is no payment authorization to capture")
            print("The capture function should only be used with the .SERVICE_FEE fee mode")
            completion(.failure(error))
        }
    }
    
    func resetPT() {
        self.envAch.clear()
        self.envCard.clear()
        self.envPayor.clear()
        self.envCash.clear()
        getToken(apiKey: apiKey, environment: self.environment, stage: self.stage, completion: ptTokenClosure)
    }
}


