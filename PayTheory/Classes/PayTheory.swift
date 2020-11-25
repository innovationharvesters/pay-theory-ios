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

import AWSKMS

public func ??<T>(lhs: Binding<Optional<T>>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}

public class PayTheory {
    
    let service = DCAppAttestService.shared
    
    var apiKey: String
    
    private var identityResponse: IdentityResponse?
    private var cardResponse: PaymentCardResponse?
    private var authResponse: AuthorizationResponse?
    private var tokenResponse: TokenizationResponse?
    private var idempotencyResponse: Idempotency?
    
    private var card = PaymentCard()
    
    
    public init(apiKey: String){
        self.apiKey = apiKey
    }
    
    
    //Function that sends the BuyerOptions, PaymentCard/BankAccount, and Authorization to the server and returns a Result<TokenizationResponse, FailureResponse> to the completion handler.
    private func tokenizeCard(identity: Buyer, paymentCard: PaymentCard, amount: Int, merchant: String, tags: [String: Any], completion: @escaping (Result<TokenizationResponse, FailureResponse>) -> Void) {
        
        func paymentCardCompletion(response: Result<PaymentCardResponse, Error>) {
            switch response {
                case .success(let card):
                     cardResponse = card
                    let authorization: [String: Any] = ["merchant_identity": merchant, "amount": amount, "source": card.id, "currency": "USD", "tags": tags, "idempotency_id":  idempotencyResponse!.idempotency]
//                    let authorization = Authorization(merchant_identity: merchant, amount: "\(amount)", source: card.id, idempotency_id: idempotencyResponse!.idempotency)
                    AuthorizationAPI().create(auth: idempotencyResponse!.token, authorization: authorization, completion: authCompletion)
                case .failure(let error):
                    debugPrint("Your transaction failed! \(error.localizedDescription)")
                }
        }
        
        func authCompletion(response: Result<AuthorizationResponse, Error>) {
            switch response {
                case .success(let auth):
                    authResponse = auth
                    tokenResponse = TokenizationResponse(receipt_number: idempotencyResponse!.idempotency, first_six: cardResponse!.bin, brand: cardResponse!.bin, amount: idempotencyResponse!.payment.amount, convenience_fee: idempotencyResponse!.payment.service_fee)
                    completion(.success(tokenResponse!))
                case .failure(let error):
                    debugPrint("Your transaction failed! \(error.localizedDescription)")
                }
        }
        
        func identityCompletion(response: Result<IdentityResponse, Error>) {
            switch response {
                case .success(let responseIdentity):
                    identityResponse = responseIdentity
                    paymentCard.identity = responseIdentity.id
                    PaymentCardAPI().create(auth: idempotencyResponse!.token, card: paymentCardToDictionary(card: paymentCard), completion: paymentCardCompletion)
                case .failure(let error):
                    debugPrint("Your transaction failed! \(error.localizedDescription)")
                }
        }
        
        let buyer = buyerToDictionary(buyer: identity)
        let identityParameter: [String: Any] = ["tags": tags, "entity": buyer]
        
        IdentityAPI().create(auth: idempotencyResponse!.token, identity: identityParameter , completion: identityCompletion)
    }
    
    //Function that decrypts the idempotency response from the server
    func decryptKMS(response: AWSResponse, completion: @escaping (Idempotency) -> Void) {
        let decodedCredId = Data(base64Encoded: response.credId)!
        let credIdString = String(data: decodedCredId, encoding: .utf8)!
        let keys = credIdString.components(separatedBy: ":")
        
        let credentialsProvider = AWSBasicSessionCredentialsProvider(accessKey: keys[0], secretKey: keys[1], sessionToken: keys[2])
        let configuration = AWSServiceConfiguration(
            region: .USEast1,
            credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        let verifyRequest:AWSKMSVerifyRequest = AWSKMSVerifyRequest()
        let decodedMessage = Data(base64Encoded: response.response)!
        let decodedSignature =  Data(base64Encoded: response.signature)!
        verifyRequest.signature = decodedSignature
        verifyRequest.keyId = "9c25fd5d-fd5e-4f02-83ce-a981f1824c4f"
        verifyRequest.signingAlgorithm = .ecdsaSha384
        verifyRequest.messageType = .RAW
        verifyRequest.message = decodedMessage
        AWSKMS.default().verify(verifyRequest) { (response, err) in
            guard let error = err else {
                let decryptRequest:AWSKMSDecryptRequest = AWSKMSDecryptRequest();
                decryptRequest.ciphertextBlob = decodedMessage
                decryptRequest.encryptionAlgorithm = .rsaesOaepSha256
                decryptRequest.keyId = "c731e986-c849-4534-9367-a004f6ca272c"
                
                AWSKMS.default().decrypt(decryptRequest, completionHandler: { (decryptRes, err) in
                            guard let error = err else {
                                
                                let decoder = JSONDecoder()
                                let decodedIdempotency = try? decoder.decode(Idempotency.self, from: decryptRes!.plaintext!)
        
                                completion(decodedIdempotency!)
                                
                                
                                return
                            }
                            debugPrint(error)
                        })
                return
            }
            debugPrint(error)
        }
    }
    
    
    //Public function that will  tokenize all the information and create an authorization but needs to either be cancelled or confirmed before the payment goes through. Allows for there to be a confirmation step in the transaction process
    
    func tokenize(card: PaymentCard, amount: Int,  buyerOptions: Buyer, fee_mode: FEE_MODE, tags: [String: Any], completion: @escaping (Result<TokenizationResponse, FailureResponse>) -> Void ) {
        
        //Closure to run once the challenge has been retrieved from the PT Server
        func challengeClosure(response: Result<Challenge, Error>) {
            switch response {
            case .success(let challenge):
                service.generateKey { (keyIdentifier, error) in
                    guard error == nil else {
                        debugPrint(error ?? "")
                        return
                    }
                    let encodedChallenge = challenge.challenge.data(using: .utf8)!
                    let hash = Data(SHA256.hash(data: encodedChallenge))
                    self.service.attestKey(keyIdentifier!, clientDataHash: hash) { attestation, error in
                        guard error == nil else {
                            debugPrint(error ?? "")
                            return
                        }
                        let attest = Attestation(attestation: attestation!.base64EncodedString(), nonce: encodedChallenge.base64EncodedString(), key: keyIdentifier!, currency: "USD", amount: amount, fee_mode: fee_mode)
                        postAttestation(attestation: attest, apiKey: self.apiKey, completion: attestationClosure)
                    }
                }
            
            case .failure(let error):
                debugPrint(error.localizedDescription)
            }
        }
        
        //Closure to run once the idempotency has been retrieved from the PT Server
        func attestationClosure(response: Result<AWSResponse, Error>) {
            switch response {
            case .success(let response):
                
                decryptKMS(response: response) { idempotency in
                    self.idempotencyResponse = idempotency
                    self.tokenizeCard(identity: buyerOptions, paymentCard: card, amount: amount, merchant: idempotency.payment.merchant, tags: tags, completion: completion)
                }
                
            case .failure(let error):
                debugPrint(error.localizedDescription)
            }
        }
        
        getChallenge(apiKey: apiKey, completion: challengeClosure)
    }
    
    // Calculated value that can allow someone to check if there is an active token
    public var isTokenized: Bool {
        if tokenResponse != nil {
            return true
        } else {
            return false
        }
    }
    
    
    //Public function that will void the authorization and relase any funds that may be held.
    
    public func cancel(completion: @escaping (Result<Bool, FailureResponse>) -> Void) {
        func cancelCompletion(response: Result<AuthorizationResponse, Error>) {
            switch response {
                case .success(_):
                    completion(.success(true))
                    authResponse = nil
                    tokenResponse = nil
                case .failure(let error):
                    debugPrint("Your void failed! \(error.localizedDescription)")
                }
        }
        
        if let auth = authResponse {
            AuthorizationAPI().void(auth: idempotencyResponse!.token, id: auth.id, completion: cancelCompletion)
        } else {
            let error = FailureResponse(type: "There is no auth to void")
            completion(.failure(error))
        }
    }
    
    
    //Public function that will complete the authorization and send a Completion Response with all the transaction details to the completion handler provided
    
    public func confirm(completion: @escaping (Result<CompletionResponse, FailureResponse>) -> Void) {
        func confirmCompletion(response: Result<AuthorizationResponse, Error>) {
            switch response {
                case .success(let responseAuth):
                    let complete = CompletionResponse(receipt_number: idempotencyResponse!.idempotency, last_four: cardResponse!.last_four, brand: cardResponse!.brand, created_at: authResponse!.created_at, amount: idempotencyResponse!.payment.amount, convenience_fee: idempotencyResponse!.payment.service_fee, state: responseAuth.state)
                    completion(.success(complete))
                    identityResponse = nil
                    cardResponse = nil
                    authResponse = nil
                    tokenResponse = nil
                    idempotencyResponse = nil

                case .failure(let error):
                    debugPrint("Your void failed! \(error.localizedDescription)")
                }
        }
        
        if let token = tokenResponse {
            let captureAuth = CaptureAuth(fee: token.convenience_fee, capture_amount: Int(authResponse!.amount))
            AuthorizationAPI().capture(auth: idempotencyResponse!.token, authorization: captureAuth, id: authResponse!.id ,completion: confirmCompletion)
        } else {
            let error = FailureResponse(type: "There is no auth to capture")
            completion(.failure(error))
        }
    }
}

//These fields are for capturing the card info required to create a payment card associated with an identity to run a transaction

public struct PTCardName: View {
    @EnvironmentObject var card: PaymentCard
    public init() {
    }

    public var body: some View {
        TextField("Name on Card", text: $card.name ?? "")
    }
}

public struct PTCardNumber: View {
    @EnvironmentObject var card: PaymentCard
    public init(){
        
    }
    public var body: some View {
        TextField("Card Number", text: $card.number)
            .keyboardType(.decimalPad)
    }
}

public struct PTExpYear: View {
    @EnvironmentObject var card: PaymentCard
    public init(){
        
    }
    public var body: some View {
        TextField("Expiration Year", text: $card.expiration_year)
            .keyboardType(.decimalPad)
    }
}

public struct PTExpMonth: View {
    @EnvironmentObject var card: PaymentCard
    public init(){
        
    }
    public var body: some View {
        TextField("Expiration Month", text: $card.expiration_month)
            .keyboardType(.decimalPad)
    }
}

public struct PTCvv: View {
    @EnvironmentObject var card: PaymentCard
    public init(){
        
    }
    public var body: some View {
        TextField("CVV", text: $card.security_code)
            .keyboardType(.decimalPad)
    }
}

public struct cardLineOne: View {
    @EnvironmentObject var card: PaymentCard
    
    public var body: some View {
        TextField("Address Line 1", text: $card.address.line1 ?? "")
    }
}

public struct cardLineTwo: View {
    @EnvironmentObject var card: PaymentCard
    
    public var body: some View {
        TextField("Address Line 2", text: $card.address.line2 ?? "")
    }
}

public struct cardCity: View {
    @EnvironmentObject var card: PaymentCard
    
    public var body: some View {
        TextField("City", text: $card.address.city ?? "")
    }
}

public struct cardState: View {
    @EnvironmentObject var card: PaymentCard
    
    public var body: some View {
        TextField("State", text: $card.address.region ?? "")
    }
}

public struct cardZip: View {
    @EnvironmentObject var card: PaymentCard
    
    public var body: some View {
        TextField("Zip", text: $card.address.postal_code ?? "")
    }
}

public struct cardCountry: View {
    @EnvironmentObject var card: PaymentCard
    
    public var body: some View {
        TextField("Country", text: $card.address.country ?? "")
    }
}


public struct PTCardButton: View {
    @EnvironmentObject var card: PaymentCard
    @EnvironmentObject var envBuyer: Buyer
    
    var completion: (Result<TokenizationResponse, FailureResponse>) -> Void
    var amount: Int
    var PT: PayTheory
    var buyer: Buyer?
    var fee_mode: FEE_MODE
    var tags: [String: Any]
    
    /// Button that allows a payment to be tokenized once it has the necessary data (Card Number, Expiration Date, and CVV)
    /// - Parameters:
    ///   - amount: Payment amount that should be charged to the card in cents.
    ///   - PT: PayTheory object that was initiated in your project that allows this to make calls with the API key.
    ///   - buyer: Optional buyer information that allows name, email, phone number, and address of the buyer to be associated with the payment.
    ///   - completion: Function that will handle the result of the tokenization response once it has been returned from the server.
    ///   - fee_mode: optional param that defaults to .SURCHARGE if you don't declare it. Can also pass .SERVICE_FEE as a prop
    public init(amount: Int, PT: PayTheory, buyer: Buyer? = nil, fee_mode: FEE_MODE = .SURCHARGE, tags: [String:Any] = [:], completion: @escaping (Result<TokenizationResponse, FailureResponse>) -> Void) {
        self.completion = completion
        self.amount = amount
        self.PT = PT
        self.fee_mode = fee_mode
        self.tags = tags
    }
    
    
    public var body: some View {
        Button("Create Card") {
            if let identity = buyer {
                PT.tokenize(card: card, amount: amount, buyerOptions: identity, fee_mode: fee_mode, tags: tags, completion: completion)
            } else {
                PT.tokenize(card: card, amount: amount, buyerOptions: envBuyer, fee_mode: fee_mode, tags: tags, completion: completion)
            }
        }
        .disabled(card.isValid == false)
    }
}

public struct PTForm<Content>: View where Content: View {

    let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        Group{
            content()
        }.environmentObject(PaymentCard())
        .environmentObject(Buyer())
    }

}

//These fields are for creating an identity to associate with a purchase if you want to capture customer information

public struct PTBuyerFirstName: View {
    @EnvironmentObject var identity: Buyer
    
   public var body: some View {
        TextField("First Name", text: $identity.first_name ?? "")
    }
}
public struct PTBuyerLastName: View {
    @EnvironmentObject var identity: Buyer
    
    public var body: some View {
        TextField("Last Name", text: $identity.last_name ?? "")
    }
}
public struct PTBuyerPhone: View {
    @EnvironmentObject var identity: Buyer
    
    public var body: some View {
        TextField("Phone", text: $identity.phone ?? "")
    }
}
public struct PTBuyerEmail: View {
    @EnvironmentObject var identity: Buyer
    
    public var body: some View {
        TextField("Email", text: $identity.email ?? "")
    }
}

public struct PTBuyerLineOne: View {
    @EnvironmentObject var identity: Buyer
    
    public var body: some View {
        TextField("Address Line 1", text: $identity.personal_address.line1 ?? "")
    }
}

public struct PTBuyerLineTwo: View {
    @EnvironmentObject var identity: Buyer
    
    public var body: some View {
        TextField("Address Line 2", text: $identity.personal_address.line2 ?? "")
    }
}

public struct PTBuyerCity: View {
    @EnvironmentObject var identity: Buyer
    
    public var body: some View {
        TextField("City", text: $identity.personal_address.city ?? "")
    }
}

public struct PTBuyerState: View {
    @EnvironmentObject var identity: Buyer
    
    public var body: some View {
        TextField("State", text: $identity.personal_address.region ?? "")
    }
}

public struct PTBuyerZip: View {
    @EnvironmentObject var identity: Buyer
    
    public var body: some View {
        TextField("Zip", text: $identity.personal_address.postal_code ?? "")
    }
}

public struct PTBuyerCountry: View {
    @EnvironmentObject var identity: Buyer
    
    public var body: some View {
        TextField("Country", text: $identity.personal_address.country ?? "")
    }
}
