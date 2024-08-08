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
    var sessionKey: String?
    var publicKey: Bytes?
    var ptInstrument: String?
    var idempotencyToken: [String: AnyObject]?
    var transferToken: [String: AnyObject]?
    var apiKey: String
    var amount: Int = 0
    var keyPair: Box.KeyPair
    var sodium: Sodium
    var feeMode: FEE_MODE = .MERCHANT_FEE
    var metadata: [String: Any] = [:]
    var payTheoryData: [String: Any] = [:]
    var lastMessage: String?
    var payor: Payor?
    var confirmation: Bool = false
    
    init(apiKey: String) {
        self.apiKey = apiKey
        sodium = Sodium()
        keyPair = sodium.box.keyPair()!
    }
    
    func encryptBody(body: [String: Any], action: String) -> String {
        var message: [String: Any] = [:]
        let strigifiedMessage = stringify(jsonDictionary: body).bytes
        let encryptedMessage: Bytes =
            sodium.box.seal(message: strigifiedMessage,
                            recipientPublicKey: publicKey!,
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
                "sessionKey": sessionKey!,
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
                "sessionKey": sessionKey!,
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
    
    func createTokenizePaymentMethodBody(instrument: [String: Any], payorId: String? = nil) -> String? {
        if let host = hostToken {
            return encryptBody(body: [
                "hostToken": host,
                "sessionKey": sessionKey!,
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
    
    func resetTransaction() {
        DispatchQueue.main.async {
            self.hostToken = nil
        }
        sessionKey = ""
        ptInstrument = nil
        idempotencyToken = nil
        transferToken = nil
        amount = 0
        lastMessage = nil
    }
}
