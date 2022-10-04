//
//  PayTheory.swift
//  PayTheory
//
//  Created by Austin Zani on 11/3/20.
//

import Foundation
import SwiftUI

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

//Action Constants
let HOST_TOKEN = "host:hostToken"
let TRANSFER_PART1 = "host:transfer_part1"
let TRANSFER_PART2 = "host:transfer_part2"
let TOKENIZE = "host:tokenize"
let CANCEL_TRANSFER = "host:cancel_transfer"
let BARCODE = "host:barcode"

// Constants for incoming message types
let HOST_TOKEN_TYPE = "host_token"
let TRANSFER_CONFIRMATION_TYPE = "transfer_confirmation"
let CANCEL_TYPE = "cancel"
let BARCODE_COMPLETE_TYPE = "barcode_complete"
let TRANSFER_COMPLETE_TYPE = "transfer_complete"
let TOKENIZE_COMPLETE_TYPE = "tokenize_complete"
let ERROR_TYPE = "error"

public let PT_CONFIRMATION = "CONFIRMATION"
public let PT_COMPLETE = "COMPLETE"
public let PT_BARCODE = "BARCODE"
public let PT_TOKENIZE = "TOKENIZE"

let ENCRYPTED_MESSAGES = [TRANSFER_CONFIRMATION_TYPE, BARCODE_COMPLETE_TYPE, TRANSFER_COMPLETE_TYPE, TOKENIZE_COMPLETE_TYPE]

public enum FEE_MODE: String, Codable {
    case INTERCHANGE = "interchange"
    case SERVICE_FEE = "service_fee"
}

public enum PAYMENT_TYPE: String, Codable {
    case CARD = "CARD"
    case ACH = "ACH"
    case CASH = "CASH"
}

//Extensions to swift foundational 
extension Date {
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

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

public func ?? <T>(lhs: Binding<T?>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}
public enum Environment {
    case DEMO, PROD
    
    var value: String {
        switch self {
        case .DEMO:
            return "demo"
        case .PROD:
            return "prod"
        }
    }
}

// Got list from https://github.com/melwynfurtado/postcode-validator/blob/master/src/postcode-regexes.ts
let postalRegexList: [[String]] = [
    ["UK",
     "^([A-Z]){1}([0-9][0-9]|[0-9]|[A-Z][0-9][A-Z]|[A-Z][0-9][0-9]|[A-Z][0-9]|[0-9][A-Z]){1}([ ])?([0-9][A-z][A-z]){1}$i"
    ],
    ["GB",
     "^([A-Z]){1}([0-9][0-9]|[0-9]|[A-Z][0-9][A-Z]|[A-Z][0-9][0-9]|[A-Z][0-9]|[0-9][A-Z]){1}([ ])?([0-9][A-z][A-z]){1}$i"
    ],
    ["JE","^JE\\d[\\dA-Z]?[ ]?\\d[ABD-HJLN-UW-Z]{2}$"],
    ["GG","^GY\\d[\\dA-Z]?[ ]?\\d[ABD-HJLN-UW-Z]{2}$"],
    ["IM","^IM\\d[\\dA-Z]?[ ]?\\d[ABD-HJLN-UW-Z]{2}$"],
    ["US","^([0-9]{5})(?:-([0-9]{4}))?$"],
    ["CA","^([ABCEGHJKLMNPRSTVXY][0-9][ABCEGHJKLMNPRSTVWXYZ])\\s*([0-9][ABCEGHJKLMNPRSTVWXYZ][0-9])$i"],
    ["IE","^([AC-FHKNPRTV-Y][0-9]{2}|D6W)[ -]?[0-9AC-FHKNPRTV-Y]{4}$"],
    ["DE","^\\d{5}$"],
    ["JP","^\\d{3}-\\d{4}$"],
    ["FR","^\\d{2}[ ]?\\d{3}$"],
    ["AU","^\\d{4}$"],
    ["IT","^\\d{5}$"],
    ["CH","^\\d{4}$"],
    ["AT","^(?!0)\\d{4}$"],
    ["ES","^(?:0[1-9]|[1-4]\\d|5[0-2])\\d{3}$"],
    ["NL","^\\d{4}[ ]?[A-Z]{2}$"],
    ["BE","^\\d{4}$"],
    ["DK","^\\d{4}$"],
    ["SE","^(SE-)?\\d{3}[ ]?\\d{2}$"],
    ["NO","^\\d{4}$"],
    ["BR","^\\d{5}[\\-]?\\d{3}$"],
    ["PT","^\\d{4}([\\-]\\d{3})?$"],
    ["FI","^(FI-|AX-)?\\d{5}$"],
    ["AX","^22\\d{3}$"],
    ["KR","^\\d{5}$"],
    ["CN", "^\\d{6}$"],
    ["TW","^\\d{3}(\\d{2})?$"],
    ["SG","^\\d{6}$"],
    ["DZ","^\\d{5}$"],
    ["AD","^AD\\d{3}$"],
    ["AR", "^([A-HJ-NP-Z])?\\d{4}([A-Z]{3})?$"],
    ["AM","^(37)?\\d{4}$"],
    ["AZ","^\\d{4}$"],
    ["BH","^((1[0-2]|[2-9])\\d{2})?$" ],
    ["BD","^\\d{4}$"],
    ["BB","^(BB\\d{5})?$"],
    ["BY", "^\\d{6}$"],
    ["BM","^[A-Z]{2}[ ]?[A-Z0-9]{2}$"],
    [
        "BA",
        "^\\d{5}$"
    ],
    [
        "IO",
        "^BBND 1ZZ$"
    ],
    [
        "BN",
        "^[A-Z]{2}[ ]?\\d{4}$"
    ],
    [
        "BG",
        "^\\d{4}$"
    ],
    [
        "KH",
        "^\\d{5}$"
    ],
    [
        "CV",
        "^\\d{4}$"
    ],
    [
        "CL",
        "^\\d{7}$"
    ],
    [
        "CR",
        "^(\\d{4,5}|\\d{3}-\\d{4})$"
    ],
    [
        "HR",
        "^(HR-)?\\d{5}$"
    ],
    [
        "CY",
        "^\\d{4}$"
    ],
    [
        "CZ",
        "^\\d{3}[ ]?\\d{2}$"
    ],
    [
        "DO",
        "^\\d{5}$"
    ],
    [
        "EC",
        "^([A-Z]\\d{4}[A-Z]|(?:[A-Z]{2})?\\d{6})?$"
    ],
    [
        "EG",
        "^\\d{5}$"
    ],
    [
        "EE",
        "^\\d{5}$"
    ],
    [
        "FO",
        "^\\d{3}$"
    ],
    [
        "GE",
        "^\\d{4}$"
    ],
    [
        "GR",
        "^\\d{3}[ ]?\\d{2}$"
    ],
    [
        "GL",
        "^39\\d{2}$"
    ],
    [
        "GT",
        "^\\d{5}$"
    ],
    [
        "HT",
        "^\\d{4}$"
    ],
    [
        "HN",
        "^(?:\\d{5})?$"
    ],
    [
        "HU",
        "^\\d{4}$"
    ],
    [
        "IS",
        "^\\d{3}$"
    ],
    [
        "IN",
        "^\\d{6}$"
    ],
    [
        "ID",
        "^\\d{5}$"
    ],
    [
        "IL",
        "^\\d{5,7}$"
    ],
    [
        "JO",
        "^\\d{5}$"
    ],
    [
        "KZ",
        "^\\d{6}$"
    ],
    [
        "KE",
        "^\\d{5}$"
    ],
    [
        "KW",
        "^\\d{5}$"
    ],
    [
        "LA",
        "^\\d{5}$"
    ],
    [
        "LV",
        "^(LV-)?\\d{4}$"
    ],
    [
        "LB",
        "^(\\d{4}([ ]?\\d{4})?)?$"
    ],
    [
        "LI",
        "^(948[5-9])|(949[0-7])$"
    ],
    [
        "LT",
        "^(LT-)?\\d{5}$"
    ],
    [
        "LU",
        "^(L-)?\\d{4}$"
    ],
    [
        "MK",
        "^\\d{4}$"
    ],
    [
        "MY",
        "^\\d{5}$"
    ],
    [
        "MV",
        "^\\d{5}$"
    ],
    [
        "MT",
        "^[A-Z]{3}[ ]?\\d{2,4}$"
    ],
    [
        "MU",
        "^((\\d|[A-Z])\\d{4})?$"
    ],
    [
        "MX",
        "^\\d{5}$"
    ],
    [
        "MD",
        "^\\d{4}$"
    ],
    [
        "MC",
        "^980\\d{2}$"
    ],
    [
        "MA",
        "^\\d{5}$"
    ],
    [
        "NP",
        "^\\d{5}$"
    ],
    [
        "NZ",
        "^\\d{4}$"
    ],
    [
        "NI",
        "^((\\d{4}-)?\\d{3}-\\d{3}(-\\d{1})?)?$"
    ],
    [
        "NG",
        "^(\\d{6})?$"
    ],
    [
        "OM",
        "^(PC )?\\d{3}$"
    ],
    [
        "PA",
        "^\\d{4}$"
    ],
    [
        "PK",
        "^\\d{5}$"
    ],
    [
        "PY",
        "^\\d{4}$"
    ],
    [
        "PH",
        "^\\d{4}$"
    ],
    [
        "PL",
        "^\\d{2}-\\d{3}$"
    ],
    [
        "PR",
        "^00[679]\\d{2}([ \\-]\\d{4})?$"
    ],
    [
        "RO",
        "^\\d{6}$"
    ],
    [
        "RU",
        "^\\d{6}$"
    ],
    [
        "SM",
        "^4789\\d$"
    ],
    [
        "SA",
        "^\\d{5}$"
    ],
    [
        "SN",
        "^\\d{5}$"
    ],
    [
        "SK",
        "^\\d{3}[ ]?\\d{2}$"
    ],
    [
        "SI",
        "^(SI-)?\\d{4}$"
    ],
    [
        "ZA",
        "^\\d{4}$"
    ],
    [
        "LK",
        "^\\d{5}$"
    ],
    [
        "TJ",
        "^\\d{6}$"
    ],
    [
        "TH",
        "^\\d{5}$"
    ],
    [
        "TN",
        "^\\d{4}$"
    ],
    [
        "TR",
        "^\\d{5}$"
    ],
    [
        "TM",
        "^\\d{6}$"
    ],
    [
        "UA",
        "^\\d{5}$"
    ],
    [
        "UY",
        "^\\d{5}$"
    ],
    [
        "UZ",
        "^\\d{6}$"
    ],
    [
        "VA",
        "^00120$"
    ],
    [
        "VE",
        "^\\d{4}$"
    ],
    [
        "ZM",
        "^\\d{5}$"
    ],
    [
        "AS",
        "^96799$"
    ],
    [
        "CC",
        "^6799$"
    ],
    [
        "CK",
        "^\\d{4}$"
    ],
    [
        "RS",
        "^\\d{5,6}$"
    ],
    [
        "ME",
        "^8\\d{4}$"
    ],
    [
        "CS",
        "^\\d{5}$"
    ],
    [
        "YU",
        "^\\d{5}$"
    ],
    [
        "CX",
        "^6798$"
    ],
    [
        "ET",
        "^\\d{4}$"
    ],
    [
        "FK",
        "^FIQQ 1ZZ$"
    ],
    [
        "NF",
        "^2899$"
    ],
    [
        "FM",
        "^(9694[1-4])([ \\-]\\d{4})?$"
    ],
    [
        "GF",
        "^9[78]3\\d{2}$"
    ],
    [
        "GN",
        "^\\d{3}$"
    ],
    [
        "GP",
        "^9[78][01]\\d{2}$"
    ],
    [
        "GS",
        "^SIQQ 1ZZ$"
    ],
    [
        "GU",
        "^969[123]\\d([ \\-]\\d{4})?$"
    ],
    [
        "GW",
        "^\\d{4}$"
    ],
    [
        "HM",
        "^\\d{4}$"
    ],
    [
        "IQ",
        "^\\d{5}$"
    ],
    [
        "KG",
        "^\\d{6}$"
    ],
    [
        "LR",
        "^\\d{4}$"
    ],
    [
        "LS",
        "^\\d{3}$"
    ],
    [
        "MG",
        "^\\d{3}$"
    ],
    [
        "MH",
        "^969[67]\\d([ \\-]\\d{4})?$"
    ],
    [
        "MN",
        "^\\d{6}$"
    ],
    [
        "MP",
        "^9695[012]([ \\-]\\d{4})?$"
    ],
    [
        "MQ",
        "^9[78]2\\d{2}$"
    ],
    [
        "NC",
        "^988\\d{2}$"
    ],
    [
        "NE",
        "^\\d{4}$"
    ],
    [
        "VI",
        "^008(([0-4]\\d)|(5[01]))([ \\-]\\d{4})?$"
    ],
    [
        "VN",
        "^\\d{6}$"
    ],
    [
        "PF",
        "^987\\d{2}$"
    ],
    [
        "PG",
        "^\\d{3}$"
    ],
    [
        "PM",
        "^9[78]5\\d{2}$"
    ],
    [
        "PN",
        "^PCRN 1ZZ$"
    ],
    [
        "PW",
        "^96940$"
    ],
    [
        "RE",
        "^9[78]4\\d{2}$"
    ],
    [
        "SH",
        "^(ASCN|STHL) 1ZZ$"
    ],
    [
        "SJ",
        "^\\d{4}$"
    ],
    [
        "SO",
        "^\\d{5}$"
    ],
    [
        "SZ",
        "^[HLMS]\\d{3}$"
    ],
    [
        "TC",
        "^TKCA 1ZZ$"
    ],
    [
        "WF",
        "^986\\d{2}$"
    ],
    [
        "XK",
        "^\\d{5}$"
    ],
    [
        "YT",
        "^976\\d{2}$"
    ]
]
