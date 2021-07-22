//
//  PayTheory.swift
//  PayTheory
//
//  Created by Austin Zani on 11/3/20.
//

import Foundation

//public class Buyer: ObservableObject, Codable, Equatable {
//    public static func == (lhs: Buyer, rhs: Buyer) -> Bool {
//        if lhs.phone == rhs.phone &&
//        lhs.firstName == rhs.firstName &&
//        lhs.lastName == rhs.lastName &&
//        lhs.email == rhs.email &&
//            lhs.personalAddress == rhs.personalAddress {
//            return true
//        }
//        return false
//    }
//
//    @Published public var phone: String?
//    @Published public var firstName: String?
//    @Published public var lastName: String?
//    @Published public var email: String?
//    @Published public var personalAddress: Address
//
//    enum CodingKeys: CodingKey {
//        case phone, firstName, lastName, email, personalAddress
//    }
//
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(phone, forKey: .phone)
//        try container.encode(firstName, forKey: .firstName)
//        try container.encode(lastName, forKey: .lastName)
//        try container.encode(email, forKey: .email)
//        try container.encode(personalAddress, forKey: .personalAddress)
//    }
//
//    public required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//
//        phone = try container.decodeIfPresent(String.self, forKey: .phone) ?? nil
//        firstName = try container.decodeIfPresent(String.self, forKey: .firstName) ?? nil
//        lastName = try container.decodeIfPresent(String.self, forKey: .lastName) ?? nil
//        email = try container.decodeIfPresent(String.self, forKey: .email) ?? nil
//        personalAddress = try container.decode(Address.self, forKey: .personalAddress)
//    }
//
//    public init(firstName: String? = nil,
//                lastName: String? = nil,
//                email: String? = nil,
//                phone: String? = nil,
//                personalAddress: Address = Address()) {
//        self.email = email
//        self.firstName = firstName
//        self.lastName = lastName
//        self.phone = phone
//        self.personalAddress = personalAddress
//    }
//
//    func clear() {
//        self.email = nil
//        self.firstName = nil
//        self.lastName = nil
//        self.phone = nil
//        self.personalAddress = Address()
//    }
//}
