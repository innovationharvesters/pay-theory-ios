//
//  EncryptionTests.swift
//  PayTheory_Tests
//
//  Created by Austin Zani on 5/17/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest
@testable import PayTheory
import Sodium


class EncryptionTests: XCTestCase {
    var sodium: Sodium!
    var keyPair: Box.KeyPair!
    var transaction: Transaction!
    var hostToken = "Test Token"
    var ptInstrument = "Test Instrument"
    
    override func setUpWithError() throws {
        sodium = Sodium()
        transaction = Transaction()
        
        keyPair = sodium.box.keyPair()
        transaction.publicKey = keyPair.publicKey
        
        transaction.hostToken = hostToken
        transaction.ptInstrument = ptInstrument
    }
    
    func decryptBody(body: String) -> [String: AnyObject] {
        let decrypted = convertStringToDictionary(text: body) ?? [:]
        let encoded = decrypted["encoded"] as? String ?? ""
        let encryptedBytes = convertStringToByte(string: encoded)
        let decryptedBody = sodium.box.open(nonceAndAuthenticatedCipherText: encryptedBytes,
                                            senderPublicKey: transaction.keyPair.publicKey,
                                            recipientSecretKey: keyPair.secretKey)
        let stringBody = convertBytesToString(bytes: decryptedBody ?? Bytes())
        let decodedData = Data(base64Encoded: stringBody) ?? Data()
        let decodedString = String(data: decodedData, encoding: .utf8) ?? ""
        return convertStringToDictionary(text: decodedString) ?? [:]
    }
    
    func testEncryptBody() {
        let body = ["Test" : "Body"]
        let action = "Test Action"
        let encrypted = transaction.encryptBody(body: body, action: action)
        let newBody = decryptBody(body: encrypted)
        
        XCTAssert(NSDictionary(dictionary: body).isEqual(to: newBody))
    }
    
    func testCreateInstrumentBody() {
        let instrument = ["Test" : "Instrument"]
        let encrypted = transaction.createInstrumentBody(instrument: instrument) ?? ""
        let newBody = decryptBody(body: encrypted)
        let newInstrument = newBody["payment"] as? [String: AnyObject] ?? [:]
        
        XCTAssert(NSDictionary(dictionary: instrument).isEqual(to: newInstrument))
    }
    
    func testCreateIdempotencyBody() {
        let encrypted = transaction.createIdempotencyBody() ?? ""
        let newBody = decryptBody(body: encrypted)
        let newIdempotency = newBody["payment"] as? [String: AnyObject] ?? [:]
        
        XCTAssertEqual(ptInstrument, newIdempotency["pt-instrument"] as? String ?? "")
    }
    
    func testCreateTransferBody() {
        let payment = ["Test" : "Transfer"]
        transaction.paymentToken = payment as [String: AnyObject]
        let encrypted = transaction.createTransferBody() ?? ""
        let newBody = decryptBody(body: encrypted)
        let newTransfer = newBody["transfer"] as? [String: AnyObject] ?? [:]
        
        XCTAssert(NSDictionary(dictionary: newTransfer).isEqual(to: payment))
    }
    
    func testCreateCompletionResponse() {
        transaction.transferToken = transferToken
        transaction.paymentToken = achPaymentToken
        let achCompletion = transaction.createCompletionResponse()
        
        XCTAssert(NSDictionary(dictionary: achCompletion ?? [:]).isEqual(to: achCompletionResponse))
        
        XCTAssertNil(achCompletion?["brand"])
        
        transaction.transferToken?["card_brand"] = brand as AnyObject
        
        let cardCompletion = transaction.createCompletionResponse()
        
        XCTAssert(NSDictionary(dictionary: cardCompletion ?? [:]).isEqual(to: cardCompletionResponse))
        
        XCTAssertNotNil(cardCompletion?["brand"])
    }
    
    func testCreateTokenizationResponse() {
        transaction.paymentToken = cardPaymentToken
        let cardTokenization = transaction.createTokenizationResponse()
        
        XCTAssert(NSDictionary(dictionary: cardTokenization ?? [:]).isEqual(to: cardTokenizationResponse))
        
        XCTAssertNotNil(cardTokenization?["brand"])
        
        transaction.paymentToken = achPaymentToken
        let achTokenization = transaction.createTokenizationResponse()
        
        XCTAssert(NSDictionary(dictionary: achTokenization ?? [:]).isEqual(to: achTokenizationResponse))
        
        XCTAssertNil(achTokenization?["brand"])
    }
    
    func testCreateFailureResponse() {
        transaction.transferToken = transferTokenWithBrand
        let failure = transaction.createFailureResponse()
        
        XCTAssertEqual(failure, failureResponse)
    }
    
    func testResetTransaction() {
        let emptyTransaction = Transaction()
        let sessionTransaction = Transaction()
        sessionTransaction.sessionKey = "Session Key"
        
        XCTAssertNotEqual(sessionTransaction.sessionKey, emptyTransaction.sessionKey)
        
        sessionTransaction.resetTransaction()
        
        XCTAssertEqual(sessionTransaction.sessionKey, emptyTransaction.sessionKey)
    }

}
