//
//  PayTheory.swift
//  PayTheory
//
//  Created by Austin Zani on 11/3/20.
//

import Foundation

public class FailureResponse: Error, Equatable {
    public static func == (lhs: FailureResponse, rhs: FailureResponse) -> Bool {
        if lhs.receiptNumber == rhs.receiptNumber &&
        lhs.lastFour == rhs.lastFour &&
        lhs.brand == rhs.brand &&
        lhs.state == rhs.state &&
        lhs.type == rhs.type {
            return true
        }
        return false
    }

    public var receiptNumber: String?
    public var lastFour: String?
    public var brand: String?
    public var state: String?
    public var type: String
    public init(type: String) {
        self.type = type
    }
    
    public init(type: String, receiptNumber: String, lastFour: String, brand: String?) {
        self.type = type
        self.receiptNumber = receiptNumber
        self.lastFour = lastFour
        self.brand = brand
    }
}
