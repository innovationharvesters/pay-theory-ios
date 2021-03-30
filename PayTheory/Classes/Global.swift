//
//  PayTheory.swift
//  PayTheory
//
//  Created by Austin Zani on 11/3/20.
//

import Foundation

public class Address: ObservableObject, Codable, Equatable {
    public static func == (lhs: Address, rhs: Address) -> Bool {
        if lhs.city == rhs.city &&
        lhs.country == rhs.country &&
        lhs.region == rhs.region &&
        lhs.line1 == rhs.line1 &&
        lhs.line2 == rhs.line2 &&
        lhs.postalCode == rhs.postalCode {
            return true
        }
        return false
    }

    @Published public var city: String?
    @Published public var country: String?
    @Published public var region: String? {
        didSet {
            if let unwrappedRegion = self.region {
                if unwrappedRegion.count > 2 {
                    region = oldValue
                }
            }
        }
    }
    @Published public var line1: String?
    @Published public var line2: String?
    @Published public var postalCode: String? {
        didSet {
            if let unwrappedCode = postalCode {
                let filtered = unwrappedCode.filter { $0.isNumber }
                if unwrappedCode != filtered {
                    postalCode = filtered
                }
            }
        }
    }
    
    enum CodingKeys: CodingKey {
        case city, country, region, line1, line2, postalCode
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(city, forKey: .city)
        try container.encode(country, forKey: .country)
        try container.encode(region, forKey: .region)
        try container.encode(line1, forKey: .line1)
        try container.encode(line2, forKey: .line2)
        try container.encode(postalCode, forKey: .postalCode)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        city = try container.decodeIfPresent(String.self, forKey: .city) ?? nil
        country = try container.decodeIfPresent(String.self, forKey: .country) ?? nil
        region = try container.decodeIfPresent(String.self, forKey: .region) ?? nil
        line1 = try container.decodeIfPresent(String.self, forKey: .line1) ?? nil
        line2 = try container.decodeIfPresent(String.self, forKey: .line2) ?? nil
        postalCode = try container.decodeIfPresent(String.self, forKey: .postalCode) ?? nil
    }
    
    public init(line1: String? = nil,
                line2: String? = nil,
                city: String? = nil,
                country: String? = nil,
                state: String? = nil,
                zip: String? = nil) {
        self.city = city
        self.country = country
        self.line1 = line1
        self.line2 = line2
        self.postalCode = zip
        self.region = state
    }
}

let HOST_TOKEN = "host:hostToken"
let PT_INSTRUMENT = "host:ptInstrument"
let IDEMPOTENCY = "host:idempotency"
let TRANSFER = "host:transfer"
