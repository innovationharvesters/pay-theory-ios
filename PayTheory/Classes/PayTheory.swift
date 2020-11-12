//
//  PayTheory.swift
//  PayTheory
//
//  Created by Austin Zani on 11/3/20.
//

import DeviceCheck
import CryptoKit

import AWSKMS

public class PayTheory {
    
    let service = DCAppAttestService.shared
    
    var apiKey: String
    
    private var identityResponse: IdentityResponse?
    private var cardResponse: PaymentCardResponse?
    private var authResponse: AuthorizationResponse?
    private var tokenResponse: TokenizationResponse?
    private var idempotencyResponse: Idempotency?
    
    
    public init(apiKey: String){
        self.apiKey = apiKey
    }
    
    
    //Function that sends the BuyerOptions, PaymentCard/BankAccount, and Authorization to the server and returns a Result<TokenizationResponse, FailureResponse> to the completion handler.
    private func tokenizeCard(identity: Buyer, paymentCard: PaymentCard, amount: Int, merchant: String, completion: @escaping (Result<TokenizationResponse, FailureResponse>) -> Void) {
        
        func paymentCardCompletion(response: Result<PaymentCardResponse, Error>) {
            switch response {
                case .success(let card):
                     cardResponse = card
                    let authorization = Authorization(merchant_identity: merchant, amount: "\(amount)", source: card.id, idempotency_id: idempotencyResponse!.idempotency)
                    AuthorizationAPI().create(auth: idempotencyResponse!.token, authorization: authorization, completion: authCompletion)
                case .failure(let error):
                    debugPrint("Your transaction failed! \(error.localizedDescription)")
                }
        }
        
        func authCompletion(response: Result<AuthorizationResponse, Error>) {
            switch response {
                case .success(let auth):
                    authResponse = auth
                    tokenResponse = TokenizationResponse(receipt_number: idempotencyResponse!.idempotency, first_six: cardResponse!.bin, brand: cardResponse!.bin, amount: idempotencyResponse!.payment.amount, convenience_fee: idempotencyResponse!.payment.convenience_fee)
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
                    PaymentCardAPI().create(auth: idempotencyResponse!.token, card: paymentCard, completion: paymentCardCompletion)
                case .failure(let error):
                    debugPrint("Your transaction failed! \(error.localizedDescription)")
                }
        }
        
        IdentityAPI().create(auth: idempotencyResponse!.token, identity: identity, completion: identityCompletion)
    }
    
    
    //Function that decrypts the idempotency response from the server
    private func decryptKMS(response: AWSResponse, completion: @escaping (Idempotency) -> Void) {
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
    
    public func tokenize(card: PaymentCard, amount: Int,  buyerOptions: Buyer?, completion: @escaping (Result<TokenizationResponse, FailureResponse>) -> Void ) {
        
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
                        let attest = Attestation(attestation: attestation!.base64EncodedString(), nonce: encodedChallenge.base64EncodedString(), key: keyIdentifier!, currency: "USD", amount: amount)
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
                    if let identity = buyerOptions {
                        self.tokenizeCard(identity: identity, paymentCard: card, amount: amount, merchant: idempotency.payment.merchant, completion: completion)
                    } else {
                        self.tokenizeCard(identity: Buyer(), paymentCard: card, amount: amount, merchant: idempotency.payment.merchant, completion: completion)
                    }
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
    
    public func cancel(completion: @escaping (Result<AuthorizationResponse, FailureResponse>) -> Void) {
        func cancelCompletion(response: Result<AuthorizationResponse, Error>) {
            switch response {
                case .success(let responseIdentity):
                    completion(.success(responseIdentity))
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
                    let complete = CompletionResponse(receipt_number: idempotencyResponse!.idempotency, last_four: cardResponse!.last_four, brand: cardResponse!.brand, created_at: authResponse!.created_at, amount: idempotencyResponse!.payment.amount, convenience_fee: idempotencyResponse!.payment.convenience_fee, state: responseAuth.state)
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
    
    //Public function that will take the card info, amount, and buyerOptions and complete the transaction fully without the confirmation step
    
//    public func transact(card: PaymentCard, amount: Int,  buyerOptions: Buyer?, merchant: String, completion: @escaping (Result<CompletionResponse, FailureResponse>) -> Void){
//
//        func tokenCompletion(response: Result<TokenizationResponse, FailureResponse>) {
//            switch response {
//                case .success(_):
//                    confirm(completion: completion)
//                case .failure(let error):
//                    completion(.failure(error))
//                }
//        }
//        
//        if let identity = buyerOptions {
//            tokenizeCard(apiAuth: apiKey, identity: identity, paymentCard: card, amount: amount, merchant: merchant, completion: tokenCompletion)
//        } else {
//            tokenizeCard(apiAuth: apiKey, identity: Buyer(), paymentCard: card, amount: amount, merchant: merchant, completion: tokenCompletion)
//        }
//    }
    
    
    
    
    
}
