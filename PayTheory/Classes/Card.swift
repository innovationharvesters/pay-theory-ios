//
//  CardFields.swift
//  PayTheory
//
//  Created by Austin Zani on 3/15/21.
//
import SwiftUI
import Foundation
import Combine

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

    private var type = "PAYMENT_CARD"
    @Published var name: String?
    @Published var identity = ""
    @Published var address = Address()
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
    
    var validCardNumber: AnyPublisher<Bool,Never> {
        return $number
            .map { data in
                return isValidCardNumber(cardString: data)
            }
            .eraseToAnyPublisher()
    }
    
    var publicValidCardNumber: AnyPublisher<Bool,Never> {
        return $number
            .map { data in
                return isValidCardNumber(cardString: data) && data.isEmpty
            }
            .eraseToAnyPublisher()
    }
    
    var validExpirationDate: AnyPublisher<Bool,Never> {
        return Publishers.CombineLatest(expirationYearPublisher, expirationMonthPublisher)
            .map { year, month in
                return isValidExpDate(month: month, year: year)
            }
            .eraseToAnyPublisher()
    }
    
    var publicValidExpirationDate: AnyPublisher<Bool,Never> {
        return Publishers.CombineLatest(expirationYearPublisher, expirationMonthPublisher)
            .map { year, month in
                return isValidExpDate(month: month, year: year) && self.expirationDate.isEmpty
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
    
    var publicValidSecurityCode: AnyPublisher<Bool,Never> {
        return $securityCode
            .map { input in
                let num = Int(input)
                return num != nil && input.length > 2 && input.length < 5 && input.isEmpty
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

/// TextField that can be used to capture the Name for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCardName: View {
    @EnvironmentObject var card: PaymentCard
    public init() {
    }

    public var body: some View {
        TextField("Name on Card", text: $card.name ?? "")
            .autocapitalization(UITextAutocapitalizationType.words)
    }
}

/// TextField that can be used to capture the Card Number for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
///  - Important: This is required to be able to run a transaction.
///
public struct PTCardNumber: View {
    @EnvironmentObject var card: PaymentCard
    public init() {
        
    }
    public var body: some View {
        TextField("Card Number", text: $card.number)
            .keyboardType(.decimalPad)
            
    }
}

/// TextField that can be used to capture the Expiration Year for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
///  - Important: This is required to be able to run a transaction.
///
public struct PTExp: View {
    @EnvironmentObject var card: PaymentCard
    public init() {
        
    }
    public var body: some View {
        TextField("MM / YY", text: $card.expirationDate)
            .keyboardType(.decimalPad)
    }
}

/// TextField that can be used to capture the CVV for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
///  - Important: This is required to be able to run a transaction.
///
public struct PTCvv: View {
    @EnvironmentObject var card: PaymentCard
    public init() {
        
    }
    public var body: some View {
        TextField("CVV", text: $card.securityCode)
            .keyboardType(.decimalPad)
    }
}

/// TextField that can be used to capture the Address Line 1 for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCardLineOne: View {
    @EnvironmentObject var card: PaymentCard
    public init() {
        
    }
    
    public var body: some View {
        TextField("Address Line 1", text: $card.address.line1 ?? "")
            .autocapitalization(UITextAutocapitalizationType.words)
    }
}

/// TextField that can be used to capture the Address Line 2 for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCardLineTwo: View {
    @EnvironmentObject var card: PaymentCard
    public init() {
        
    }
    
    public var body: some View {
        TextField("Address Line 2", text: $card.address.line2 ?? "")
    }
}

/// TextField that can be used to capture the City for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCardCity: View {
    @EnvironmentObject var card: PaymentCard
    public init() {
        
    }
    
    public var body: some View {
        TextField("City", text: $card.address.city ?? "")
    }
}

/// TextField that can be used to capture the State for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCardState: View {
    @EnvironmentObject var card: PaymentCard
    public init() {
        
    }
    
    public var body: some View {
        TextField("State", text: $card.address.region ?? "")
            .autocapitalization(UITextAutocapitalizationType.allCharacters)
            .disableAutocorrection(true)
    }
}

/// TextField that can be used to capture the Zip for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCardZip: View {
    @EnvironmentObject var card: PaymentCard
    public init() {
        
    }
    
    public var body: some View {
        TextField("Zip", text: $card.address.postalCode ?? "")
            .keyboardType(.decimalPad)
    }
}

/// TextField that can be used to capture the Country for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCardCountry: View {
    @EnvironmentObject var card: PaymentCard
    public init() {
        
    }
    
    public var body: some View {
        TextField("Country", text: $card.address.country ?? "")
    }
}

/// TextField that can be used to capture the Country for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCombinedCard: View {
    public init() {
        
    }
    
    public var body: some View {
        HStack() {
            PTCardNumber()
                .frame(minWidth: 200)
            Spacer()
            HStack {
                PTExp()
            Spacer()
                PTCvv()
            }
        }
    }
}
