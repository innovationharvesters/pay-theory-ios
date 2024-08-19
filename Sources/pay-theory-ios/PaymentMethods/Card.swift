//
//  CardFields.swift
//  PayTheory
//
//  Created by Austin Zani on 3/15/21.
//
import SwiftUI
import Foundation
import Combine

class Card: ObservableObject, Equatable, PaymentMethod {
    static func == (lhs: Card, rhs: Card) -> Bool {
        if lhs.name == rhs.name &&
            lhs.expirationDate == rhs.expirationDate &&
            lhs.address == rhs.address &&
            lhs.number == rhs.number &&
            lhs.type == rhs.type &&
            lhs.securityCode == rhs.securityCode {
            return true
        }
        return false
    }

    private var type = "card"
    @Published var isVisible: Bool = false
    @Published var name: String?
    @Published var address = Address()
    @Published var expirationDate = ""
    @Published var number = ""
    @Published var securityCode = ""
    
    @Published var isValid: Bool = false
    @Published var expirationMonth: String = ""
    @Published var expirationYear: String = ""
    private var cancellables = Set<AnyCancellable>()
    
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
                if data.count == 5 {
                    result = "20" + String(data.suffix(2))
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
        return number.filter { $0.isNumber }
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
    
    var validExpirationDate: AnyPublisher<Bool,Never> {
        return Publishers.CombineLatest(expirationYearPublisher, expirationMonthPublisher)
            .map { year, month in
                return isValidExpDate(month: month, year: year)
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
    
    var validPostalCode: AnyPublisher<Bool, Never> {
        return address.$postalCode
            .map { data in
                let unwrapped = data ?? ""
                return isValidPostalCode(value: unwrapped)
            }
            .eraseToAnyPublisher()
    }
    
    var isValidPublisher: AnyPublisher<Bool,Never> {
        return Publishers.CombineLatest4(validCardNumber, validSecurityCode, validExpirationDate, validPostalCode)
            .map { validNumber, validCode, validDate, validPostal in
                if validNumber == false || validCode == false || validDate == false || validPostal == false {
                    return false
                }
                return true
            }
            .eraseToAnyPublisher()
    }
    
    init() {
        isValidPublisher.sink { valid in
            self.isValid = valid
                }
        .store(in: &cancellables)
        expirationMonthPublisher.sink { month in
            self.expirationMonth = month
        }
        .store(in: &cancellables)
        expirationYearPublisher.sink { year in
            self.expirationYear = year
        }
        .store(in: &cancellables)
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
    
    func clear() {
        self.number = ""
        self.expirationDate = ""
        self.securityCode = ""
        self.address = Address()
        self.name = nil
    }
    
}

/// TextField that can be used to capture the Name for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCardName: View {
    @EnvironmentObject var card: Card
    let placeholder: String
    
    public init(placeholder: String = "Name on Card") {
        self.placeholder = placeholder
    }

    public var body: some View {
        TextField(placeholder, text: $card.name ?? "")
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
    @EnvironmentObject var card: Card
    let placeholder: String
    
    /// Initializes a new instance of the view with a placeholder text.
    ///
    /// - Parameter placeholder: A `String` that represents the placeholder text for the text field. The default value is "Card Number".
    public init(placeholder: String = "Card Number") {
        self.placeholder = placeholder
    }
    
    public var body: some View {
        TextField(placeholder, text: $card.number)
            .onChange(of: card.number) { newValue in
                card.number = insertCreditCardSpaces(newValue.filter({$0 .isNumber}))
            }
            .keyboardType(.decimalPad)
            .trackVisibility(card)
    }
}

/// TextField that can be used to capture the Expiration Year for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
///  - Important: This is required to be able to run a transaction.
///
public struct PTExp: View {
    @EnvironmentObject var card: Card
    let placeholder: String
    
    /// Initializes a new instance of the view with a placeholder text.
    ///
    /// - Parameter placeholder: A `String` that represents the placeholder text for the text field. The default value is "MM / YY".
    public init(placeholder: String = "MM/YY") {
        self.placeholder = placeholder
    }
    
    public var body: some View {
        TextField(placeholder, text: $card.expirationDate)
            .onChange(of: card.expirationDate) { newValue in
                card.expirationDate = formatExpirationDate(newValue)
            }
            .keyboardType(.decimalPad)
    }
    
    private func formatExpirationDate(_ input: String) -> String {
        // Remove all non-numeric characters from the input
        var cleaned = input.filter { $0.isNumber }
        var formatted = ""
        
        if cleaned.count > 0 {
            // Extract the month from the first two characters (if available)
            let month = Int(cleaned.prefix(2)) ?? 0
            
            if month > 12 {
                // If month is greater than 12, take the first digit and prepend a 0
                formatted = "0\(cleaned.prefix(1))"
                cleaned = "0\(cleaned)" // Update cleaned string for year formatting
            } else if month == 0 {
                // If month is 0, set it to "0"
                formatted = "0"
            } else if cleaned.count > 1 {
                // For valid months with more than one digit
                formatted = month < 10 ? "0\(month)" : "\(month)"
            } else {
                // For single digit input, don't add leading zero yet
                formatted = "\(month)"
            }
            
            if cleaned.count > 2 {
                // Add slash after month if there's input for year
                formatted += "/"
                // Take up to two digits for the year
                let year = String(cleaned.suffix(cleaned.count - 2).prefix(2))
                formatted += year
            }
        }
        
        return formatted
    }
}

/// TextField that can be used to capture the CVV for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
///  - Important: This is required to be able to run a transaction.
///
public struct PTCvv: View {
    @EnvironmentObject var card: Card
    let placeholder: String
    
    /// Initializes a new instance of the view with a placeholder text.
    ///
    /// - Parameter placeholder: A `String` that represents the placeholder text for the text field. The default value is "CVV".
    public init(placeholder: String = "CVV") {
        self.placeholder = placeholder
    }
    
    public var body: some View {
        TextField(placeholder, text: $card.securityCode)
            .onChange(of: card.securityCode) { newValue in
                card.securityCode = formatDigitTextField(newValue, maxLength: 4)
            }
            .keyboardType(.decimalPad)
    }
}

/// TextField that can be used to capture the Address Line 1 for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCardLineOne: View {
    @EnvironmentObject var card: Card
    let placeholder: String
    
    /// Initializes a new instance of the view with a placeholder text.
    ///
    /// - Parameter placeholder: A `String` that represents the placeholder text for the text field. The default value is "Address Line 1".
    public init(placeholder: String = "Address Line 1") {
        self.placeholder = placeholder
    }
    
    public var body: some View {
        TextField(placeholder, text: $card.address.line1 ?? "")
            .autocapitalization(UITextAutocapitalizationType.words)
    }
}

/// TextField that can be used to capture the Address Line 2 for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCardLineTwo: View {
    @EnvironmentObject var card: Card
    let placeholder: String
    
    /// Initializes a new instance of the view with a placeholder text.
    ///
    /// - Parameter placeholder: A `String` that represents the placeholder text for the text field. The default value is "Address Line 2".
    public init(placeholder: String = "Address Line 2") {
        self.placeholder = placeholder
    }
    
    public var body: some View {
        TextField(placeholder, text: $card.address.line2 ?? "")
    }
}

/// TextField that can be used to capture the City for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCardCity: View {
    @EnvironmentObject var card: Card
    let placeholder: String
    
    /// Initializes a new instance of the view with a placeholder text.
    ///
    /// - Parameter placeholder: A `String` that represents the placeholder text for the text field. The default value is "City".
    public init(placeholder: String = "City") {
        self.placeholder = placeholder
    }
    
    public var body: some View {
        TextField(placeholder, text: $card.address.city ?? "")
    }
}

/// TextField that can be used to capture the Region for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCardRegion: View {
    @EnvironmentObject var card: Card
    let placeholder: String
    
    /// Initializes a new instance of the view with a placeholder text.
    ///
    /// - Parameter placeholder: A `String` that represents the placeholder text for the text field. The default value is "Region".
    public init(placeholder: String = "Region") {
        self.placeholder = placeholder
    }
    
    public var body: some View {
        TextField(placeholder, text: $card.address.region ?? "")
            .autocapitalization(UITextAutocapitalizationType.allCharacters)
            .disableAutocorrection(true)
    }
}

/// TextField that can be used to capture the Postal Code for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCardPostalCode: View {
    @EnvironmentObject var card: Card
    let placeholder: String
    
    /// Initializes a new instance of the view with a placeholder text.
    ///
    /// - Parameter placeholder: A `String` that represents the placeholder text for the text field. The default value is "Postal Code".
    public init(placeholder: String = "Postal Code") {
        self.placeholder = placeholder
    }
    
    public var body: some View {
        TextField(placeholder, text: $card.address.postalCode ?? "")
            .keyboardType(.numbersAndPunctuation)
    }
}

/// TextField that can be used to capture the Country for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCardCountry: View {
    @EnvironmentObject var card: Card
    let placeholder: String
    
    /// Initializes a new instance of the view with a placeholder text.
    ///
    /// - Parameter placeholder: A `String` that represents the placeholder text for the text field. The default value is "Country".
    public init(placeholder: String = "Country") {
        self.placeholder = placeholder
    }
    
    public var body: some View {
        TextField(placeholder, text: $card.address.country ?? "")
    }
}

/// TextField that can be used to capture the Country for a card object to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTCombinedCard: View {
    let numberPlaceholder: String
    let expPlaceholder: String
    let cvvPlaceholder: String
    
    /// Initializes a new instance of the view with placeholder texts for card details.
    ///
    /// - Parameters:
    ///   - numberPlaceholder: A `String` that represents the placeholder text for the card number field. The default value is "Card Number".
    ///   - expPlaceholder: A `String` that represents the placeholder text for the expiration date field. The default value is "MM / YY".
    ///   - cvvPlaceholder: A `String` that represents the placeholder text for the CVV field. The default value is "CVV".
    public init(numberPlaceholder: String = "Card Number",
                expPlaceholder: String = "MM / YY",
                cvvPlaceholder: String = "CVV") {
        self.numberPlaceholder = numberPlaceholder
        self.expPlaceholder = expPlaceholder
        self.cvvPlaceholder = cvvPlaceholder
    }
    
    public var body: some View {
        HStack() {
            PTCardNumber(placeholder: numberPlaceholder)
                .frame(minWidth: 200)
            Spacer()
            HStack {
                PTExp(placeholder: expPlaceholder)
            Spacer()
                PTCvv(placeholder: cvvPlaceholder)
            }
        }
    }
}
