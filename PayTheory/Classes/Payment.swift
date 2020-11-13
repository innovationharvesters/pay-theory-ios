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

//    func substring(fromIndex: Int) -> String {
//        return self[min(fromIndex, length) ..< length]
//    }
//
//    func substring(toIndex: Int) -> String {
//        return self[0 ..< max(0, toIndex)]
//    }

    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}

public class PaymentCard: ObservableObject, Codable, Equatable {
    public static func == (lhs: PaymentCard, rhs: PaymentCard) -> Bool {
        if lhs.name == rhs.name &&
        lhs.expiration_month == rhs.expiration_month &&
        lhs.expiration_year == rhs.expiration_year &&
        lhs.identity == rhs.identity &&
        lhs.address == rhs.address &&
        lhs.number == rhs.number &&
        lhs.type == rhs.type &&
            lhs.security_code == rhs.security_code {
            return true
        }
        
        return false
    }
    
    @Published public var name: String?
    @Published public var expiration_month = ""
    @Published public var expiration_year = ""
    @Published public var identity = ""
    @Published public var address = Address()
    @Published public var number = ""
    private var type = "PAYMENT_CARD"
    @Published public var security_code: String?
    
    enum CodingKeys: CodingKey {
        case name, expiration_month, expiration_year, identity, address, number, type, security_code
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(expiration_year, forKey: .expiration_year)
        try container.encode(expiration_month, forKey: .expiration_month)
        try container.encode(identity, forKey: .identity)
        try container.encode(address, forKey: .address)
        try container.encode(number, forKey: .number)
        try container.encode(type, forKey: .type)
        try container.encode(security_code, forKey: .security_code)
    }
    
    public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            name = try container.decodeIfPresent(String.self, forKey: .name) ?? nil
            address = try container.decode(Address.self, forKey: .address)
            security_code = try container.decodeIfPresent(String.self, forKey: .security_code) ?? nil
            expiration_month = try container.decode(String.self, forKey: .expiration_month)
            expiration_year = try container.decode(String.self, forKey: .expiration_year)
            identity = try container.decode(String.self, forKey: .identity)
            number = try container.decode(String.self, forKey: .number)
            type = try container.decode(String.self, forKey: .type)
    }
    
    var validCardNumber: Bool {
        if (number.count < 13 || number.count > 19){
            return false
        }
        
        var sum = 0
        let digitStrings = number.reversed().map { String($0) }

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
    
    public var isValid: Bool {
        if validExpirationDate == false || validCardNumber == false {
            return false
        }
        return true
    }
    
    public init() {
    }
    
    public init(number: String, expiration_year: String, expiration_month: String, cvv: String) {
        self.number = number
        self.expiration_year = expiration_year
        self.expiration_month = expiration_month
        self.security_code = cvv
    }
    
}

class PaymentCardResponse: Codable {
    var id: String
    var application: String
    var expiration_month: Int
    var expiration_year: Int
    var bin: String
    var address: Address
    var card_type: String
    var last_four: String
    var currency: String
    var identity: String
    var instrument_type: String
    var type: String
    var updated_at: String
    var name: String?
    var brand: String
}

public class BankAccount: ObservableObject, Codable, Equatable {
    public static func == (lhs: BankAccount, rhs: BankAccount) -> Bool {
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
    
    @Published public var name = ""
    @Published public var account_number = ""
    @Published public var account_type = "CHECKING"
    @Published public var bank_code = ""
    @Published public var country: String?
    @Published public var identity = ""
    private var type = "BANK_ACCOUNT"
    
    enum CodingKeys: CodingKey {
        case name, account_number, account_type, bank_code, country, identity, type
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(account_number, forKey: .account_number)
        try container.encode(account_type, forKey: .account_type)
        try container.encode(identity, forKey: .identity)
        try container.encode(bank_code, forKey: .bank_code)
        try container.encode(country, forKey: .country)
        try container.encode(type, forKey: .type)
    }
    
    public required init(from decoder: Decoder) throws {
           let container = try decoder.container(keyedBy: CodingKeys.self)

           name = try container.decode(String.self, forKey: .name)
           account_number = try container.decode(String.self, forKey: .account_number)
           account_type = try container.decode(String.self, forKey: .account_type)
           bank_code = try container.decode(String.self, forKey: .bank_code)
           country = try container.decodeIfPresent(String.self, forKey: .country) ?? nil
           identity = try container.decode(String.self, forKey: .identity)
           type = try container.decode(String.self, forKey: .type)
    }
    
    
    public var validAccountType: Bool {
        if account_type == "CHECKING" || account_type == "SAVINGS" {
            return true
        }
        
        return false
    }
    
    public var validBankCode: Bool {
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
    
    public var isValid: Bool {
        if account_number.isEmpty || validBankCode == false || identity.isEmpty || name.isEmpty || validAccountType == false {
            return false
        }
        return true
    }
    
    
    public init(identity: String) {
        self.identity = identity
    }
    
    public init(name: String, account_number: String, account_type: String, bank_code: String ) {
        self.name = name
        self.account_type = account_type
        self.account_number = account_number
        self.bank_code = bank_code
    }
    
}

class BankAccountResponse: Codable {
    var id: String
    var application: String
    var bank_code: String
    var country: String?
    var masked_account_number: String
    var account_type: String
    var instrument_type: String
    var type: String
    var updated_at: String
    var name: String
    var currency: String
    var identity: String
}
