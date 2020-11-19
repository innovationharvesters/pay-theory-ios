//
//  PayTheory.swift
//  PayTheory
//
//  Created by Austin Zani on 11/3/20.
//

import Foundation

class Authorization: ObservableObject, Codable, Equatable {
    static func == (lhs: Authorization, rhs: Authorization) -> Bool {
        if lhs.source == rhs.source &&
        lhs.merchant_identity == rhs.merchant_identity &&
        lhs.currency == rhs.currency &&
        lhs.amount == rhs.amount &&
        lhs.processor == rhs.processor {
            return true
        }
        
        return false
    }
    
    var source = ""
    var merchant_identity = ""
    var currency = "USD"
    @Published var amount = ""
    var processor: String?
    var idempotency_id: String
    
    enum CodingKeys: CodingKey {
        case source, merchant_identity, currency, amount, processor, tags, idempotency_id
    }
    
    func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(source, forKey: .source)
        try container.encode(merchant_identity, forKey: .merchant_identity)
        try container.encode(currency, forKey: .currency)
        try container.encode(amount, forKey: .amount)
        try container.encode(processor, forKey: .processor)
        try container.encode(idempotency_id, forKey: .idempotency_id)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        source = try container.decode(String.self, forKey: .source)
        merchant_identity = try container.decode(String.self, forKey: .merchant_identity)
        currency = try container.decode(String.self, forKey: .currency)
        amount = try container.decode(String.self, forKey: .amount)
        processor = try container.decodeIfPresent(String.self, forKey: .processor) ?? nil
        idempotency_id = try container.decode(String.self, forKey: .idempotency_id)
    }
    
    
    init(merchant_identity: String, amount: String, source: String, idempotency_id: String) {
        self.merchant_identity = merchant_identity
        self.amount = amount
        self.source = source
        self.idempotency_id = idempotency_id
    }
}

class CaptureAuth: Codable, Equatable {
    static func == (lhs: CaptureAuth, rhs: CaptureAuth) -> Bool {
        if lhs.capture_amount == rhs.capture_amount &&
            lhs.fee == rhs.fee {
            return true
        }
        return false
    }
    
    var fee: Int
    var capture_amount: Int
    
    init(fee: Int, capture_amount: Int) {
        self.fee = fee
        self.capture_amount = capture_amount
    }
}

class AuthorizationResponse: Codable, Equatable {
    static func == (lhs: AuthorizationResponse, rhs: AuthorizationResponse) -> Bool {
        if lhs.id == rhs.id &&
        lhs.application == rhs.application &&
        lhs.amount == rhs.amount &&
        lhs.state == rhs.state &&
        lhs.currency == rhs.currency &&
        lhs.transfer == rhs.transfer &&
        lhs.updated_at == rhs.updated_at &&
        lhs.source == rhs.source &&
        lhs.merchant_identity == rhs.merchant_identity &&
        lhs.is_void == rhs.is_void &&
        lhs.void_state == rhs.void_state &&
        lhs.expires_at == rhs.expires_at &&
            lhs.created_at == rhs.created_at  {
            return true
        }
        
        return false
    }
    
    var id = ""
    var application = ""
    var amount: Double = 0
    var state = ""
    var currency = ""
    var transfer: String?
    var updated_at = ""
    var source = ""
    var merchant_identity = ""
    var is_void: Bool = false
    var void_state = ""
    var expires_at = ""
    var created_at = ""
    
    init() {
        
    }
}

public class CompletionResponse: Equatable {
    public static func == (lhs: CompletionResponse, rhs: CompletionResponse) -> Bool {
        if lhs.receipt_number == rhs.receipt_number &&
        lhs.last_four == rhs.last_four &&
        lhs.brand == rhs.brand &&
        lhs.created_at == rhs.created_at &&
        lhs.amount == rhs.amount &&
        lhs.convenience_fee == rhs.convenience_fee &&
            lhs.state == rhs.state {
            return true
        }
        
        return false
    }
    
    
    public var receipt_number: String
    public var last_four: String
    public var brand: String
    public var created_at: String
    public var amount: Int
    public var convenience_fee: Int
    public var state: String
    
    public init(receipt_number: String, last_four: String, brand: String, created_at: String, amount: Int, convenience_fee: Int, state: String){
        self.receipt_number = receipt_number
        self.last_four = last_four
        self.brand = brand
        self.created_at = created_at
        self.amount = amount
        self.convenience_fee = convenience_fee
        self.state = state
    }
}

public class TokenizationResponse: Equatable {
    public static func == (lhs: TokenizationResponse, rhs: TokenizationResponse) -> Bool {
        if lhs.receipt_number == rhs.receipt_number &&
        lhs.first_six == rhs.first_six &&
        lhs.brand == rhs.brand &&
        lhs.amount == rhs.amount &&
        lhs.convenience_fee == rhs.convenience_fee {
            return true
        }
        
        return false
    }
    
    public var first_six: String
    public var brand: String
    public var receipt_number: String
    public var amount: Int
    public var convenience_fee: Int
    
    public init(receipt_number: String, first_six: String, brand: String, amount: Int, convenience_fee: Int){
        self.receipt_number = receipt_number
        self.first_six = first_six
        self.brand = brand
        self.amount = amount
        self.convenience_fee = convenience_fee
    }
}

public class FailureResponse: Error, Equatable {
    public static func == (lhs: FailureResponse, rhs: FailureResponse) -> Bool {
        if lhs.receipt_number == rhs.receipt_number &&
        lhs.last_four == rhs.last_four &&
        lhs.brand == rhs.brand &&
        lhs.state == rhs.state &&
        lhs.type == rhs.type {
            return true
        }
        
        return false
    }
    
    public var receipt_number = ""
    public var last_four = ""
    public var brand = ""
    public var state = "FAILURE"
    public var type: String
    
    public init(type: String) {
        self.type = type
    }
    
    public init(type: String, receipt_number: String, last_four: String, brand: String) {
        self.type = type
        self.receipt_number = receipt_number
        self.last_four = last_four
        self.brand = brand
    }
}

class Challenge: Codable, Equatable {
    static func == (lhs: Challenge, rhs: Challenge) -> Bool {
        if lhs.challenge == rhs.challenge { return true }
        return false
    }
    
    var challenge = ""
    
    init() {
        
    }
}

class Attestation: Codable, Equatable {
    static func == (lhs: Attestation, rhs: Attestation) -> Bool {
        if lhs.attestation == rhs.attestation &&
            lhs.type == rhs.type &&
            lhs.nonce == rhs.nonce { return true }
        return false
    }
    
    var attestation: String
    var type = "ios"
    var nonce: String
    var key: String
    var currency: String
    var amount: Int
    
    init(attestation: String, nonce: String, key: String, currency: String, amount: Int) {
        self.attestation = attestation
        self.nonce = nonce
        self.key = key
        self.amount = amount
        self.currency = currency
    }
}

class Idempotency: Codable, Equatable {
    static func == (lhs: Idempotency, rhs: Idempotency) -> Bool {
        if lhs.token == rhs.token &&
            lhs.idempotency == rhs.idempotency &&
            lhs.payment == rhs.payment {
            return true
        }
        return false
    }
    
    var idempotency: String
    var payment: Payment
    var token: String
    
    init(idempotency: String, payment: Payment, token: String) {
        self.idempotency = idempotency
        self.payment = payment
        self.token = token
    }
    
}

class Payment: Codable, Equatable {
    static func == (lhs: Payment, rhs: Payment) -> Bool {
        if lhs.amount == rhs.amount &&
            lhs.convenience_fee == rhs.convenience_fee &&
            lhs.currency == rhs.currency &&
            lhs.merchant == rhs.merchant {
            return true
        }
        return false
    }
    
    var currency: String
    var amount: Int
    var merchant: String
    var convenience_fee: Int
    
    init(currency: String, amount: Int, convenience_fee: Int, merchant: String) {
        self.amount = amount
        self.currency = currency
        self.convenience_fee = convenience_fee
        self.merchant = merchant
    }
}

class AWSResponse: Codable, Equatable {
    static func == (lhs: AWSResponse, rhs: AWSResponse) -> Bool {
        if lhs.response == rhs.response && lhs.signature == rhs.signature && lhs.credId == rhs.credId {return true}
        return false
    }
    
    var response: String
    var signature: String
    var credId: String
    
    init(response: String, signature: String, credId: String) {
        self.signature = signature
        self.response = response
        self.credId = credId
    }
        
}
