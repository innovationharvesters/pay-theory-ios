//
//  FunctionTests.swift
//  PayTheory_Tests
//
//  Created by Austin Zani on 5/17/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest
@testable import PayTheory

class FunctionTests: XCTestCase {

    func testBankAccountToDictionary() {
        let name = "test"
        let accNumber = "111111111"
        let accountType = 0
        let bankCode = "789456124"
        let bank = BankAccount()
        
        bank.name = name
        bank.accountNumber = accNumber
        bank.accountType = accountType
        bank.bankCode = bankCode

        let result: [String: Any] = bankAccountToDictionary(account: bank)

        XCTAssertEqual(name, result["name"] as? String ?? "")
        XCTAssertEqual(accNumber, result["account_number"] as? String ?? "")
        XCTAssertEqual("CHECKING", result["account_type"] as? String ?? "")
        XCTAssertEqual(bankCode, result["bank_code"] as? String ?? "")
    }
    
    func testCardToDictionary() {
        let name = "test"
        let number = "4242424242424242"
        let exp = "12 / 22"
        let cvv = "222"
        let card = PaymentCard()
        card.name = name
        card.number = number
        card.expirationDate = exp
        card.securityCode = cvv

        let result: [String: Any] = paymentCardToDictionary(card: card)

        XCTAssertEqual(name, result["name"] as? String ?? "")
        XCTAssertEqual(number, result["number"] as? String ?? "")
        XCTAssertEqual("12", result["expiration_month"] as? String ?? "")
        XCTAssertEqual("2022", result["expiration_year"] as? String ?? "")
        XCTAssertEqual(cvv, result["security_code"] as? String ?? "")
    }
    
    func testAddressToDictionary() {
        let city = "Test Town"
        let country = "USA"
        let region = "OH"
        let lineOne = "12 Test Street"
        let lineTwo = "Apt 2"
        let postalCode = "45212"
        let address = Address()
        address.city = city
        address.country = country
        address.region = region
        address.line1 = lineOne
        address.line2 = lineTwo
        address.postalCode = postalCode

        let result: [String: Any] = addressToDictionary(address: address)

        XCTAssertEqual(city, result["city"] as? String ?? "")
        XCTAssertEqual(country, result["country"] as? String ?? "")
        XCTAssertEqual(region, result["region"] as? String ?? "")
        XCTAssertEqual(lineOne, result["line1"] as? String ?? "")
        XCTAssertEqual(lineTwo, result["line2"] as? String ?? "")
        XCTAssertEqual(postalCode, result["postal_code"] as? String ?? "")
    }
    
    func testBuyerToDictionary() {
        let firstName = "Test"
        let lastName = "Person"
        let email = "test@test.com"
        let phone = "5555555555"
        let buyer = Buyer()
        buyer.firstName = firstName
        buyer.lastName = lastName
        buyer.email = email
        buyer.phone = phone

        let result: [String: Any] = buyerToDictionary(buyer: buyer)

        XCTAssertEqual(firstName, result["first_name"] as? String ?? "")
        XCTAssertEqual(lastName, result["last_name"] as? String ?? "")
        XCTAssertEqual(email, result["email"] as? String ?? "")
        XCTAssertEqual(phone, result["phone"] as? String ?? "")
    }
    
    func testStringToDictionary() {
        let key = "Test Key"
        let value = "Test Value"
        let jsonString = """
            {
              "\(key)" : "\(value)"
            }
            """
        let dictionary =  convertStringToDictionary(text: jsonString)
        let newValue = dictionary?[key] as? String ?? ""
        XCTAssertEqual(value, newValue)
    }
    
    func testStringifyDictionary() {
        let jsonString = """
            {
              "Test Key" : "Test Value"
            }
            """
        let dictionary = ["Test Key" : "Test Value"]
        let string = stringify(jsonDictionary: dictionary)
        XCTAssertEqual(string, jsonString)
    }

}
