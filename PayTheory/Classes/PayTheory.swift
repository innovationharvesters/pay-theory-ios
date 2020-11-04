//
//  PayTheory.swift
//  PayTheory
//
//  Created by Austin Zani on 11/3/20.
//

public class PayTheory {
    
    var apiKey: String
    
    private var identityResponse: IdentityResponse?
    private var cardResponse: PaymentCardResponse?
    private var authResponse: AuthorizationResponse?
    private var tokenResponse: TokenizationResponse?
    
    public init(apiKey: String){
        self.apiKey = apiKey
    }
    
    private func tokenizeCard(apiAuth: String, identity: Identity, paymentCard: PaymentCard, amount: Int, merchant: String, completion: @escaping (Result<TokenizationResponse, FailureResponse>) -> Void) {
        
        func paymentCardCompletion(response: Result<PaymentCardResponse, Error>) {
            switch response {
                case .success(let card):
                     cardResponse = card
                    let authorization = Authorization(merchant_identity: merchant, amount: "\(amount)", source: card.id)
                    AuthorizationAPI().create(auth: apiAuth, authorization: authorization, completion: authCompletion)
                case .failure(let error):
                    debugPrint("Your transaction failed! \(error.localizedDescription)")
                }
        }
        
        func authCompletion(response: Result<AuthorizationResponse, Error>) {
            switch response {
                case .success(let auth):
                    authResponse = auth
                    tokenResponse = TokenizationResponse(receipt_number: "TEST", first_six: cardResponse!.bin, brand: cardResponse!.bin, amount: Int(auth.amount), convenience_fee: 10)
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
                    PaymentCardAPI().create(auth: apiAuth, card: paymentCard, completion: paymentCardCompletion)
                case .failure(let error):
                    debugPrint("Your transaction failed! \(error.localizedDescription)")
                }
        }
        
        IdentityAPI().create(auth: apiAuth, identity: identity, completion: identityCompletion)
    }
    
    
    //Public function that will  tokenize all the information and create an authorization but needs to either be cancelled or confirmed before the payment goes through. Allows for there to be a confirmation step in the transaction process
    
    public func tokenize(card: PaymentCard, amount: Int,  buyerOptions: Identity?, merchant: String, completion: @escaping (Result<TokenizationResponse, FailureResponse>) -> Void ) {
        if let identity = buyerOptions {
            tokenizeCard(apiAuth: apiKey, identity: identity, paymentCard: card, amount: amount, merchant: merchant, completion: completion)
        } else {
            tokenizeCard(apiAuth: apiKey, identity: Identity(), paymentCard: card, amount: amount, merchant: merchant, completion: completion)
        }
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
            AuthorizationAPI().void(auth: apiKey, id: auth.id, completion: cancelCompletion)
        } else {
            let error = FailureResponse(type: "There is no auth to void")
            completion(.failure(error))
        }
    }
    
    
    //Public function that will complete the authorization and send a Completion Response with all the transaction details to the completion handler provided
    
    public func confirm(completion: @escaping (Result<CompletionResponse, FailureResponse>) -> Void) {
        func cancelCompletion(response: Result<AuthorizationResponse, Error>) {
            switch response {
                case .success(let responseAuth):
                    let complete = CompletionResponse(receipt_number: "Test", last_four: cardResponse!.last_four, brand: cardResponse!.brand, created_at: authResponse!.created_at, amount: tokenResponse!.amount, convenience_fee: tokenResponse!.convenience_fee, state: responseAuth.state)
                    completion(.success(complete))
                    identityResponse = nil
                    cardResponse = nil
                    authResponse = nil
                    tokenResponse = nil

                case .failure(let error):
                    debugPrint("Your void failed! \(error.localizedDescription)")
                }
        }
        
        if let token = tokenResponse {
            let captureAuth = CaptureAuth(fee: token.convenience_fee, capture_amount: token.amount)
            AuthorizationAPI().capture(auth: apiKey, authorization: captureAuth, id: authResponse!.id ,completion: cancelCompletion)
        } else {
            let error = FailureResponse(type: "There is no auth to capture")
            completion(.failure(error))
        }
    }
    
    //Public function that will take the card info, amount, and buyerOptions and complete the transaction fully without the confirmation step
    
    public func transact(card: PaymentCard, amount: Int,  buyerOptions: Identity?, merchant: String, completion: @escaping (Result<CompletionResponse, FailureResponse>) -> Void){
        
        func tokenCompletion(response: Result<TokenizationResponse, FailureResponse>) {
            switch response {
                case .success(_):
                    confirm(completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
        }
        
        if let identity = buyerOptions {
            tokenizeCard(apiAuth: apiKey, identity: identity, paymentCard: card, amount: amount, merchant: merchant, completion: tokenCompletion)
        } else {
            tokenizeCard(apiAuth: apiKey, identity: Identity(), paymentCard: card, amount: amount, merchant: merchant, completion: tokenCompletion)
        }
    }
    
    
    
    
    
}
