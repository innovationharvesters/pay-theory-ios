//
//  Transaction.swift
//  PayTheory
//
//  Created by Austin Zani on 3/29/21.
//

import Foundation
import Sodium

class Transaction: ObservableObject {
    
    var hostToken: String = ""
    var sessionKey: String = ""
    var publicKey: Bytes = "".bytes
    var ptInstrument: String = ""
    var paymentToken: [String: AnyObject] = [:]
    var transferToken: [String: AnyObject] = [:]
    var keyPair: Box.KeyPair
    var tokenizationCompletion: ((Result<[String: Any], FailureResponse>) -> Void)?
    var sodium: Sodium
    var apiKey: String = ""
    var amount: Int = 0
    var feeMode: String = ""
    var tags: [String: Any] = [:]
    
    
    init() {
        self.sodium = Sodium()
        self.keyPair = sodium.box.keyPair()!
    }
    
    func createInstrumentBody(instrument: [String: Any]) -> [String: Any] {
        return [
            "hostToken": hostToken,
            "sessionKey": sessionKey,
            "timing": Date().millisecondsSince1970,
            "payment": instrument
        ]
    }
    
    func createIdempotencyBody() -> [String: Any] {
        var body: [String: Any] = [:]
        body["apiKey"] = apiKey
        body["hostToken"] = hostToken
        body["sessionKey"] = sessionKey
        body["timing"] = Date().millisecondsSince1970
        body["payment"] = [
            "amount": amount,
            "currency": "USD",
            "pt-instrument": ptInstrument,
            "fee_mode": feeMode
        ]
        
        return body
    }
    
    func createTransferBody() -> [String: Any] {
        var body: [String: Any] = [:]
        body["transfer"] = paymentToken
        body["sessionKey"] = sessionKey
        body["timing"] = Date().millisecondsSince1970
        body["tags"] = tags
        
        return body
    }
    
    func createCompletionResponse() -> [String: Any] {
        return [
          "receipt_number": paymentToken["idempotency"] as? String ?? "",
          "last_four": transferToken["last_four"] as? String ?? "",
          "created_at": transferToken["created_at"] as? String ?? "",
          "amount": transferToken["amount"] as? Int ?? 0,
          "service_fee": transferToken["service_fee"] as? Int ?? 0,
          "state": transferToken["state"] as? String ?? "",
          "tags": transferToken["tags"] as? [String: Any] ?? [:]]
    }
}
