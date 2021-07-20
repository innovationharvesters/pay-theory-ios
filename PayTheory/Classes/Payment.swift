//
//  PayTheory.swift
//  PayTheory
//
//  Created by Austin Zani on 11/3/20.
//

import Foundation
import Combine

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

class PaymentCard: ObservableObject, Equatable {
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
                expirationDate += " / "
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
                if oldValue.last == " " {
                    number.remove(at: oldValue.index(before: number.endIndex))
                } else {
                    number += " "
                }
            } else if (self.number.prefix(2) != "34" && self.number.prefix(2) != "37") &&
                        (self.number.count == 4 || self.number.count == 9 ||
                            self.number.count == 14 || self.number.count == 19) {
                if oldValue.last == " " {
                    number.remove(at: oldValue.index(before: number.endIndex))
                } else {
                    number += " "
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
            if self.securityCode.count > 4 {
                securityCode = oldValue
            } else if securityCode != filtered {
                securityCode = filtered
            }
        }
    }
    
    @Published var isValid: Bool = false
    private var isValidCancellable: AnyCancellable!
    
    @Published var expirationMonth: String = ""
    private var expirationMonthCancellable: AnyCancellable!
    
    @Published var expirationYear: String = ""
    private var expirationYearCancellable: AnyCancellable!
    
    var expirationMonthPublisher: AnyPublisher<String,Never> {
        return $expirationDate
            .map { data in
               return String(data.prefix(2))
            }
            .eraseToAnyPublisher()
    }

    var expirationYearPublisher: AnyPublisher<String,Never> {
        return $expirationDate
            .map { data in
                var result = ""
                if data.count == 7 {
                    result = "20" + String(data.suffix(2))
                } else if data.count == 9 {
                    result = String(data.suffix(4))
                }
                return result
            }
            .eraseToAnyPublisher()
    }
    
    var validCardNumber: AnyPublisher<Bool,Never> {
        return $number
            .map { data in
                let noSpaces = String(data.filter { !" \n\t\r".contains($0) })
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
            .eraseToAnyPublisher()
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
        let mastercard = """
                        ^5[1-5][0-9]{5,}|222[1-9][0-9]{3,}|22[3-9]
                        [0-9]{4,}|2[3-6][0-9]{5,}|27[01][0-9]{4,}|2720[0-9]{3,}$/
                        """
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
    
    var validExpirationDate: AnyPublisher<Bool,Never> {
        return Publishers.CombineLatest(expirationYearPublisher, expirationMonthPublisher)
            .map { year, month in
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
            .eraseToAnyPublisher()
    }
    
    var validSecurityCode: AnyPublisher<Bool,Never> {
        return $securityCode
            .map { input in
                let num = Int(input)
                return num != nil && input.length > 2 && input.length < 5
              }
            .eraseToAnyPublisher()
    }
    
    var isValidPublisher: AnyPublisher<Bool,Never> {
        return Publishers.CombineLatest3(validCardNumber, validSecurityCode, validExpirationDate)
            .map { validNumber, validCode, validDate in
                if validNumber == false || validCode == false || validDate == false {
                    return false
                }
                return true
            }
            .eraseToAnyPublisher()
    }
    
    init() {
        isValidCancellable = isValidPublisher.sink { valid in
            self.isValid = valid
                }
        expirationMonthCancellable = expirationMonthPublisher.sink { month in
            self.expirationMonth = month
        }
        
        expirationYearCancellable = expirationYearPublisher.sink { year in
            self.expirationYear = year
        }
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

class BankAccount: ObservableObject, Equatable {
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
    @Published var isValid: Bool = false
    private var isValidCancellable: AnyCancellable!
    private var type = "BANK_ACCOUNT"
    
    var validBankCode: AnyPublisher<Bool,Never> {
        return $bankCode
            .map { code in
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
            .eraseToAnyPublisher()
    }
    
    var validAccountNumber: AnyPublisher<Bool,Never> {
        return $accountNumber
            .map { number in
                let num = Int(number)
                return num != nil && number.isEmpty == false
            }
            .eraseToAnyPublisher()
    }
    
    var isValidPublisher: AnyPublisher<Bool,Never> {
        return Publishers.CombineLatest4($name, $accountType, validBankCode, validAccountNumber)
            .map { name, type, validCode, validNumber in
                if validCode == false || validNumber == false || name.isEmpty || type > 1 {
                    return false
                }
                return true
            }
            .eraseToAnyPublisher()
    }
    
    var lastFour: String {
        return String(accountNumber.suffix(4))
    }
    
    init() {
        isValidCancellable = isValidPublisher.sink { isValid in
                    self.isValid = isValid
                }
    }
    
    func clear() {
        self.name = ""
        self.accountType = 0
        self.accountNumber = ""
        self.bankCode = ""
    }
    
}


class Cash: ObservableObject {
    @Published var name = ""
    @Published var contact = ""
    @Published var isValid: Bool = false
    private var isValidCancellable: AnyCancellable!
    
    var validName: AnyPublisher<Bool,Never> {
        return $name
            .map { name in
                return name.length > 0
              }
            .eraseToAnyPublisher()
    }
    
    var validContact: AnyPublisher<Bool,Never> {
        return $contact
            .map { contact in
                let validEmail = isValidEmail(value: contact)
                let validPhone = isValidPhone(value: contact)
                return validPhone || validEmail
              }
            .eraseToAnyPublisher()
    }
    
    var isValidPublisher: AnyPublisher<Bool,Never> {
        return Publishers.CombineLatest(validName, validContact)
            .map { name, contact in
                if name == false || contact == false {
                    return false
                }
                return true
            }
            .eraseToAnyPublisher()
    }
    
    init() {
        isValidCancellable = isValidPublisher.sink { isValid in
                    self.isValid = isValid
                }
    }
    
    func clear() {
        self.name = ""
        self.contact = ""
    }
}
