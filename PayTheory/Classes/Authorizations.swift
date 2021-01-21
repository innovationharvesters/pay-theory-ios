//
//  PayTheory.swift
//  PayTheory
//
//  Created by Austin Zani on 11/3/20.
//

import Foundation

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
    public var brand: String?
    public var state = "FAILURE"
    public var type: String
    
    public init(type: String) {
        self.type = type
    }
    
    public init(type: String, receipt_number: String, last_four: String, brand: String?) {
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

public enum FEE_MODE: String, Codable {
    case SURCHARGE = "surcharge"
    case SERVICE_FEE = "service_fee"
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
    var fee_mode: FEE_MODE
    
    init(attestation: String, nonce: String, key: String, currency: String, amount: Int, fee_mode: FEE_MODE = .SURCHARGE) {
        self.attestation = attestation
        self.nonce = nonce
        self.key = key
        self.amount = amount
        self.currency = currency
        self.fee_mode = fee_mode
    }
}

class Payment: Codable, Equatable {
    static func == (lhs: Payment, rhs: Payment) -> Bool {
        if lhs.amount == rhs.amount &&
            lhs.service_fee == rhs.service_fee &&
            lhs.currency == rhs.currency &&
            lhs.merchant == rhs.merchant {
            return true
        }
        return false
    }
    
    var currency: String
    var amount: Int
    var merchant: String
    var service_fee: Int
    var fee_mode: String
    
    init(currency: String, amount: Int, service_fee: Int, merchant: String, fee_mode: String) {
        self.amount = amount
        self.currency = currency
        self.service_fee = service_fee
        self.merchant = merchant
        self.fee_mode = fee_mode
    }
}

class IdempotencyResponse: Codable, Equatable {
    static func == (lhs: IdempotencyResponse, rhs: IdempotencyResponse) -> Bool {
        if lhs.response == rhs.response && lhs.signature == rhs.signature && lhs.credId == rhs.credId {return true}
        return false
    }
    
    var response: String
    var signature: String
    var credId: String
    var idempotency: String
    var payment: Payment
    
    init(response: String, signature: String, credId: String, idempotency: String, payment: Payment) {
        self.signature = signature
        self.response = response
        self.credId = credId
        self.idempotency = idempotency
        self.payment = payment
    }
        
}

