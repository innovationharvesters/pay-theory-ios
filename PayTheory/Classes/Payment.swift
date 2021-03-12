//
//  PayTheory.swift
//  PayTheory
//
//  Created by Austin Zani on 11/3/20.
//

import Foundation

extension String {

    var length: Int {
        return count
    }

    subscript (int: Int) -> String {
        return self[int ..< int + 1]
    }

    subscript (section: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, section.lowerBound)),
                                            upper: min(length, max(0, section.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}

class PaymentCard: ObservableObject, Codable, Equatable {
    static func == (lhs: PaymentCard, rhs: PaymentCard) -> Bool {
        if lhs.name == rhs.name &&
        lhs.expirationDate == rhs.expirationDate &&
        lhs.identity == rhs.identity &&
        lhs.address == rhs.address &&
        lhs.number == rhs.number &&
        lhs.type == rhs.type &&
            lhs.securityCode == rhs.securityCode {
            return true
        }
        
        return false
    }
    
    @Published var name: String?
    @Published var expirationDate = ""{
        didSet {
            if let month = Int(self.expirationDate) {
                if self.expirationDate.count == 1 && month > 1 {
                    expirationDate = "0" + expirationDate + " / "
                }
                if self.expirationDate.count == 2 && month > 12 {
                    expirationDate = "0" + String(expirationDate.prefix(1)) + " / " + String(expirationDate.suffix(1))
                }
            }
            if self.expirationDate.count == 2 {
                expirationDate = expirationDate + " / "
            }
            if self.expirationDate.count == 4 {
                expirationDate = String(expirationDate.prefix(1))
            }
            if self.expirationDate.count > 9 {
                expirationDate = oldValue
            }
        }
    }
    @Published var identity = ""
    @Published var address = Address()
    @Published var number = ""{
        didSet {
            if (self.number.prefix(2) == "34" || self.number.prefix(2) == "37") &&
                (self.number.count == 4 || self.number.count == 11) {
                if (oldValue.last == " ") {
                    number.remove(at: oldValue.index(before: number.endIndex))
                } else {
                    number = number + " "
                }
            } else if (self.number.prefix(2) != "34" && self.number.prefix(2) != "37") &&
                        (self.number.count == 4 || self.number.count == 9 ||
                            self.number.count == 14 || self.number.count == 19) {
                if (oldValue.last == " ") {
                    number.remove(at: oldValue.index(before: number.endIndex))
                } else {
                    number = number + " "
                }
            }
            if self.number.count > 23 ||
                ((self.number.prefix(2) == "34" || self.number.prefix(2) == "37") &&
                    self.number.count == 18) {
                number = oldValue
            }
        }
    }
    private var type = "PAYMENT_CARD"
    @Published var securityCode = ""{
        didSet {
            let filtered = securityCode.filter { $0.isNumber }
            
            if securityCode != filtered {
                securityCode = filtered
            }
        }
    }
    
    enum CodingKeys: CodingKey {
        case name, expirationDate, identity, address, number, type, securityCode
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(expirationDate, forKey: .expirationDate)
        try container.encode(identity, forKey: .identity)
        try container.encode(address, forKey: .address)
        try container.encode(number, forKey: .number)
        try container.encode(type, forKey: .type)
        try container.encode(securityCode, forKey: .securityCode)
    }
    
    required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            name = try container.decodeIfPresent(String.self, forKey: .name) ?? nil
            address = try container.decode(Address.self, forKey: .address)
            securityCode = try container.decode(String.self, forKey: .securityCode)
            expirationDate = try container.decode(String.self, forKey: .expirationDate)
            identity = try container.decode(String.self, forKey: .identity)
            number = try container.decode(String.self, forKey: .number)
            type = try container.decode(String.self, forKey: .type)
    }
    
    var expirationMonth: String {
        return String(expirationDate.prefix(2))
    }

    var expirationYear: String {
        var result = ""
        if expirationDate.count == 7 {
            result = "20" + String(expirationDate.suffix(2))
        } else if expirationDate.count == 9 {
            result = String(expirationDate.suffix(4))
        }
        return result
    }
    
    var validCardNumber: Bool {
        if spacelessCard.count < 13 {
            return false
        }
        
        var sum = 0
        let digitStrings = spacelessCard.reversed().map { String($0) }

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
    
    var firstSix: String {
        return String(spacelessCard.prefix(6))
    }
    
    var lastFour: String {
        return String(spacelessCard.suffix(4))
    }
    
    var spacelessCard: String {
        return String(number.filter { !" \n\t\r".contains($0) })
    }
    
    var brand: String {
        let visa = "^4"
        let mastercard = "^5[1-5][0-9]{5,}|222[1-9][0-9]{3,}|22[3-9][0-9]{4,}|2[3-6][0-9]{5,}|27[01][0-9]{4,}|2720[0-9]{3,}$/"
        let amex = "^3[47][0-9]{5,}$"
        let discover = "^6(?:011|5[0-9]{2})[0-9]{3,}$"
        let jcb = "^35"
        let dinersClub = "^3(?:0[0-5]|[68][0-9])[0-9]{4,}$"
        
        let first7 = String(spacelessCard.prefix(7))
        
        if first7.range(of: visa, options: .regularExpression, range: nil, locale: nil) != nil {
            return "Visa"
        } else if first7.range(of: mastercard, options: .regularExpression, range: nil, locale: nil) != nil {
            return "MasterCard"
        } else  if first7.range(of: amex, options: .regularExpression, range: nil, locale: nil) != nil {
            return "American Express"
        } else if first7.range(of: discover, options: .regularExpression, range: nil, locale: nil) != nil {
            return "Discover"
        } else if first7.range(of: jcb, options: .regularExpression, range: nil, locale: nil) != nil {
            return "JCB"
        } else if first7.range(of: dinersClub, options: .regularExpression, range: nil, locale: nil) != nil {
            return "Diners Club"
        }
        
        return ""
    }
    
    var validExpirationDate: Bool {
        if expirationYear.count != 4 {
            return false
        }
        
        let currentDate = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: currentDate)
        
        if let month = Int(expirationMonth) {
            if month <= 0 || month > 12 {
                return false
            }
        } else {
            return false
        }
        
        if let year = Int(expirationYear) {
            if year < currentYear {
                return false
            }
        } else {
            return false
        }
        
        return true
    }
    
    var validSecurityCode: Bool {
        let num = Int(securityCode)
        return num != nil && securityCode.length > 2 && securityCode.length < 5
    }
    
    var isValid: Bool {
        if validExpirationDate == false || validCardNumber == false || validSecurityCode == false {
            return false
        }
        return true
    }
    
    init() {
    }
    
    init(number: String, expirationDate: String, cvv: String) {
        self.number = number
        self.expirationDate = expirationDate
        self.securityCode = cvv
    }
    
    func clear() {
        self.number = ""
        self.expirationDate = ""
        self.securityCode = ""
        self.address = Address()
        self.identity = ""
        self.name = nil
    }
    
}

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

class BankAccount: ObservableObject, Codable, Equatable {
    static func == (lhs: BankAccount, rhs: BankAccount) -> Bool {
        if lhs.name == rhs.name &&
        lhs.accountNumber == rhs.accountNumber &&
        lhs.accountType == rhs.accountType &&
        lhs.bankCode == rhs.bankCode &&
        lhs.country == rhs.country &&
        lhs.identity == rhs.identity &&
            lhs.type == rhs.type {
            return true
        }
        
        return false
    }
    
    @Published var name = ""
    @Published var accountNumber = ""
    @Published var accountType = 0
    @Published var bankCode = ""
    @Published var country: String?
    @Published var identity = ""
    private var type = "BANK_ACCOUNT"
    
    enum CodingKeys: CodingKey {
        case name, accountNumber, accountType, bankCode, country, identity, type
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(accountNumber, forKey: .accountNumber)
        try container.encode(accountType, forKey: .accountType)
        try container.encode(identity, forKey: .identity)
        try container.encode(bankCode, forKey: .bankCode)
        try container.encode(country, forKey: .country)
        try container.encode(type, forKey: .type)
    }
    
    required init(from decoder: Decoder) throws {
           let container = try decoder.container(keyedBy: CodingKeys.self)

           name = try container.decode(String.self, forKey: .name)
           accountNumber = try container.decode(String.self, forKey: .accountNumber)
           accountType = try container.decode(Int.self, forKey: .accountType)
           bankCode = try container.decode(String.self, forKey: .bankCode)
           country = try container.decodeIfPresent(String.self, forKey: .country) ?? nil
           identity = try container.decode(String.self, forKey: .identity)
           type = try container.decode(String.self, forKey: .type)
    }
    
    var validAccountType: Bool {
        return accountType < 2
    }
    
    var validBankCode: Bool {
        if bankCode.count != 9 {
            return false
        }
        
        var n = 0
        for num in stride(from: 0, to: bankCode.count, by: 3) {
            if let first = Int(bankCode[num]) {
                n += (first * 3)
            } else {
                return false
            }
            
            if let second = Int(bankCode[num + 1]) {
                n += (second * 7)
            } else {
                return false
            }
            
            if let third = Int(bankCode[num + 2]) {
                n += (third * 1)
            } else {
                return false
            }
        }
        
        return n > 0 && n % 10 == 0
    }
    
    var validAccountNumber: Bool {
        let num = Int(accountNumber)
        return num != nil && accountNumber.isEmpty == false
    }
    
    var isValid: Bool {
        if validAccountNumber == false || validBankCode == false || name.isEmpty || validAccountType == false {
            return false
        }
        return true
    }
    
    var lastFour: String {
        return String(accountNumber.suffix(4))
    }
    
    
    init(identity: String) {
        self.identity = identity
    }
    
    init(name: String, accountNumber: String, accountType: Int, bankCode: String ) {
        self.name = name
        self.accountType = accountType
        self.accountNumber = accountNumber
        self.bankCode = bankCode
    }
    
    init() {
    }
    
    func clear() {
        self.name = ""
        self.accountType = 0
        self.accountNumber = ""
        self.bankCode = ""
    }
    
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


