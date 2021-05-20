//
//  TestData.swift
//  PayTheory_Tests
//
//  Created by Austin Zani on 5/18/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import PayTheory

let lastFour = "4242"
let receiptNumber = "Test Receipt"
let createdAt = "Now"
let amount = 100
let serviceFee = 20
let state = "OH"
let tags = ["Test": "Tags"]
let brand = "Visa"
let firstSix = "424242"
let type = "fail"


let transferToken = [
    "last_four": lastFour,
    "created_at": createdAt,
    "amount": amount,
    "service_fee": serviceFee,
    "state": state,
    "tags": tags,
    "type": type,
    "receipt_number": receiptNumber
] as [String: AnyObject]

let transferTokenWithBrand = [
    "last_four": lastFour,
    "created_at": createdAt,
    "amount": amount,
    "service_fee": serviceFee,
    "state": state,
    "tags": tags,
    "card_brand": brand,
    "type": type,
    "receipt_number": receiptNumber
] as [String : AnyObject]

let cardPaymentToken = [
    "idempotency": receiptNumber,
    "payment": [
        "amount": amount,
        "service_fee": serviceFee,
    ],
    "bin": [
        "card_brand": brand,
        "first_six": firstSix
    ]
] as [String: AnyObject]

let achPaymentToken = [
    "idempotency": receiptNumber,
    "payment": [
        "amount": amount,
        "service_fee": serviceFee,
    ],
    "bin": [
        "last_four": lastFour
    ]
] as [String: AnyObject]

let achCompletionResponse = [
    "receipt_number": receiptNumber,
    "last_four": lastFour,
    "created_at": createdAt,
    "amount": amount,
    "service_fee": serviceFee,
    "state": state,
    "tags": tags
] as [String: Any]

let cardCompletionResponse = [
    "receipt_number": receiptNumber,
    "last_four": lastFour,
    "created_at": createdAt,
    "amount": amount,
    "service_fee": serviceFee,
    "state": state,
    "tags": tags,
    "brand": brand
] as [String: AnyObject]

let failureResponse = FailureResponse(type: type, receiptNumber: receiptNumber, lastFour: lastFour, brand: brand)

let cardTokenizationResponse = [
    "receipt_number": receiptNumber,
    "amount": amount,
    "convenience_fee": serviceFee,
    "brand": brand,
    "first_six": firstSix
] as [String: AnyObject]

let achTokenizationResponse = [
    "receipt_number": receiptNumber,
    "amount": amount,
    "convenience_fee": serviceFee,
    "last_four": lastFour
] as [String: AnyObject]
