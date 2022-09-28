//
//  DataModelTests.swift
//  PayTheory_Tests
//
//  Created by Austin Zani on 5/17/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest
@testable import PayTheory

class DataModelTests: XCTestCase {

    func testClearBankAccount() {
        let bank = ACH()
        bank.name = "Test"
        bank.accountNumber = "11111111"
        bank.accountType = 0
        bank.bankCode = "11111111"
        
        let bank2 = ACH()

        XCTAssertNotEqual(bank, bank2)

        bank.clear()

        XCTAssertEqual(bank, bank2)
    }

//    func testBankAccountValidBankCode() {
//        let bankAccount = BankAccount()
//
//        XCTAssertFalse(bankAccount.validBankCode)
//
//        bankAccount.bankCode = "000"
//
//        XCTAssertFalse(bankAccount.validBankCode)
//
//        bankAccount.bankCode = "789456124"
//
//        XCTAssertTrue(bankAccount.validBankCode)
//
//        bankAccount.bankCode = "789456124000"
//
//        XCTAssertFalse(bankAccount.validBankCode)
//
//        bankAccount.bankCode = "F89456124"
//
//        XCTAssertFalse(bankAccount.validBankCode)
//
//        bankAccount.bankCode = "7F9456124"
//
//        XCTAssertFalse(bankAccount.validBankCode)
//
//        bankAccount.bankCode = "78F456124"
//
//        XCTAssertFalse(bankAccount.validBankCode)
//    }
    
    func testClearPaymentCard() {
        let card = Card()
        card.number = "11111111"
        card.expirationDate = "12 / 22"
        card.securityCode = "240"
        
        let card2 = Card()

        XCTAssertNotEqual(card, card2)

        card.clear()

        XCTAssertEqual(card, card2)
    }

    func testCreditCardBrand() {
        let card = Card()

        XCTAssertEqual(card.brand, "")

        card.number = "4024007148719528"

        XCTAssertEqual(card.brand, "Visa")

        card.number = "6011876717071788"

        XCTAssertEqual(card.brand, "Discover")

        card.number = "5548281345836773"

        XCTAssertEqual(card.brand, "MasterCard")

        card.number = "3538346422215451"

        XCTAssertEqual(card.brand, "JCB")

        card.number = "376520957732459"

        XCTAssertEqual(card.brand, "American Express")

        card.number = "30238697651289"

        XCTAssertEqual(card.brand, "Diners Club")
    }

    func testCardLastFour() {
        let card = Card()

        XCTAssertEqual(card.lastFour, "")

        card.number = "4024007148719528"

        XCTAssertEqual(card.lastFour, "9528")

        card.number = "6011876717071788"

        XCTAssertEqual(card.lastFour, "1788")
    }

    func testCardFirstSix() {
        let card = Card()

        XCTAssertEqual(card.firstSix, "")

        card.number = "4024007148719528"

        XCTAssertEqual(card.firstSix, "402400")

        card.number = "6011876717071788"

        XCTAssertEqual(card.firstSix, "601187")
    }

//    func testCreditCardValidCardNumber() {
//        let card = PaymentCard()
//
//        XCTAssertFalse(card.validCardNumber)
//
//        card.number = "0001"
//
//        XCTAssertFalse(card.validCardNumber)
//
//        card.number = "4242424242424242"
//
//        XCTAssertTrue(card.validCardNumber)
//
//        card.number = "4929449361763377"
//
//        XCTAssertTrue(card.validCardNumber)
//
//        card.number = "1111111111111111"
//
//        XCTAssertFalse(card.validCardNumber)
//
//        card.number = "card-number-test"
//
//        XCTAssertFalse(card.validCardNumber)
//    }

    func testCreditCardIsValid() {
        let card = Card()
        XCTAssertFalse(card.isValid)

        card.number =  "424242424242424242424242424242"
        card.expirationDate = "12 / 22"
        card.securityCode = "232"

        XCTAssertFalse(card.isValid)

        card.number = "4242424242424242"
        card.expirationDate = "12 / 17"
        card.securityCode = "232"

        XCTAssertFalse(card.isValid)

        card.number = "4242424242424242"
        card.expirationDate = "12 / 22"
        card.securityCode = "232"

        XCTAssertTrue(card.isValid)

    }

//    func testCreditCardExpIsValid() {
//        let card = PaymentCard()
//        XCTAssertFalse(card.validExpirationDate)
//
//        card.expirationDate = "12 / 22"
//
//        XCTAssertTrue(card.validExpirationDate)
//
//        card.expirationDate = "NO / 22"
//
//        XCTAssertFalse(card.validExpirationDate)
//
//        card.expirationDate = "12 / NO"
//
//        XCTAssertFalse(card.validExpirationDate)
//
//    }
//
//    func testCreditCardValidExpDate() {
//        let card = PaymentCard()
//        XCTAssertFalse(card.validExpirationDate)
//
//        card.expirationDate = "13 / 22"
//
//
//        XCTAssertFalse(card.validExpirationDate)
//
//        card.expirationDate = "13 / 22"
//
//        XCTAssertFalse(card.validExpirationDate)
//
//        card.expirationDate = "11 / 2019"
//
//        XCTAssertFalse(card.validExpirationDate)
//
//        card.expirationDate = "NO"
//
//        XCTAssertFalse(card.validExpirationDate)
//
//        card.expirationDate = "13 / NO"
//
//        XCTAssertFalse(card.validExpirationDate)
//
//        card.expirationDate = "11 / 22"
//
//        XCTAssertTrue(card.validExpirationDate)
//    }

    func testDidSetCardDate() {
        let card = Card()

        card.expirationDate = "1"

        XCTAssertEqual(card.expirationDate, "1")

        card.expirationDate = "2"

        XCTAssertEqual(card.expirationDate, "02 / ")

        card.expirationDate = "22"

        XCTAssertEqual(card.expirationDate, "02 / 2")

        card.expirationDate = "02 /"

        XCTAssertEqual(card.expirationDate, "0")

        card.expirationDate = "02 / 2022"

        XCTAssertEqual(card.expirationDate, "02 / 2022")

        card.expirationDate = "02 / 202222"

        XCTAssertEqual(card.expirationDate, "02 / 2022")

        card.expirationDate = "02"

        XCTAssertEqual(card.expirationDate, "02 / ")

    }

    func testDidSetCadNumber() {
        let card = Card()

        card.number = "1"

        XCTAssertEqual(card.number, "1")

        card.number = "3456"

        XCTAssertEqual(card.number, "3456 ")

        card.number = "3456 12345"

        XCTAssertEqual(card.number, "3456 12345")

        card.number = "3456 123456"

        XCTAssertEqual(card.number, "3456 123456 ")

        card.number = "3456 123456"

        XCTAssertEqual(card.number, "3456 12345")

        card.number = "4242"

        XCTAssertEqual(card.number, "4242 ")

        card.number = "4242 4"

        XCTAssertEqual(card.number, "4242 4")

        card.number = "4242 4242"

        XCTAssertEqual(card.number, "4242 4242 ")

        card.number = "4242 4242 424"

        XCTAssertEqual(card.number, "4242 4242 424")

        card.number = "4242 4242 4242"

        XCTAssertEqual(card.number, "4242 4242 4242 ")

        card.number = "4242 4242 4242"

        XCTAssertEqual(card.number, "4242 4242 424")
    }
    
    func testCodingAddress() {
        let address = Address()
        address.city = "Test Town"
        address.country = "USA"
        address.region = "OH"
        address.line1 = "12 Test Street"
        address.line2 = "Apt 2"
        address.postalCode = "45212"

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()


        let data = try? encoder.encode(address)
        let decodedAddress = try? decoder.decode(Address.self, from: data!)

        XCTAssertEqual(address, decodedAddress)

        let address2 = Address()

        let data2 = try? encoder.encode(address2)
        let decodedAddress2 = try? decoder.decode(Address.self, from: data2!)

        XCTAssertEqual(address2, decodedAddress2)

        XCTAssertNotEqual(address2, decodedAddress)
    }

    func testDidSetRegion() {
        let address = Address()
        address.region = "TEST"

        XCTAssertEqual(address.region, nil)

        address.region = "OH"

        XCTAssertEqual(address.region, "OH")
    }

    func testDidSetPostalCode() {
        let address = Address()
        address.postalCode = "TEST"

        XCTAssertEqual(address.region, nil)

        address.postalCode = "12345"

        XCTAssertEqual(address.postalCode, "12345")
    }

    func testCodingBuyer() {
        let address = Address()
        address.city = "Test Town"
        address.country = "USA"
        address.region = "OH"
        address.line1 = "12 Test Street"
        address.line2 = "Apt 2"
        address.postalCode = "45212"

        let buyer = Payor()
        buyer.firstName = "Test"
        buyer.lastName = "Buyer"
        buyer.email = "test"
        buyer.phone = "5555555555"
        buyer.personalAddress = address

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try? encoder.encode(buyer)
        let decodedBuyer = try? decoder.decode(Payor.self, from: data!)

        XCTAssertEqual(buyer, decodedBuyer)

        let buyer2 = Payor()

        let data2 = try? encoder.encode(buyer2)
        let decodedBuyer2 = try? decoder.decode(Payor.self, from: data2!)

        XCTAssertEqual(buyer2, decodedBuyer2)

        XCTAssertNotEqual(buyer2, buyer)
    }

    func testClearBuyer() {
        let firstName = "Test"
        let lastName = "Person"
        let email = "test@test.com"
        let phone = "5555555555"
        let buyer = Payor()
        buyer.firstName = firstName
        buyer.lastName = lastName
        buyer.email = email
        buyer.phone = phone

        let buyer2 = Payor()

        XCTAssertNotEqual(buyer, buyer2)

        buyer.clear()

        XCTAssertEqual(buyer, buyer2)

    }

    func testFailureResponseInit() {
        let fail = FailureResponse(type: "Failure", receiptNumber: "12334", lastFour: "1234", brand: "VISA")
        let fail2 = FailureResponse(type: "Failure", receiptNumber: "12334", lastFour: "1234", brand: "VISA")

        XCTAssertEqual(fail, fail2)

        let fail3 = FailureResponse(type: "Test")

        XCTAssertNotEqual(fail, fail3)
    }
    

}
