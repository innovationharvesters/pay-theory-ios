//
//  Transaction.swift
//  PayTheory
//
//  Created by Austin Zani on 3/29/21.
//

import Foundation
import Sodium

class Transaction: ObservableObject {
    
    @Published var hostToken: String?
    var sessionKey: String = ""
    var publicKey: Bytes = "".bytes
    var ptInstrument: String?
    var idempotencyToken: [String: AnyObject]?
    var transferToken: [String: AnyObject]?
    var keyPair: Box.KeyPair
    var completionHandler: ((Result<[String: Any], FailureResponse>) -> Void)?
    var sodium: Sodium
    var apiKey: String = ""
    var amount: Int = 0
    var feeMode: FEE_MODE = .SURCHARGE
    var tags: [String: Any] = [:]
    var lastMessage: String?
    var buyerOptions: Buyer?
    
    init() {
        self.sodium = Sodium()
        self.keyPair = sodium.box.keyPair()!
    }
    
    func encryptBody(body: [String: Any], action: String) -> String {
        var message: [String: Any] = [:]
        let strigifiedMessage = stringify(jsonDictionary: body).bytes
        let encryptedMessage: Bytes =
            sodium.box.seal(message: strigifiedMessage,
                            recipientPublicKey: publicKey,
                            senderSecretKey: self.keyPair.secretKey)!

        message["encoded"] = convertBytesToString(bytes: encryptedMessage)
        message["sessionKey"] = sessionKey
        message["publicKey"] = convertBytesToString(bytes: self.keyPair.publicKey)
        message["action"] =  action
        return stringify(jsonDictionary: message)
    }
    
    func createCashBody(payment: [String: Any]) -> String? {
        if let host = hostToken {
            var newPayment = payment
            newPayment["amount"] = amount
            return encryptBody(body: [
                "hostToken": host,
                "sessionKey": sessionKey,
                "timing": Date().millisecondsSince1970,
                "payment": newPayment,
                "buyerOptions": buyerToDictionary(buyer: buyerOptions ?? Buyer()),
                "tags": tags
            ], action: CASH)
        } else {
            return nil
        }
    }
    
    func createTransferPartOneBody(instrument: [String: Any]) -> String? {
        if let host = hostToken {
            let confirmation = feeMode == .SERVICE_FEE ? true : false
            return encryptBody(body: [
                "hostToken": host,
                "sessionKey": sessionKey,
                "timing": Date().millisecondsSince1970,
                "instrument_data": instrument,
                "payment_data": [
                    "fee_mode": feeMode.rawValue,
                    "currency": "USD",
                    "amount": amount
                ],
                "confirmation_needed": confirmation,
                "buyerOptions": buyerToDictionary(buyer: buyerOptions ?? Buyer()),
                "tags": tags
            ], action: TRANSFER_PART1)
        } else {
            return nil
        }
    }
    
    func createTransferPartTwoBody() -> String? {
        if let transfer = idempotencyToken {
            return encryptBody(body: [
                "transfer": transfer,
                "sessionKey": sessionKey,
                "timing": Date().millisecondsSince1970,
                "tags": tags
            ], action: TRANSFER_PART2)
        } else {
            return nil
        }
    }
    
    func createCancelBody() -> String? {
        if let payment_intent = idempotencyToken?["payment_intent_id"] as? String {
            return encryptBody(body: [
                "payment_intent_id": payment_intent,
                "sessionKey": sessionKey,
                "timing": Date().millisecondsSince1970
            ], action: CANCEL_TRANSFER)
        } else {
            return nil
        }
    }
    
    func createCompletionResponse() -> [String: Any]? {
        if let transfer = transferToken {
            var result: [String: Any] = [
              "receipt_number": idempotencyToken?["idempotency"] as? String ?? "",
              "last_four": transfer["last_four"] as? String ?? "",
              "created_at": transfer["created_at"] as? String ?? "",
              "amount": transfer["amount"] as? Int ?? 0,
              "service_fee": transfer["service_fee"] as? Int ?? 0,
              "state": transfer["state"] as? String ?? "",
              "tags": transfer["tags"] as? [String: Any] ?? [:]
            ]
            if let brand = transfer["card_brand"] {
                result["brand"] = brand as? String ?? ""
            }
            
            return result
        } else {
            return nil
        }
    }
    
    func createTokenizationResponse() -> [String: Any]? {
        if let payment = idempotencyToken {
            var result: [String: Any] = [
                "receipt_number": payment["idempotency"] as? String ?? "",
                "amount": payment["payment"]?["amount"] as? Int ?? 0,
                "convenience_fee": payment["payment"]?["service_fee"] as? Int ?? 0,
                ]
            if let brand = payment["bin"]?["card_brand"] as? String {
                result["brand"] = brand
                result["first_six"] = payment["bin"]?["first_six"] as? String ?? ""
            } else {
                result["last_four"] = payment["bin"]?["last_four"] as? String ?? ""
            }
            return result
        } else {
            return nil
        }
    }
    
    func createFailureResponse() -> FailureResponse {
        let type = transferToken?["type"] as? String ?? ""
        let receipt = transferToken?["receipt_number"] as? String ?? ""
        let lastFour = transferToken?["last_four"] as? String ?? ""
        let brand = transferToken?["card_brand"] as? String ?? ""
        
        return FailureResponse(type: type, receiptNumber: receipt, lastFour: lastFour, brand: brand)
    }
    
    func resetTransaction() {
        DispatchQueue.main.async {
            self.hostToken = nil
        }
        sessionKey = ""
        ptInstrument = nil
        idempotencyToken = nil
        transferToken = nil
        completionHandler = nil
        amount = 0
        lastMessage = nil
    }
}
