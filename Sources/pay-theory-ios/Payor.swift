//
//  PayorFields.swift
//  PayTheory
//
//  Created by Austin Zani on 3/15/21.
//
import SwiftUI
import Foundation

public class Payor: ObservableObject, Codable, Equatable {
    public static func == (lhs: Payor, rhs: Payor) -> Bool {
        if lhs.phone == rhs.phone &&
        lhs.firstName == rhs.firstName &&
        lhs.lastName == rhs.lastName &&
        lhs.email == rhs.email &&
            lhs.personalAddress == rhs.personalAddress {
            return true
        }
        return false
    }

    @Published public var phone: String?
    @Published public var firstName: String?
    @Published public var lastName: String?
    @Published public var email: String?
    @Published public var personalAddress: Address
    
    enum CodingKeys: CodingKey {
        case phone, firstName, lastName, email, personalAddress
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(phone, forKey: .phone)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(email, forKey: .email)
        try container.encode(personalAddress, forKey: .personalAddress)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        phone = try container.decodeIfPresent(String.self, forKey: .phone) ?? nil
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName) ?? nil
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName) ?? nil
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? nil
        personalAddress = try container.decode(Address.self, forKey: .personalAddress)
    }
    
    public init(firstName: String? = nil,
                lastName: String? = nil,
                email: String? = nil,
                phone: String? = nil,
                personalAddress: Address = Address()) {
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
        self.personalAddress = personalAddress
    }
    
    func clear() {
        self.email = nil
        self.firstName = nil
        self.lastName = nil
        self.phone = nil
        self.personalAddress = Address()
    }
}


/// TextField that can be used to capture the First Name for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTPayorFirstName: View {
    @EnvironmentObject var identity: Payor
    let placeholder: String
    
    public init(placeholder: String = "First Name") {
        self.placeholder = placeholder
    }
    
    public var body: some View {
        TextField(placeholder, text: $identity.firstName ?? "")
    }
}

/// TextField that can be used to capture the Last Name for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTPayorLastName: View {
    @EnvironmentObject var identity: Payor
    let placeholder: String
    
    public init(placeholder: String = "Last Name") {
        self.placeholder = placeholder
    }
    
    public var body: some View {
        TextField(placeholder, text: $identity.lastName ?? "")
    }
}

/// TextField that can be used to capture the Phone for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTPayorPhone: View {
    @EnvironmentObject var identity: Payor
    let placeholder: String
    
    public init(placeholder: String = "Phone Number") {
        self.placeholder = placeholder
    }
    
    public var body: some View {
        TextField(placeholder, text: $identity.phone ?? "")
    }
}

/// TextField that can be used to capture the Email for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTPayorEmail: View {
    @EnvironmentObject var identity: Payor
    let placeholder: String
    
    public init(placeholder: String = "Email") {
        self.placeholder = placeholder
    }
    
    public var body: some View {
        TextField(placeholder, text: $identity.email ?? "")
    }
}

/// TextField that can be used to capture the Address Line 1 for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTPayorLineOne: View {
    @EnvironmentObject var identity: Payor
    let placeholder: String
    
    public init(placeholder: String = "Address Line 1") {
        self.placeholder = placeholder
    }
    
    public var body: some View {
        TextField(placeholder, text: $identity.personalAddress.line1 ?? "")
    }
}

/// TextField that can be used to capture the Address Line 2 for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTPayorLineTwo: View {
    @EnvironmentObject var identity: Payor
    let placeholder: String
    
    public init(placeholder: String = "Address Line 2") {
        self.placeholder = placeholder
    }
    
    public var body: some View {
        TextField(placeholder, text: $identity.personalAddress.line2 ?? "")
    }
}

/// TextField that can be used to capture the City for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTPayorCity: View {
    @EnvironmentObject var identity: Payor
    let placeholder: String
    
    public init(placeholder: String = "City") {
        self.placeholder = placeholder
    }
    
    public var body: some View {
        TextField(placeholder, text: $identity.personalAddress.city ?? "")
    }
}

/// TextField that can be used to capture the State for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTPayorRegion: View {
    @EnvironmentObject var identity: Payor
    let placeholder: String
    
    public init(placeholder: String = "Region") {
        self.placeholder = placeholder
    }
    
    public var body: some View {
        TextField(placeholder, text: $identity.personalAddress.region ?? "")
    }
}

/// TextField that can be used to capture the Zip for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTPayorPostalCode: View {
    @EnvironmentObject var identity: Payor
    let placeholder: String
    
    public init(placeholder: String = "Postal Code") {
        self.placeholder = placeholder
    }
    
    public var body: some View {
        TextField(placeholder, text: $identity.personalAddress.postalCode ?? "")
    }
}

/// TextField that can be used to capture the Country for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTPayorCountry: View {
    @EnvironmentObject var identity: Payor
    let placeholder: String
    
    public init(placeholder: String = "Country") {
        self.placeholder = placeholder
    }
    
    public var body: some View {
        TextField(placeholder, text: $identity.personalAddress.country ?? "")
    }
}
