//
//  Functions.swift
//  PayTheory
//
//  Created by Austin Zani on 3/15/21.
//

import Foundation
import Sodium

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

func cashToDictionary(cash: Cash) -> [String: String] {
    return ["buyer" : cash.name, "buyer_contact": cash.contact]
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

func stringify(jsonDictionary: [String: Any]) -> String {
  do {
    let data = try JSONSerialization.data(withJSONObject: jsonDictionary, options: .prettyPrinted)
    return String(data: data, encoding: String.Encoding.utf8) ?? ""
  } catch {
    return ""
  }
}

func convertBytesToString(bytes: Bytes) -> String {
    let data = NSData(bytes: bytes, length: bytes.count)
    let base64Data = data.base64EncodedData(options: NSData.Base64EncodingOptions.endLineWithLineFeed)
    let newData = NSData(base64Encoded: base64Data, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters) ?? NSData()
    return newData.base64EncodedString()
}

func convertStringToByte(string: String) -> Bytes {
    return [UInt8](NSData(base64Encoded: string, options: NSData.Base64DecodingOptions(rawValue: 0)) ?? NSData())
}

func parseError(errors: [String: AnyObject]) -> String {
    var type = ""
    var message = ""
    let field = errors["_embedded"] as? [String: AnyObject]
    let errors = field?["errors"] as? [[String: AnyObject]]
    if let initialType = errors?[0]["field"] {
        type = initialType as? String ?? ""
    }
    if let initialMessage = errors?[0]["message"] {
        message = initialMessage as? String ?? ""
    }
    
    return "\(type) \(message)"
}

func isValidEmail(value: String) -> Bool {
            let EMAIL_REGEX = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailTest = NSPredicate(format:"SELF MATCHES %@", EMAIL_REGEX)
            let result = emailTest.evaluate(with: value)
            return result
        }

func isValidPhone(value: String) -> Bool {
            let PHONE_REGEX = "^\\d{3}-\\d{3}-\\d{4}$"
            let phoneTest = NSPredicate(format: "SELF MATCHES %@", PHONE_REGEX)
            let result = phoneTest.evaluate(with: value)
            return result
        }
