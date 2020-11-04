//
//  PayTheory.swift
//  PayTheory
//
//  Created by Austin Zani on 11/3/20.
//

import Foundation

class Authorization: ObservableObject, Codable {
    var source = ""
    var merchant_identity = ""
    var currency = "USD"
    var amount = ""
    var processor: String?
    
    enum CodingKeys: CodingKey {
        case source, merchant_identity, currency, amount, processor, tags
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(source, forKey: .source)
        try container.encode(merchant_identity, forKey: .merchant_identity)
        try container.encode(currency, forKey: .currency)
        try container.encode(amount, forKey: .amount)
        try container.encode(processor, forKey: .processor)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        source = try container.decode(String.self, forKey: .source)
        merchant_identity = try container.decode(String.self, forKey: .merchant_identity)
        currency = try container.decode(String.self, forKey: .currency)
        amount = try container.decode(String.self, forKey: .amount)
        processor = try container.decodeIfPresent(String.self, forKey: .processor) ?? nil
    }
    
    var hasRequiredFields: Bool {
        if source.isEmpty || merchant_identity.isEmpty || amount.isEmpty || currency.isEmpty {
            return false
        }
        return true
    }
    
    init(merchant_identity: String, source: String) {
        self.merchant_identity = merchant_identity
        self.source = source
    }
    
    init(merchant_identity: String, amount: String, source: String) {
        self.merchant_identity = merchant_identity
        self.amount = amount
        self.source = source
    }
}

class CaptureAuth: ObservableObject, Codable {
    var fee: Int
    var capture_amount: Int
    
    enum CodingKeys: CodingKey {
        case fee, capture_amount
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(capture_amount, forKey: .capture_amount)
        try container.encode(fee, forKey: .fee)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fee = try container.decode(Int.self, forKey: .fee)
        capture_amount = try container.decode(Int.self, forKey: .capture_amount)
    }
    
    init(fee: Int, capture_amount: Int) {
        self.fee = fee
        self.capture_amount = capture_amount
    }
}

public class AuthorizationResponse: Codable {
    var id: String
    var application: String
    var amount: Double
    var state: String
    var currency: String
    var transfer: String?
    var updated_at: String
    var source: String
    var merchant_identity: String
    var is_void: Bool
    var void_state: String
    var expires_at: String
    var created_at: String
}

public class CompletionResponse: Codable {
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

public class TokenizationResponse: Codable {
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

public class FailureResponse: Codable, Error {
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
