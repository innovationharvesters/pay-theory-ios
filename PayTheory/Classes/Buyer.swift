//
//  BuyerFields.swift
//  PayTheory
//
//  Created by Austin Zani on 3/15/21.
//
import SwiftUI
import Foundation

public class Buyer: ObservableObject, Codable, Equatable {
    public static func == (lhs: Buyer, rhs: Buyer) -> Bool {
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
public struct PTBuyerFirstName: View {
    @EnvironmentObject var identity: Buyer
    public init() {
    }
   public var body: some View {
        TextField("First Name", text: $identity.firstName ?? "")
    }
}

/// TextField that can be used to capture the Last Name for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTBuyerLastName: View {
    @EnvironmentObject var identity: Buyer
    public init() {
    }
    public var body: some View {
        TextField("Last Name", text: $identity.lastName ?? "")
    }
}

/// TextField that can be used to capture the Phone for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTBuyerPhone: View {
    @EnvironmentObject var identity: Buyer
    public init() {
    }
    public var body: some View {
        TextField("Phone", text: $identity.phone ?? "")
    }
}

/// TextField that can be used to capture the Email for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTBuyerEmail: View {
    @EnvironmentObject var identity: Buyer
    public init() {
    }
    public var body: some View {
        TextField("Email", text: $identity.email ?? "")
    }
}

/// TextField that can be used to capture the Address Line 1 for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTBuyerLineOne: View {
    @EnvironmentObject var identity: Buyer
    public init() {
    }
    public var body: some View {
        TextField("Address Line 1", text: $identity.personalAddress.line1 ?? "")
    }
}

/// TextField that can be used to capture the Address Line 2 for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTBuyerLineTwo: View {
    @EnvironmentObject var identity: Buyer
    public init() {
    }
    public var body: some View {
        TextField("Address Line 2", text: $identity.personalAddress.line2 ?? "")
    }
}

/// TextField that can be used to capture the City for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTBuyerCity: View {
    @EnvironmentObject var identity: Buyer
    public init() {
    }
    public var body: some View {
        TextField("City", text: $identity.personalAddress.city ?? "")
    }
}

/// TextField that can be used to capture the State for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTBuyerState: View {
    @EnvironmentObject var identity: Buyer
    public init() {
    }
    public var body: some View {
        TextField("State", text: $identity.personalAddress.region ?? "")
    }
}

/// TextField that can be used to capture the Zip for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTBuyerZip: View {
    @EnvironmentObject var identity: Buyer
    public init() {
    }
    public var body: some View {
        TextField("Zip", text: $identity.personalAddress.postalCode ?? "")
    }
}

/// TextField that can be used to capture the Country for Buyer Options to be used in a Pay Theory payment
///
///  - Requires: Ancestor view must be wrapped in a PTForm
///
public struct PTBuyerCountry: View {
    @EnvironmentObject var identity: Buyer
    public init() {
    }
    public var body: some View {
        TextField("Country", text: $identity.personalAddress.country ?? "")
    }
}
