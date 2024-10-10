//
//  PayTheory.swift
//  PayTheory
//
//  Created by Austin Zani on 11/3/20.
//

import Foundation
import SwiftUI

// MARK: - Public Enums

public enum FeeMode: String, Codable {
    case MERCHANT_FEE = "merchant_fee"
    case SERVICE_FEE = "service_fee"
}

public enum PaymentType: String, CaseIterable, Identifiable {
    case CARD = "Card"
    case ACH = "ACH"
    case CASH = "Cash"
    
    public var id: Self { self }
}

public enum HealthExpenseType: String, Encodable {
    case healthcare = "HEALTHCARE"
    case rx = "RX"
    case vision = "VISION"
    case clinical = "CLINICAL"
    case copay = "COPAY"
    case dental = "DENTAL"
    case transit = "TRANSIT"
}


// MARK: - Message names
//Action Constants
let HOST_TOKEN = "host:hostToken"
let TRANSFER_PART1 = "host:transfer_part1"
let TOKENIZE = "host:tokenize"
let BARCODE = "host:barcode"
let CALCULATE_FEE = "host:calculate_fee"

// Constants for incoming message types
let HOST_TOKEN_TYPE = "host_token"
let BARCODE_COMPLETE_TYPE = "barcode_complete"
let TRANSFER_COMPLETE_TYPE = "transfer_complete"
let TOKENIZE_COMPLETE_TYPE = "tokenize_complete"
let ERROR_TYPE = "error"
let CALCULATE_FEE_TYPE = "calculate_fee_complete"

let ENCRYPTED_MESSAGES = [BARCODE_COMPLETE_TYPE, TRANSFER_COMPLETE_TYPE, TOKENIZE_COMPLETE_TYPE]

//MARK: - Extensions to swift foundational
extension Date {
    var millisecondsSince1970: Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    init(milliseconds: Int64) {
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

func ?? <T>(lhs: Binding<T?>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}
