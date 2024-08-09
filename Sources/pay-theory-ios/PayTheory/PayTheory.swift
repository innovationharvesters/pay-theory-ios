//
//  PayTheory.swift
//  PayTheory
//
//  Created by Austin Zani on 11/3/20.
//
// Base of the Pay Theory class that contains all attributes, the initializer, and the functions needed to make it conform to the WebSocketProtocol

import SwiftUI
import Foundation
import Combine

import DeviceCheck
import CryptoKit

public class PayTheory: ObservableObject, WebSocketProtocol {
    // State variables to tell when things are valid or empty
    var envCard: Card
    var envPayor: Payor
    var envAch: ACH
    var envCash: Cash
    var cancellables = Set<AnyCancellable>()
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
    @Published public var cardServiceFee: Int?
    @Published public var bankServiceFee: Int?
    
    @Published public var isReady: Bool = false

    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    var isAwaitingResponse: Bool = false
    let service = DCAppAttestService.shared
    var amount: Int?
    var apiKey: String
    var environment: String
    var stage: String
    var monitor: NetworkMonitor
    var sessionId = generateUUID()
    @ObservedObject var transaction: Transaction
    var transactionCancellable: AnyCancellable? = nil
    public var completion: ((Result<SuccessfulResponse, PTError>) -> Void)?
    
    var appleEnvironment: String
    var devMode = false
    var isInitialized = false
    var isComplete = false
    var passedPayor: Payor?
    var ptToken: String?
    var session: WebSocketSession
    // Attestation string being set should trigger the connection of our socket or sending of the hostTokenMessage if it is already connected
    var attestationString: String?
    
    // Setting of the cardBin should trigger the potential calculation of fees if an amount is set
    var cardBin: String? {
        didSet {
            // If there is a cardBin then try and send the amount message if the amount is sent
            if let cardBin = cardBin {
                if let _ = amount {
                    sendCalcFeeMessage(card_bin: cardBin)
                }
            } else { // If cardBin is set to nil then set the cardServiceFee to nil
                self.cardServiceFee = nil
            }
        }
    }
    
    /// Initializes a new instance of the PayTheory class.
    ///
    /// This initializer sets up the PayTheory instance with the provided amount, API key,
    /// development mode flag, and a completion handler for processing responses.
    ///
    /// - Parameters:
    ///   - amount: An optional integer representing the transaction amount in cents. This will be used to calculate the fees if you are using the Service Fee fee mode.
    ///   - apiKey: A string containing the API key for authentication with the Pay Theory service.
    ///   - devMode: A boolean flag indicating whether to run in development mode. Defaults to `false`.
    ///   - completion: An optional closure that handles the result of PayTheory operations.
    ///                 It takes a `Result<SuccessfulResponse, PTError>` parameter.
    ///
    /// - Throws: A fatal error if the API key is not valid.
    ///
    /// - Note: This initializer sets up various state variables, configures the network monitor,
    ///         sets up observers for app lifecycle events, and stores the completion handler for later use.
    public init(amount: Int?, apiKey: String, devMode: Bool = false, completion: ((Result<SuccessfulResponse, PTError>) -> Void)?) {
        // Parse the API key to extract environment and stage information
        let apiParts = apiKey.split {$0 == "-"}.map { String($0) }
        // Validate the the API key is the correct format
        if apiParts.count != 3 {
            fatalError("This is not a valid API Key. API Key should be formatted '{partner}-{paytheorystage}-{UUID}'")
        }
        
        self.amount = amount
        self.apiKey = apiKey
        environment = apiParts[0]
        stage = apiParts[1]
        appleEnvironment = devMode ? "appattestdevelop" : "appattest"
        self.devMode = devMode
        
        // Store the completion handler
        self.completion = completion
        
        // Initialize payment method objects
        envAch = ACH()
        envCard = Card()
        envPayor = Payor()
        envCash = Cash()
        
        // Initialize the Observable Objects for different payment method values
        cashName = CashName(cash: envCash)
        cashContact = CashContact(cash: envCash)
        accountName = ACHAccountName(bank: envAch)
        accountNumber = ACHAccountNumber(bank: envAch)
        routingNumber = ACHRoutingNumber(bank: envAch)
        cvv = CardCvv(card: envCard)
        exp = CardExp(card: envCard)
        cardNumber = CardNumber(card: envCard)
        postalCode = CardPostalCode(card: envCard)
        
        // Set up network monitoring
        monitor = NetworkMonitor()
        
        // Initialize transaction object
        let newTransaction = Transaction(apiKey: apiKey)
        transaction = newTransaction
        
        // Initialize validation object
        valid = ValidFields(cash: envCash, card: envCard, ach: envAch, transaction: newTransaction)
        
        // Initialize the WebSocketSession we will use for socket communications
        let provider = WebSocketProvider()
        session = WebSocketSession()
        session.prepare(_provider: provider, _handler: self)
        let notificationCenter = NotificationCenter.default
        
        // Initialize the observer for managing the socket connection
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appCameToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        // Set up Combine publishers to propagate changes
        envCard.objectWillChange.sink { [weak self] (_) in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        envCash.objectWillChange.sink { [weak self] (_) in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        envAch.objectWillChange.sink { [weak self] (_) in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        envPayor.objectWillChange.sink { [weak self] (_) in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        transaction.objectWillChange.sink { [weak self] (_) in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        
        // Set listener on the card number to set the cardBin value for calculating the fee
        envCard.$number.sink { [weak self] newNumber in
            self?.cardNumberChanged(newNumber)
        }.store(in: &cancellables)
        
        Task {
            do {
                try await connectSocket()
            } catch {
                useCompletionHandler(.failure(PTError(code: .socketError, error: "Unable to connect to the socket.")))
            }
        }
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
    
    // Functions used to conform to the WebSocketProtocol
    func receiveMessage(message: String) {
        debugPrint("handle receiveMessage")
        onMessage(response: message)
    }
    
    func handleError(error: Error) {
        useCompletionHandler(.failure(PTError(code: .socketError, error: "An unknown socket error occured")))
        debugPrint(error)
    }
    
    func handleDisconnect() {
        self.transaction.sessionKey = nil
        self.transaction.publicKey = nil
        self.isReady = false
        debugPrint("socket disconnected")
    }
}
