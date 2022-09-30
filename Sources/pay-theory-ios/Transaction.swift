//
//  Transaction.swift
//  PayTheory
//
//  Created by Austin Zani on 3/29/21.
//

import Foundation
import Sodium
//import CryptoKit

class Transaction: ObservableObject {
    
    @Published var hostToken: String?
    var sessionKey: String = ""
    var publicKey: Bytes = "".bytes
    var ptInstrument: String?
    var idempotencyToken: [String: AnyObject]?
    var transferToken: [String: AnyObject]?
    var completionHandler: ((Result<[String: Any], FailureResponse>) -> Void)?
    var apiKey: String = ""
    var amount: Int = 0
    var keyPair: Box.KeyPair
    var sodium: Sodium
    var feeMode: FEE_MODE = .INTERCHANGE
    var metadata: [String: Any] = [:]
    var payTheoryData: [String: Any] = [:]
    var lastMessage: String?
    var payor: Payor?
    var confirmation: Bool = false
    
    init() {
        sodium = Sodium()
        keyPair = sodium.box.keyPair()!
    }
    
    
//    func encryptBody(body: [String: Any], action: String) -> String? {
//        var message: [String: Any] = [:]
//        let strigifiedMessage = stringify(jsonDictionary: body).data(using: .utf8)!
//        do {
//            print(publicKey.rawRepresentation)
//            print(serverKey)
//            let serverPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: serverKey)
//            print(serverPublicKey)
//            let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: serverPublicKey)
//            print(sharedSecret)
//            let sharedKey = sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self, salt: Data(), sharedInfo: Data(), outputByteCount: 32)
//            print(sharedKey)
//            let encryptedMessage = try ChaChaPoly.seal(strigifiedMessage, using: sharedKey).combined
//            let sealedBox = try ChaChaPoly.SealedBox(combined: encryptedMessage)
//            let nonceAndMessage = Data(sealedBox.nonce) + Data(sealedBox.ciphertext)
//            print(Data(sealedBox.nonce))
//            message["encoded"] = nonceAndMessage.base64EncodedString()
//            message["sessionKey"] = sessionKey
//            message["publicKey"] = publicKey.rawRepresentation.base64EncodedString()
//            message["action"] =  action
//            return stringify(jsonDictionary: message)
//        } catch {
//            return nil
//        }
//    }
    
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

    func decryptBody(body: String, publicKey: String) -> String {
        let senderKey = convertStringToByte(string: publicKey)
        let bodyBytes = convertStringToByte(string: body)
        if let decrypted = sodium.box.open(nonceAndAuthenticatedCipherText: bodyBytes,
                                           senderPublicKey: senderKey,
                                           recipientSecretKey: self.keyPair.secretKey) {
            let decryptedString = convertBytesToString(bytes: decrypted)
            let decodedData = Data(base64Encoded: decryptedString) ?? Data()
            let decodedString = String(data: decodedData, encoding: .utf8) ?? ""
            return decodedString
        }
        return ""
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
                "payor_info": payorToDictionary(payor: payor ?? Payor()),
                "pay_theory_data": payTheoryData,
                "metadata": metadata
            ], action: BARCODE)
        } else {
            return nil
        }
    }
    
    func createTransferPartOneBody(instrument: [String: Any]) -> String? {
        if let host = hostToken {
            return encryptBody(body: [
                "hostToken": host,
                "sessionKey": sessionKey,
                "timing": Date().millisecondsSince1970,
                "payment_method_data": instrument,
                "payment_data": [
                    "fee_mode": feeMode.rawValue,
                    "currency": "USD",
                    "amount": amount
                ],
                "confirmation_needed": confirmation,
                "payor_info": payorToDictionary(payor: payor ?? Payor()),
                "pay_theory_data": payTheoryData,
                "metadata": metadata
            ], action: TRANSFER_PART1)
        } else {
            return nil
        }
    }
    
    func createTransferPartTwoBody() -> String? {
        if let transfer = idempotencyToken {
            return encryptBody(body: [
                "payment_prep": transfer,
                "sessionKey": sessionKey,
                "timing": Date().millisecondsSince1970,
                "metadata": metadata
            ], action: TRANSFER_PART2)
        } else {
            return nil
        }
    }
    
    func createTokenizePaymentMethodBody(instrument: [String: Any], payorId: String? = nil) -> String? {
        if let host = hostToken {
            return encryptBody(body: [
                "hostToken": host,
                "sessionKey": sessionKey,
                "timing": Date().millisecondsSince1970,
                "payment_method_data": instrument,
                "payor_info": payorToDictionary(payor: payor ?? Payor()),
                "pay_theory_data": [
                    "payor_id": payorId ?? ""
                ],
                "metadata": metadata
            ], action: TOKENIZE)
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
              "metadata": transfer["metadata"] as? [String: Any] ?? [:],
              "payor_id": transfer["payor_id"] as? String ?? "",
              "payment_method_id": transfer["payment_method_id"] as? String ?? "",
              "brand": ""
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
                "amount": payment["amount"] as? Int ?? 0,
                "service_fee": payment["fee"] as? Int ?? 0,
                "brand": payment["brand"] as? String ?? "",
                "first_six": payment["first_six"] as? String ?? "",
                "last_four": payment["last_four"] as? String ?? ""
                ]
            if feeMode == FEE_MODE.INTERCHANGE {
                result["fee"] = 0
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
