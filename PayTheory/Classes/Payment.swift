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

    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }

    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }

    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}

public class PaymentCard: ObservableObject, Encodable {
    @Published var name: String?
    @Published var expiration_month = ""
    @Published var expiration_year = ""
    @Published var identity = ""
    @Published var address = Address()
    @Published private var number = ""
    private var type = "PAYMENT_CARD"
    @Published var security_code: String?
    
    enum CodingKeys: CodingKey {
        case name, expiration_month, expiration_year, identity, address, number, type, security_code
    }
    
    func setCardNumber(number: String) {
        self.number = number
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
    
    public var validCardNumber: Bool {
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
    
    public var hasRequiredFields: Bool {
        if validExpirationDate == false || validCardNumber == false {
            return false
        }
        return true
    }
    
    init(identity: String) {
        self.identity = identity
    }
    
    public init(number: String, expiration_year: String, expiration_month: String, cvv: String) {
        self.number = number
        self.expiration_year = expiration_year
        self.expiration_month = expiration_month
        self.security_code = cvv
    }
    
}

public class PaymentCardResponse: Codable {
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

public class BankAccount: ObservableObject, Encodable {
    @Published var name = ""
    @Published private var account_number = ""
    @Published var account_type = "CHECKING"
    @Published private var bank_code = ""
    @Published var country: String?
    @Published var identity = ""
    private var type = "BANK_ACCOUNT"
    
    func setAccountNumber(account_number: String) {
        self.account_number = account_number
    }
    
    func setBankCode(bank_code: String) {
        self.bank_code = bank_code
    }
    
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
    
    var validAccountType: Bool {
        if account_type == "CHECKING" || account_type == "SAVINGS" {
            return true
        }
        
        return false
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
    
    var hasRequiredFields: Bool {
        if account_number.isEmpty || validBankCode == false || identity.isEmpty || name.isEmpty || validAccountType == false {
            return false
        }
        return true
    }
    init(identity: String) {
        self.identity = identity
    }
    
}

public class BankAccountResponse: Codable {
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
