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
        debugPrint("handle receiveMessage")
        onMessage(response: message)
    }
    
    func handleConnect() {
        debugPrint("handle connected")
        var message: [String: Any] = ["action": HOST_TOKEN]
        let hostToken: [String: Any] = [
            "ptToken": ptToken!,
            "origin": "apple",
            "attestation": attestationString ?? "",
            "timing": Date().millisecondsSince1970,
            "appleEnvironment": appleEnvironment
        ]
        message["encoded"] = stringify(jsonDictionary: hostToken).data(using: .utf8)!.base64EncodedString()
        session!.sendMessage(messageBody: stringify(jsonDictionary: message), requiresResponse: session!.REQUIRE_RESPONSE)
    }
    
    func handleError(error: Error) {
        debugPrint("handle error")
        let errorString = "SOCKET_ERROR: An unknown socket error occured"
        completion?(.failure(FailureResponse(type: errorString)))
        debugPrint(error)
    }
    
    func handleDisconnect() {
        let errorString = "SESSION_EXPIRED: Socket session has expired"
        completion?(.failure(FailureResponse(type: errorString)))
        debugPrint("socket disconnected")
    }
    
    var envCard: Card
    var cardCancellable: AnyCancellable? = nil
    var envPayor: Payor
    var payorCancellable: AnyCancellable? = nil
    var envAch: ACH
    var achCancellable: AnyCancellable? = nil
    var envCash: Cash
    var cashCancellable: AnyCancellable? = nil
    @Published public var cashName: CashName
    @Published public var cashContact: CashContact
    @Published public var cardNumber: CardNumber
    @Published public var cvv: CardCvv
    @Published public var exp: CardExp
    @Published public var postalCode: CardPostalCode
    @Published public var accountNumber: ACHAccountNumber
    @Published public var accountName: ACHAccountName
    @Published public var routingNumber: ACHRoutingNumber
    @Published public var valid: ValidFields
    
    let service = DCAppAttestService.shared
    var apiKey: String
    var environment: String
    var stage: String
    var monitor: NetworkMonitor
    var initialized = false
    @ObservedObject var transaction: Transaction
    var transactionCancellable: AnyCancellable? = nil
    public var completion: ((Result<[String: Any], FailureResponse>) -> Void)?
    
    private var isConnected = false
    private var appleEnvironment: String
    private var passedPayor: Payor?
    private var ptToken: String?
    private var session: WebSocketSession?
    private var devMode = false
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
                    let publicKey = dictionary["public_key"] as? String ?? ""
                    body = transaction.decryptBody(body: body, publicKey: publicKey)
                }
                if type == ERROR_TYPE {
                    let errorString = "SOCKET_ERROR: \(body)"
                    completion?(.failure(FailureResponse(type: errorString)))
                    if transaction.hostToken != nil {
                        resetTransaction()
                    }
                } else if var parsedbody = convertStringToDictionary(text: body)  {
                    if type == TRANSFER_CONFIRMATION_TYPE {
                        transaction.idempotencyToken = parsedbody
                        let body = transaction.createTokenizationResponse()!
                        let response = [
                            "type": PT_CONFIRMATION,
                            "body": parsedbody
                        ] as [String : Any]
                        completion?(.success(response))
                    } else if type == TRANSFER_COMPLETE_TYPE {
                        transaction.transferToken = parsedbody
                        if parsedbody["state"] as? String ?? "" == "FAILURE" {
                            let body = transaction.createFailureResponse()
                            completion?(.failure(body))
                            resetTransaction()
                        } else {
                            let body = transaction.createCompletionResponse()!
                            let response = [
                                "type": PT_COMPLETE,
                                "body": parsedbody
                            ] as [String : Any]
                            completion?(.success(response))
                            transaction.resetTransaction()
                        }
                    } else if type == BARCODE_COMPLETE_TYPE {
                        parsedbody["mapUrl"] = "https://pay.vanilladirect.com/pages/locations" as AnyObject
                        let response = [
                            "type": PT_BARCODE,
                            "body": parsedbody
                        ] as [String : Any]
                        completion?(.success(response))
                    } else if type == TOKENIZE_COMPLETE_TYPE {
                        let response = [
                            "type": PT_TOKENIZE,
                            "body": parsedbody
                        ] as [String : Any]
                        completion?(.success(response))
                    }
                }
            }

            if let errors = dictionary["error"] as? [Any] {
                var result = ""
                for error in errors {
                    if let errorString = error as? String {
                        result += errorString
                    }
                }
                if result != "" {
                    let errorString = "SOCKET_ERROR: \(result)"
                    completion?(.failure(FailureResponse(type: errorString)))
                } else {
                    completion?(.failure(FailureResponse(type: "SOCKET_ERROR: An unknown socket error occured")))
                }
            }
        } else {
            debugPrint("Could not convert the response to a Dictionary")
            completion?(.failure(FailureResponse(type: "SOCKET_ERROR: An unknown socket error occured")))
            if transaction.hostToken != nil {
                resetTransaction()
            }
        }
        
        if completion == nil {
            debugPrint("There is no completion handler to handle the response")
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
                if devMode {
                    // Skip attestation if it is in devMode for testing in the simulator
                    self.attestationString = ""
                } else {
                    if let challenge = token["challengeOptions"]?["challenge"] as? String {
                        service.generateKey { (keyIdentifier, error) in
                            guard error == nil else {
                                debugPrint(error ?? "")
                                let errorString = "INVALID_APP: App Attestation Failed"
                                self.completion?(.failure(FailureResponse(type: errorString)))
                                return
                            }
                            let encodedChallengeData = challenge.data(using: .utf8)!
                            let hash = Data(SHA256.hash(data: encodedChallengeData))
                            self.service.attestKey(keyIdentifier!, clientDataHash: hash) { attestation, error in
                                guard error == nil else {
                                    debugPrint(error!)
                                    let errorString = "INVALID_APP: App Attestation Failed"
                                    self.completion?(.failure(FailureResponse(type: errorString)))
                                    return
                                }
                                self.attestationString = attestation!.base64EncodedString()
                            }
                        }
                    }
                }
            case .failure(_):
                let errorString = "NO_TOKEN: No pt-token found"
                completion?(.failure(FailureResponse(type: errorString)))
                debugPrint("failed to fetch pt-token")
        }
    }
    
    public init(apiKey: String, devMode: Bool = false) {
        
        self.apiKey = apiKey
        let apiParts = apiKey.split{$0 == "-"}.map { String($0) }
        
        if apiParts.count != 3 {
            fatalError("API Key should be formatted '{partner}-{paytheorystage}-{number}'")
        }

        environment = apiParts[0]
        stage = apiParts[1]
        appleEnvironment = devMode ? "appattestdevelop" : "appattest"
        self.devMode = devMode
        envAch = ACH()
        envCard = Card()
        envPayor = Payor()
        envCash = Cash()
        cashName = CashName(cash: envCash)
        cashContact = CashContact(cash: envCash)
        accountName = ACHAccountName(bank: envAch)
        accountNumber = ACHAccountNumber(bank: envAch)
        routingNumber = ACHRoutingNumber(bank: envAch)
        cvv = CardCvv(card: envCard)
        exp = CardExp(card: envCard)
        cardNumber = CardNumber(card: envCard)
        postalCode = CardPostalCode(card: envCard)
        monitor = NetworkMonitor()
        let newTransaction = Transaction()
        transaction = newTransaction
        valid = ValidFields(cash: envCash, card: envCard, ach: envAch, transaction: newTransaction)
        transaction.apiKey = apiKey
        // These sinks are to make sure the PayTheory object updates whenever a value is updated from one of our text fields
        cardCancellable = envCard.objectWillChange.sink { [weak self] (_) in
            self?.objectWillChange.send()
        }
        cashCancellable = envCash.objectWillChange.sink { [weak self] (_) in
            self?.objectWillChange.send()
        }
        achCancellable = envAch.objectWillChange.sink { [weak self] (_) in
            self?.objectWillChange.send()
        }
        payorCancellable = envPayor.objectWillChange.sink { [weak self] (_) in
            self?.objectWillChange.send()
        }
        transactionCancellable = transaction.objectWillChange.sink { [weak self] (_) in
            self?.objectWillChange.send()
        }
        getToken(apiKey: apiKey, environment: environment, stage: stage, completion: ptTokenClosure)
    }
    
    public func transact(amount: Int,
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
                         metadata: [String: Any]? = nil) {
        if initialized == false && transaction.hostToken != nil {
            self.transaction.amount = amount
            self.transaction.payor = payor ?? envPayor
            self.transaction.feeMode = feeMode
            self.transaction.confirmation = confirmation
            self.transaction.metadata = metadata ?? [:]
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
                let body = transaction.createTransferPartOneBody(instrument: paymentCardToDictionary(card: envCard)) ?? ""
                session?.sendMessage(messageBody: body, requiresResponse: session!.REQUIRE_RESPONSE)
            } else if (envAch.isVisible && envAch.isValid) && !envCash.isVisible && !envCard.isVisible {
                let body = transaction.createTransferPartOneBody(instrument: bankAccountToDictionary(account: envAch)) ?? ""
                session?.sendMessage(messageBody: body, requiresResponse: session!.REQUIRE_RESPONSE)
            } else if (envCash.isVisible && envCash.isValid) && !envCard.isVisible && !envAch.isVisible {
                let body = transaction.createCashBody(payment: cashToDictionary(cash: envCash)) ?? ""
                session?.sendMessage(messageBody: body, requiresResponse: session!.REQUIRE_RESPONSE)
            } else {
                initialized = false
                completion?(.failure(FailureResponse(type: "NO_FIELDS: No Visible and Valid PayTheory Fields to Transact")))
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
            let body = transaction.createCancelBody() ?? ""
            session?.sendMessage(messageBody: body, requiresResponse: session!.REQUIRE_RESPONSE)
        }
        resetTransaction()
    }
    
    //Public function that will complete the authorization and send a
    //Completion Response with all the transaction details to the completion handler provided

    public func confirm() {
        if isTokenized {
            let body = transaction.createTransferPartTwoBody() ?? ""
            session?.sendMessage(messageBody: body, requiresResponse: session!.REQUIRE_RESPONSE)
        } else {
            let error = FailureResponse(type: "NO_AUTH: There is no authorization to capture")
            debugPrint("The capture function should only be used with the .SERVICE_FEE fee mode")
            completion?(.failure(error))
        }
    }
    
    func resetPT() {
        self.envAch.clear()
        self.envCard.clear()
        self.envPayor.clear()
        self.envCash.clear()
        getToken(apiKey: apiKey, environment: self.environment, stage: self.stage, completion: ptTokenClosure)
    }
    
    public func tokenizePaymentMethod(payor: Payor? = nil,
                                      payorId: String? = nil,
                                      metadata: [String: Any]? = nil) {
        if initialized == false {
            self.transaction.payor = payor ?? envPayor
            self.transaction.metadata = metadata ?? [:]
            initialized = true
            if (envCard.isVisible && envCard.isValid) && !envCash.isVisible && !envAch.isVisible {
                let body = transaction.createTokenizePaymentMethodBody(instrument: paymentCardToDictionary(card: envCard), payorId: payorId) ?? ""
                session?.sendMessage(messageBody: body, requiresResponse: session!.REQUIRE_RESPONSE)
            } else if (envAch.isVisible && envCard.isValid) && !envCash.isVisible && !envCard.isVisible {
                let body = transaction.createTokenizePaymentMethodBody(instrument: bankAccountToDictionary(account: envAch), payorId: payorId) ?? ""
                session?.sendMessage(messageBody: body, requiresResponse: session!.REQUIRE_RESPONSE)
            } else {
                initialized = false
                completion?(.failure(FailureResponse(type: "NO_FIELDS: No Visible and Valid PayTheory Fields to Tokenize")))
            }
        }
    }
}


