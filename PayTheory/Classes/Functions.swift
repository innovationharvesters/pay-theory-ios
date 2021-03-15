//
//  Functions.swift
//  PayTheory
//
//  Created by Austin Zani on 3/15/21.
//

import Foundation

func paymentCardToDictionary(card: PaymentCard) -> [String: Any] {
    var result: [String: Any] = [:]
    
    if let name = card.name {
        result["name"] = name
    }
    result["address"] = addressToDictionary(address: card.address)
    result["security_code"] = card.securityCode
    result["expiration_month"] = card.expirationMonth
    result["expiration_year"] = card.expirationYear
    result["number"] = card.spacelessCard
    result["type"] = "PAYMENT_CARD"
    
    return result
}

func bankAccountToDictionary(account: BankAccount) -> [String: Any] {
    var result: [String: Any] = [:]
    let types = ["CHECKING", "SAVINGS"]
    
    result["name"] = account.name
    result["account_number"] = account.accountNumber
    result["account_type"] = types[account.accountType]
    result["bank_code"] = account.bankCode
    result["type"] = "BANK_ACCOUNT"
    
    return result
}

func buyerToDictionary(buyer: Buyer) -> [String: Any] {
    var result: [String: Any] = [:]
    
    if let phone = buyer.phone {
        result["phone"] = phone
    }
    if let firstName = buyer.firstName {
        result["first_name"] = firstName
    }
    if let lastName = buyer.lastName {
        result["last_name"] = lastName
    }
    if let email = buyer.email {
        result["email"] = email
    }
    
    result["personal_address"] = addressToDictionary(address: buyer.personalAddress)
    
    return result
}

func addressToDictionary(address: Address) -> [String: String] {
    var result: [String: String] = [:]
    
    if let city = address.city {
        result["city"] = city
    }
    if let country = address.country {
        result["country"] = country
    }
    if let region = address.region {
        result["region"] = region
    }
    if let line1 = address.line1 {
        result["line1"] = line1
    }
    if let line2 = address.line2 {
        result["line2"] = line2
    }
    if let postalCode = address.postalCode {
        result["postal_code"] = postalCode
    }
    
    return result
}

func convertStringToDictionary(text: String) -> [String: AnyObject]? {
    if let data = text.data(using: .utf8) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: AnyObject]
            return json
        } catch {
            print("Something went wrong")
        }
    }
    return nil
}
