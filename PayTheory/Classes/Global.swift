//
//  PayTheory.swift
//  PayTheory
//
//  Created by Austin Zani on 11/3/20.
//

import Foundation

import AWSKMS

public class Address: ObservableObject, Codable, Equatable {
    public static func == (lhs: Address, rhs: Address) -> Bool {
        if lhs.city == rhs.city &&
        lhs.country == rhs.country &&
        lhs.region == rhs.region &&
        lhs.line1 == rhs.line1 &&
        lhs.line2 == rhs.line2 &&
        lhs.postal_code == rhs.postal_code {
            return true
        }
        
        return false
    }
    
    @Published public var city: String?
    @Published public var country: String?
    @Published public var region: String?
    @Published public var line1: String?
    @Published public var line2: String?
    @Published public var postal_code: String?
    
    enum CodingKeys: CodingKey {
        case city, country, region, line1, line2, postal_code
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(city, forKey: .city)
        try container.encode(country, forKey: .country)
        try container.encode(region, forKey: .region)
        try container.encode(line1, forKey: .line1)
        try container.encode(line2, forKey: .line2)
        try container.encode(postal_code, forKey: .postal_code)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        city = try container.decodeIfPresent(String.self, forKey: .city) ?? nil
        country = try container.decodeIfPresent(String.self, forKey: .country) ?? nil
        region = try container.decodeIfPresent(String.self, forKey: .region) ?? nil
        line1 = try container.decodeIfPresent(String.self, forKey: .line1) ?? nil
        line2 = try container.decodeIfPresent(String.self, forKey: .line2) ?? nil
        postal_code = try container.decodeIfPresent(String.self, forKey: .postal_code) ?? nil
    }
    
    public init() {}
}

func addressToDictionary(address: Address) -> [String: String] {
    var result: [String: String] = [:]
    
    if let city = address.city {
        result["city"] = city
    }
    if let country = address.country {
        result["country"] = country
    }
    if let region = address.region {
        result["region"] = region
    }
    if let line1 = address.line1 {
        result["line1"] = line1
    }
    if let line2 = address.line2 {
        result["line2"] = line2
    }
    if let postal_code = address.postal_code {
        result["postal_code"] = postal_code
    }
    
    return result
}
