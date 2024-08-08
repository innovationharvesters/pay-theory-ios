//
//  PayTheory+Public.swift
//  PayTheory
//
//  Created by Austin Zani on 8/7/24.
//

import Foundation


extension PayTheory {
    
    /// Tokenizes a payment method based on the visible and valid payment instruments.
    /// - Parameters:
    ///   - payor: An optional `Payor` object representing the payor. Defaults to `nil`.
    ///   - payorId: An optional `String` representing the payor ID. Defaults to `nil`.
    ///   - metadata: An optional dictionary containing additional metadata. Defaults to `nil`.
    public func tokenizePaymentMethod(payor: Payor? = nil,
                                      payorId: String? = nil,
                                      metadata: [String: Any]? = nil) {
        // Check if the transaction is not initialized
        if initialized == false {
            // Set transaction properties
            self.transaction.payor = payor ?? envPayor
            self.transaction.metadata = metadata ?? [:]
            initialized = true
            
            // Check if only the card is visible and valid
            if (envCard.isVisible && envCard.isValid) && !envCash.isVisible && !envAch.isVisible {
                let body = transaction.createTokenizePaymentMethodBody(instrument: paymentCardToDictionary(card: envCard), payorId: payorId) ?? ""
                session?.sendMessage(messageBody: body, requiresResponse: session!.REQUIRE_RESPONSE)
            }
            // Check if only ACH is visible and valid
            else if (envAch.isVisible && envAch.isValid) && !envCash.isVisible && !envCard.isVisible {
                let body = transaction.createTokenizePaymentMethodBody(instrument: bankAccountToDictionary(account: envAch), payorId: payorId) ?? ""
                session?.sendMessage(messageBody: body, requiresResponse: session!.REQUIRE_RESPONSE)
            }
            // If no valid payment method is visible
            else {
                initialized = false
                completion?(.failure(PTError(code: .noFields, error: "No Visible and Valid PayTheory Fields to Transact")))
            }
        }
    }
    
    /// Processes a transaction with the given parameters.
    ///
    /// This function initializes and processes a transaction based on the provided parameters. It supports various payment methods
    /// including card, ACH, and cash. The function also validates the fee parameter if the fee mode is set to `SERVICE_FEE`.
    ///
    /// - Parameters:
    ///   - amount: The amount to be transacted.
    ///   - accountCode: An optional account code associated with the transaction.
    ///   - fee: An optional fee amount. Must be provided if `feeMode` is set to `SERVICE_FEE`.
    ///   - feeMode: The mode of the fee, either `.MERCHANT_FEE` or `.SERVICE_FEE`. Defailts to `.MERCHANT_FEE`
    ///   - healthExpenseType: An optional health expense type.
    ///   - invoiceId: An optional invoice ID.
    ///   - level3DataSummary: An optional summary of level 3 data.
    ///   - metadata: An optional dictionary of additional metadata.
    ///   - oneTimeUseToken: A boolean indicating whether a one-time use token is used.
    ///   - payor: An optional payor object. Defaults to `envPayor` if not provided.
    ///   - payorId: An optional payor ID.
    ///   - receiptDescription: An optional description for the receipt.
    ///   - recurringId: An optional recurring ID.
    ///   - reference: An optional reference string.
    ///   - sendReceipt: A boolean indicating whether to send a receipt.
    ///
    /// - Returns: Void
    ///
    /// - Note: The function exits early if the fee is not provided when `feeMode` is set to `SERVICE_FEE`.
    public func transact(amount: Int,
                         accountCode: String? = nil,
                         fee: Int? = nil,
                         feeMode: FEE_MODE = .MERCHANT_FEE,
                         healthExpenseType: HealthExpenseType? = nil,
                         invoiceId: String? = nil,
                         level3DataSummary: Level3DataSummary? = nil,
                         metadata: [String: Any]? = nil,
                         oneTimeUseToken: Bool = false,
                         payor: Payor? = nil,
                         payorId: String? = nil,
                         receiptDescription: String? = nil,
                         recurringId: String? = nil,
                         reference: String? = nil,
                         sendReceipt: Bool = false) {
        // Check if the transaction is not initialized and the host token is available
        if initialized == false && transaction.hostToken != nil {
            // Set transaction properties
            self.transaction.amount = amount
            self.transaction.payor = payor ?? envPayor
            self.transaction.feeMode = feeMode
            self.transaction.metadata = metadata ?? [:]
            
            // Validate that the fee is passed in if they are using the Service Fee mode
            if fee == nil && feeMode == .SERVICE_FEE {
                completion?(.failure(PTError(code: .invalidParam, error: "Fee must be passed in if you are using the Service Fee fee mode")))
                return // Exit the function if check is true
            }
            
            // Construct the payTheoryData dictionary with provided parameters and metadata
            let payTheoryData: [String: Any] = [
                "account_code": accountCode ?? (metadata?["pay-theory-account-code"] as? String ?? ""),
                "fee": fee ?? 0,
                "healthExpenseType": healthExpenseType ?? "",
                "invoice_id": invoiceId ?? "",
                "level3DataSummary": level3DataSummary ?? "",
                "oneTimeUseToken": oneTimeUseToken,
                "payor_id": payorId ?? "",
                "receipt_description": receiptDescription ?? (metadata?["pay-theory-receipt-description"] as? String ?? ""),
                "recurring_id": recurringId ?? "",
                "reference": reference ?? (metadata?["pay-theory-reference"] as? String ?? ""),
                "send_receipt": sendReceipt || (metadata?["pay-theory-receipt"] as? Bool ?? false),
                "timezone": TimeZone.current.identifier
            ]
            
            // Assign the constructed dictionary to the transaction's payTheoryData
            self.transaction.payTheoryData = payTheoryData
            initialized = true
            
            // Determine the payment method and send the appropriate message
            if (envCard.isVisible && envCard.isValid) && !envCash.isVisible && !envAch.isVisible {
                // If only the card is visible and valid
                let body = transaction.createTransferPartOneBody(instrument: paymentCardToDictionary(card: envCard)) ?? ""
                session?.sendMessage(messageBody: body, requiresResponse: session!.REQUIRE_RESPONSE)
            } else if (envAch.isVisible && envAch.isValid) && !envCash.isVisible && !envCard.isVisible {
                // If only ACH is visible and valid
                let body = transaction.createTransferPartOneBody(instrument: bankAccountToDictionary(account: envAch)) ?? ""
                session?.sendMessage(messageBody: body, requiresResponse: session!.REQUIRE_RESPONSE)
            } else if (envCash.isVisible && envCash.isValid) && !envCard.isVisible && !envAch.isVisible {
                // If only cash is visible and valid
                let body = transaction.createCashBody(payment: cashToDictionary(cash: envCash)) ?? ""
                session?.sendMessage(messageBody: body, requiresResponse: session!.REQUIRE_RESPONSE)
            } else {
                // If no valid payment method is visible
                initialized = false
                completion?(.failure(PTError(code: .noFields, error: "No Visible and Valid PayTheory Fields to Transact")))
            }
        }
    }
    
    /// This function will reset the environment objects used by the Pay Theory Fields so that new payment information can be reset.
    public func resetPT() {
        self.envAch.clear()
        self.envCard.clear()
        self.envPayor.clear()
        self.envCash.clear()
        self.transaction.resetTransaction()
        self.sessionId = generateUUID()
        Task {
            await fetchToken()
        }
    }
    
    public func updateAmount(newAmount: Int) {
        amount = newAmount
    }
    
}
