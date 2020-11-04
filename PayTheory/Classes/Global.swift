//
//  PayTheory.swift
//  PayTheory
//
//  Created by Austin Zani on 11/3/20.
//

import Foundation

extension String {
    func capitalizingFirstLetter() -> String {
      return prefix(1).uppercased() + self.lowercased().dropFirst()
    }

    mutating func capitalizeFirstLetter() {
      self = self.capitalizingFirstLetter()
    }
}

class Address: ObservableObject, Codable {
    @Published var city: String?
    @Published var country: String?
    @Published var region: String?
    @Published var line1: String?
    @Published var line2: String?
    @Published var postal_code: String?
    
    enum CodingKeys: CodingKey {
        case city, country, region, line1, line2, postal_code
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(city, forKey: .city)
        try container.encode(country, forKey: .country)
        try container.encode(region, forKey: .region)
        try container.encode(line1, forKey: .line1)
        try container.encode(line2, forKey: .line2)
        try container.encode(postal_code, forKey: .postal_code)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        city = try container.decodeIfPresent(String.self, forKey: .city) ?? nil
        country = try container.decodeIfPresent(String.self, forKey: .country) ?? nil
        region = try container.decodeIfPresent(String.self, forKey: .region) ?? nil
        line1 = try container.decodeIfPresent(String.self, forKey: .line1) ?? nil
        line2 = try container.decodeIfPresent(String.self, forKey: .line2) ?? nil
        postal_code = try container.decodeIfPresent(String.self, forKey: .postal_code) ?? nil
    }
    
    init() {}
}

class ResponseLinks: Codable {
    var verifications: Link
    var merchants: Link
    var settlements: Link
    var authorizations: Link
    var transfers: Link
    var payment_instruments: Link
    var assosciated_identities: Link
    var disputes: Link
    var application: Link
    var self_link: Link
    
    enum CodingKeys: String, CodingKey {
        case verifications
        case merchants
        case settlements
        case authorizations
        case transfers
        case payment_instruments
        case associated_identities
        case disputes
        case application
        case self_link = "self"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(verifications, forKey: .verifications)
        try container.encode(merchants, forKey: .merchants)
        try container.encode(settlements, forKey: .settlements)
        try container.encode(authorizations, forKey: .authorizations)
        try container.encode(transfers, forKey: .payment_instruments)
        try container.encode(assosciated_identities, forKey: .associated_identities)
        try container.encode(disputes, forKey: .disputes)
        try container.encode(application, forKey: .application)
        try container.encode(self_link, forKey: .self_link)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        verifications = try container.decode(Link.self, forKey: .verifications)
        merchants = try container.decode(Link.self, forKey: .merchants)
        settlements = try container.decode(Link.self, forKey: .settlements)
        authorizations = try container.decode(Link.self, forKey: .authorizations)
        transfers = try container.decode(Link.self, forKey: .transfers)
        payment_instruments = try container.decode(Link.self, forKey: .payment_instruments)
        assosciated_identities = try container.decode(Link.self, forKey: .associated_identities)
        disputes = try container.decode(Link.self, forKey: .disputes)
        application = try container.decode(Link.self, forKey: .application)
        self_link = try container.decode(Link.self, forKey: .self_link)
    }
}

class Link: Codable {
    var href: String
}

class Tags: Codable {
    var tag: String
}
