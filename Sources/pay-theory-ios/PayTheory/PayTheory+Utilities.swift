//
//  PayTheory+Helpers.swift
//  PayTheory
//
//  Created by Austin Zani on 8/7/24.
//
// Extension of the Pay Theory class that contains helper functions and utilities for the PayTheory class

import Foundation

extension PayTheory {
    
    // Used to reset when a transaction fails or an error is returned. Also used by cancel function.
    func resetTransaction() {
        isInitialized = false
        transaction.resetTransaction()
        Task {
            do {
                let connected = try await ensureConnected()
                if connected == true {
                    try await fetchToken()
                    try await sendHostTokenMessage()
                }
            } catch {
                self.useCompletionHandler(.failure(PTError(code: .tokenFailed, error: "Fetching the token failed")))
            }
        }
    }
    
    func useCompletionHandler(_ result: Result<SuccessfulResponse, PTError>) {
        if let completion = completion {
            completion(result)
        } else {
            debugPrint("The completion handler is not set on the PayTheory object", result)
        }
    }
    
    func calcFeesWithAmount () {
        if let _ = amount {
            // Send calc fee for Bank Fee
            sendCalcFeeMessage()
            if let cardBin = cardBin {
                sendCalcFeeMessage(card_bin: cardBin)
            }
        }
    }
    
    /// Function that checks the new card number and updates the cardBin if it has changed
    ///
    /// If it is greater than 6 and is different than what is set in the cardBin then we should set the value to the new value
    ///
    /// If the new value is less than 6 characters then we should set the cardBin to nil
    func cardNumberChanged(_ newNumber: String) {
        // Strip non-numerical characters
        let numericString = newNumber.filter { $0.isNumber }
        
        // Ensure it's 6 characters or longer and compare to cardBin. Set if needed.
        if numericString.count >= 6 {
            let firstSixDigits = String(numericString.prefix(6))
            if firstSixDigits != cardBin {
                cardBin = firstSixDigits
            }
        } else {
            if cardBin != nil {
                cardBin = nil
            }
        }
    }
    
    func canCallAction() -> Bool {
        if isComplete == true {
            useCompletionHandler(.failure(PTError(code: .actionComplete, error: "Pay Theory class has already succesfully tokenized or made a transaction.")))
            return false
        } else if isInitialized == true {
            useCompletionHandler(.failure(PTError(code: .inProgress, error: "Transact or Tokenize function is already in progress.")))
            return false
        }
        return true
    }
}
