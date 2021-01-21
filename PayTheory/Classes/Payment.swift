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

    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }

    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}

class PaymentCard: ObservableObject, Codable, Equatable {
    static func == (lhs: PaymentCard, rhs: PaymentCard) -> Bool {
        if lhs.name == rhs.name &&
        lhs.expiration_date == rhs.expiration_date &&
        lhs.identity == rhs.identity &&
        lhs.address == rhs.address &&
        lhs.number == rhs.number &&
        lhs.type == rhs.type &&
            lhs.security_code == rhs.security_code {
            return true
        }
        
        return false
    }
    
    @Published var name: String?
    @Published var expiration_date = ""{
        didSet {
            if let month = Int(self.expiration_date) {
                if (self.expiration_date.count == 1 && month > 1){
                    expiration_date = "0" + expiration_date + " / "
                }
                if (self.expiration_date.count == 2 && month > 12) {
                    expiration_date = "0" + String(expiration_date.prefix(1)) + " / " + String(expiration_date.suffix(1))
                }
            }
            if (self.expiration_date.count == 2) {
                expiration_date = expiration_date + " / "
            }
            if (self.expiration_date.count == 4) {
                expiration_date = String(expiration_date.prefix(1))
            }
            if (self.expiration_date.count > 9){
                expiration_date = oldValue
            }
        }
    }
    @Published var identity = ""
    @Published var address = Address()
    @Published var number = ""{
        didSet {
            if ((self.number.prefix(2) == "34" || self.number.prefix(2) == "37") && (self.number.count == 4 || self.number.count == 11)) {
                if (oldValue.last == " ") {
                    number.remove(at: oldValue.index(before: number.endIndex))
                } else {
                    number = number + " "
                }
            } else if ((self.number.prefix(2) != "34" && self.number.prefix(2) != "37") && (self.number.count == 4 || self.number.count == 9 || self.number.count == 14 || self.number.count == 19)) {
                if (oldValue.last == " ") {
                    number.remove(at: oldValue.index(before: number.endIndex))
                } else {
                    number = number + " "
                }
            }
            if (self.number.count > 23 || ((self.number.prefix(2) == "34" || self.number.prefix(2) == "37") && self.number.count == 18)) {
                number = oldValue
            }
        }
    }
    private var type = "PAYMENT_CARD"
    @Published var security_code = ""{
        didSet {
            let filtered = security_code.filter { $0.isNumber }
            
            if security_code != filtered {
                security_code = filtered
            }
        }
    }
    
    enum CodingKeys: CodingKey {
        case name, expiration_date, identity, address, number, type, security_code
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(expiration_date, forKey: .expiration_date)
        try container.encode(identity, forKey: .identity)
        try container.encode(address, forKey: .address)
        try container.encode(number, forKey: .number)
        try container.encode(type, forKey: .type)
        try container.encode(security_code, forKey: .security_code)
    }
    
    required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            name = try container.decodeIfPresent(String.self, forKey: .name) ?? nil
            address = try container.decode(Address.self, forKey: .address)
            security_code = try container.decode(String.self, forKey: .security_code)
            expiration_date = try container.decode(String.self, forKey: .expiration_date)
            identity = try container.decode(String.self, forKey: .identity)
            number = try container.decode(String.self, forKey: .number)
            type = try container.decode(String.self, forKey: .type)
    }
    
    var expiration_month: String {
        return String(expiration_date.prefix(2))
    }

    var expiration_year: String {
        var result = ""
        if expiration_date.count == 7 {
            result = "20" + String(expiration_date.suffix(2))
        } else if expiration_date.count == 9 {
            result = String(expiration_date.suffix(4))
        }
        return result
    }
    
    var validCardNumber: Bool {
        if (spacelessCard.count < 13 || spacelessCard.count > 19){
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
    
    var first_six: String {
        return String(spacelessCard.prefix(6))
    }
    
    var last_four: String {
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
        } else {
            return ""
        }
    }
    
    var validExpirationDate: Bool {
        if expiration_year.count != 4 {
            return false
        }
        
        let currentDate = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: currentDate)
        
        if let month = Int(expiration_month) {
            if month <= 0 || month > 12 {
                return false
            }
        } else {
            return false
        }
        
        if let year = Int(expiration_year) {
            if year < currentYear {
                return false
            }
        } else {
            return false
        }
        
        return true
    }
    
    var validSecurityCode: Bool {
        let num = Int(security_code)
        return num != nil && security_code.length > 2 && security_code.length < 5
    }
    
    var isValid: Bool {
        if validExpirationDate == false || validCardNumber == false || validSecurityCode == false {
            return false
        }
        return true
    }
    
    init() {
    }
    
    init(number: String, expiration_date: String, cvv: String) {
        self.number = number
        self.expiration_date = expiration_date
        self.security_code = cvv
    }
    
    func clear() {
        self.number = ""
        self.expiration_date = ""
        self.security_code = ""
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
    result["security_code"] = card.security_code
    result["expiration_month"] = card.expiration_month
    result["expiration_year"] = card.expiration_year
    result["number"] = card.spacelessCard
    result["type"] = "PAYMENT_CARD"
    
    return result
}

class BankAccount: ObservableObject, Codable, Equatable {
    static func == (lhs: BankAccount, rhs: BankAccount) -> Bool {
        if lhs.name == rhs.name &&
        lhs.account_number == rhs.account_number &&
        lhs.account_type == rhs.account_type &&
        lhs.bank_code == rhs.bank_code &&
        lhs.country == rhs.country &&
        lhs.identity == rhs.identity &&
            lhs.type == rhs.type {
            return true
        }
        
        return false
    }
    
    @Published var name = ""
    @Published var account_number = ""
    @Published var account_type = 0
    @Published var bank_code = ""
    @Published var country: String?
    @Published var identity = ""
    private var type = "BANK_ACCOUNT"
    
    enum CodingKeys: CodingKey {
        case name, account_number, account_type, bank_code, country, identity, type
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(account_number, forKey: .account_number)
        try container.encode(account_type, forKey: .account_type)
        try container.encode(identity, forKey: .identity)
        try container.encode(bank_code, forKey: .bank_code)
        try container.encode(country, forKey: .country)
        try container.encode(type, forKey: .type)
    }
    
    required init(from decoder: Decoder) throws {
           let container = try decoder.container(keyedBy: CodingKeys.self)

           name = try container.decode(String.self, forKey: .name)
           account_number = try container.decode(String.self, forKey: .account_number)
           account_type = try container.decode(Int.self, forKey: .account_type)
           bank_code = try container.decode(String.self, forKey: .bank_code)
           country = try container.decodeIfPresent(String.self, forKey: .country) ?? nil
           identity = try container.decode(String.self, forKey: .identity)
           type = try container.decode(String.self, forKey: .type)
    }
    
    
    var validAccountType: Bool {
        return account_type < 2
    }
    
    var validBankCode: Bool {
        if bank_code.count != 9 {
            return false
        }
        
        var n = 0
        for num in stride(from: 0, to: bank_code.count, by: 3){
            if let first = Int(bank_code[num]) {
                n += (first * 3)
            } else {
                return false
            }
            
            if let second = Int(bank_code[num + 1]) {
                n += (second * 7)
            } else {
                return false
            }
            
            if let third = Int(bank_code[num + 2]) {
                n += (third * 1)
            } else {
                return false
            }
        }
        
        return n > 0 && n % 10 == 0
    }
    
    var validAccountNumber: Bool {
        let num = Int(account_number)
        return num != nil && account_number.isEmpty == false
    }
    
    var isValid: Bool {
        if validAccountNumber == false || validBankCode == false || name.isEmpty || validAccountType == false {
            return false
        }
        return true
    }
    
    var last_four: String {
        return String(account_number.suffix(4))
    }
    
    
    init(identity: String) {
        self.identity = identity
    }
    
    init(name: String, account_number: String, account_type: Int, bank_code: String ) {
        self.name = name
        self.account_type = account_type
        self.account_number = account_number
        self.bank_code = bank_code
    }
    
    init() {
    }
    
    func clear() {
        self.name = ""
        self.account_type = 0
        self.account_number = ""
        self.bank_code = ""
    }
    
}

func bankAccountToDictionary(account: BankAccount) -> [String: Any] {
    var result: [String: Any] = [:]
    let types = ["CHECKING", "SAVINGS"]
    
    
    result["name"] = account.name
    result["account_number"] = account.account_number
    result["account_type"] = types[account.account_type]
    result["bank_code"] = account.bank_code
    result["type"] = "BANK_ACCOUNT"
    
    return result
}


