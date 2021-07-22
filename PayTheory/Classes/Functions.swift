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
            let EMAIL_REGEX = "(?:[\\p{L}0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[\\p{L}0-9!#$%\\&'*+/=?\\^_`{|}" +
                "~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\" +
                "x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[\\p{L}0-9](?:[a-" +
                "z0-9-]*[\\p{L}0-9])?\\.)+[\\p{L}0-9](?:[\\p{L}0-9-]*[\\p{L}0-9])?|\\[(?:(?:25[0-5" +
                "]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-" +
                "9][0-9]?|[\\p{L}0-9-]*[\\p{L}0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21" +
                "-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
            let emailTest = NSPredicate(format:"SELF MATCHES %@", EMAIL_REGEX)
            let result = emailTest.evaluate(with: value)
            return result
        }

func isValidPhone(value: String) -> Bool {
            let PHONE_REGEX = "^(\\+\\d{1,2}\\s)?\\(?\\d{3}\\)?[\\s.-]?\\d{3}[\\s.-]?\\d{4}$"
            let phoneTest = NSPredicate(format: "SELF MATCHES %@", PHONE_REGEX)
            let result = phoneTest.evaluate(with: value)
            return result
        }


func isValidExpDate(month: String, year: String) -> Bool {
    if year.count != 4 {
        return false
    }

    let currentDate = Date()
    let calendar = Calendar.current
    let currentYear = calendar.component(.year, from: currentDate)

    if let monthed = Int(month) {
        if monthed <= 0 || monthed > 12 {
            return false
        }
    } else {
        return false
    }

    if let yeared = Int(year) {
        if yeared < currentYear {
            return false
        }
    } else {
        return false
    }

    return true
}

func isValidCardNumber(cardString: String) -> Bool {
    let noSpaces = String(cardString.filter { !" \n\t\r".contains($0) })
    if noSpaces.count < 13 {
        return false
    }
    
    var sum = 0
    let digitStrings = noSpaces.reversed().map { String($0) }

    for tuple in digitStrings.enumerated() {
        if let digit = Int(tuple.element) {
            let odd = tuple.offset % 2 == 1

            switch (odd, digit) {
            case (true, 9):
                sum += 9
            case (true, 0...8):
                sum += (digit * 2) % 9
            default:
                sum += digit
            }
        } else {
            return false
        }
    }
    return sum % 10 == 0
}
