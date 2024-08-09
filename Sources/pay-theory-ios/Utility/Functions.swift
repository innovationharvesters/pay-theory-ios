//
//  Functions.swift
//  PayTheory
//
//  Created by Austin Zani on 3/15/21.
//

import Foundation
import Sodium

public extension Data {
    init?(hexString: String) {
      let len = hexString.count / 2
      var data = Data(capacity: len)
      var index = hexString.startIndex
      for _ in 0..<len {
        let offset = hexString.index(index, offsetBy: 2)
        let bytes = hexString[index..<offset]
        if var num = UInt8(bytes, radix: 16) {
          data.append(&num, count: 1)
        } else {
          return nil
        }
        index = offset
      }
      self = data
    }
    /// Hexadecimal string representation of `Data` object.
    var hexadecimal: String {
        return map { String(format: "%02x", $0) }
            .joined()
    }
}

func paymentCardToDictionary(card: Card) -> [String: Any] {
    var result: [String: Any] = [:]
    
    if let name = card.name {
        result["name"] = name
    }
    result["address"] = addressToDictionary(address: card.address)
    result["security_code"] = card.securityCode
    result["expiration_month"] = card.expirationMonth
    result["expiration_year"] = card.expirationYear
    result["number"] = card.spacelessCard
    result["type"] = "card"
    
    return result
}

func bankAccountToDictionary(account: ACH) -> [String: Any] {
    var result: [String: Any] = [:]
    let types = ["CHECKING", "SAVINGS"]
    
    result["name"] = account.name
    result["account_number"] = account.accountNumber
    result["account_type"] = types[account.accountType]
    result["bank_code"] = account.bankCode
    result["type"] = "ach"
    
    return result
}

func payorToDictionary(payor: Payor) -> [String: Any] {
    var result: [String: Any] = [:]
    
    if let phone = payor.phone {
        result["phone"] = phone
    }
    if let firstName = payor.firstName {
        result["first_name"] = firstName
    }
    if let lastName = payor.lastName {
        result["last_name"] = lastName
    }
    if let email = payor.email {
        result["email"] = email
    }
    
    result["personal_address"] = addressToDictionary(address: payor.personalAddress)
    
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
    return ["payor": cash.name, "payor_contact": cash.contact]
}

func convertStringToDictionary(text: String) -> [String: AnyObject]? {
    if let data = text.data(using: .utf8) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: AnyObject]
            return json
        } catch {
            print("Something went wrong decoding repsonse")
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

func isValidPostalCode(value: String) -> Bool {
    if value == "" {
        return false
    }
    for regex in postalRegexList {
        let zipTest = NSPredicate(format: "SELF MATCHES %@", regex[1])
        let evaluated = zipTest.evaluate(with: value)
        if evaluated {
            return true
        }
    }
    
    return false
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
    let currentMonth = calendar.component(.month, from: currentDate)
    
    if let yeared = Int(year) {
        if yeared < currentYear {
            // Expired because past exp year
            return false
        }
        if let monthed = Int(month) {
            if monthed < currentMonth && yeared == currentYear {
                // Expired because month is previous month this year
                return false
            }
        } else {
            // Could not parse month to Int
            return false
        }
    } else {
        // Could not parse year to Int
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

func isValidRoutingNumber(code: String) -> Bool {
    if code.count != 9 {
        return false
    }
    
    var number = 0
    for num in stride(from: 0, to: code.count, by: 3) {
        if let first = Int(code[num]) {
            number += (first * 3)
        } else {
            return false
        }
        
        if let second = Int(code[num + 1]) {
            number += (second * 7)
        } else {
            return false
        }
        
        if let third = Int(code[num + 2]) {
            number += (third * 1)
        } else {
            return false
        }
    }
    
    return number > 0 && number % 10 == 0
}

func insertCreditCardSpaces(_ string: String) -> String {
        // Mapping of card prefix to pattern is taken from
        // https://baymard.com/checkout-usability/credit-card-patterns

        // UATP cards have 4-5-6 (XXXX-XXXXX-XXXXXX) format
        let is456 = string.hasPrefix("1")

        // These prefixes reliably indicate either a 4-6-5 or 4-6-4 card. We treat all these
        // as 4-6-5-4 to err on the side of always letting the user type more digits.
        let is465 = [
            // Amex
            "34", "37",

            // Diners Club
            "300", "301", "302", "303", "304", "305", "309", "36", "38", "39"
        ].contains { string.hasPrefix($0) }

        // In all other cases, assume 4-4-4-4-3.
        // This won't always be correct; for instance, Maestro has 4-4-5 cards according
        // to https://baymard.com/checkout-usability/credit-card-patterns, but I don't
        // know what prefixes identify particular formats.
        let is4444 = !(is456 || is465)

        var stringWithAddedSpaces = ""

        for index in 0..<string.count {
            let needs465Spacing = (is465 && (index == 4 || index == 10))
            let needs456Spacing = (is456 && (index == 4 || index == 9))
            let needs4444Spacing = (is4444 && index > 0 && (index % 4) == 0 && index < 13)

            if needs465Spacing || needs456Spacing || needs4444Spacing {
                stringWithAddedSpaces.append(" ")
            }

            let characterToAdd = string[string.index(string.startIndex, offsetBy: index)]
            if ((is456 || is465) && index <= 14) || (is4444 && index <= 15) {
                stringWithAddedSpaces.append(characterToAdd)
            }
        }

        return stringWithAddedSpaces
    }

func generateUUID() -> String {
    return UUID().uuidString
}

func formatDigitTextField(_ value: String, maxLength: Int) -> String {
    // Filter out non-numeric characters
    let filtered = value.filter { $0.isNumber }
    
    // Limit to 4 digits
    return String(filtered.prefix(maxLength))
}
