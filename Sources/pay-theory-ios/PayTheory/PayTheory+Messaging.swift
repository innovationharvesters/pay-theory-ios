//
//  PayTheory+Helpers.swift
//  PayTheory
//
//  Created by Austin Zani on 8/7/24.
//
// Extension of the Pay Theory class that contains functions used for messaging the websocket and also handling messages from the socket

import UIKit
import Foundation
import CryptoKit

extension PayTheory {
    
    func onMessage(response: String) {
        // Attempt to convert the response string to a dictionary
        guard let dictionary = convertStringToDictionary(text: response) else {
            // If conversion fails, handle it as an error and exit
            handleErrors(["Could not convert the response to a Dictionary"])
            return
        }

        // Extract the message type, defaulting to an empty string if not present
        let type = dictionary["type"] as? String ?? ""
        
        // Check if the response contains any errors
        if let errors = dictionary["error"] as? [Any] {
            // If errors are present, handle them and exit
            handleErrors(errors)
            return
        }

        // Attempt to extract the body from the response
        guard var body = dictionary["body"] as? String else {
            // If body is missing, handle it as an error and exit
            handleErrors(["Missing body in response"])
            return
        }

        // If the message type requires decryption, decrypt the body
        if ENCRYPTED_MESSAGES.contains(type) {
            let publicKey = dictionary["public_key"] as? String ?? ""
            body = transaction.decryptBody(body: body, publicKey: publicKey)
        }

        // If the message type indicates an error, handle it separately
        if type == ERROR_TYPE {
            handleErrorType(body)
            return
        }

        // Attempt to parse the body string into a dictionary
        guard let parsedBody = convertStringToDictionary(text: body) else {
            // If parsing fails, handle it as an error and exit
            handleErrors(["Could not parse body"])
            return
        }

        // Process the message based on its type
        handleMessageType(type, parsedBody)

        // Perform any necessary cleanup or final processing
        finishProcessing()
    }

    private func handleErrors(_ errors: [Any]) {
        let errorMessage = errors.compactMap { $0 as? String }.joined()
        let error = errorMessage.isEmpty ? "An unknown socket error occurred" : errorMessage
        useCompletionHandler(.failure(PTError(code: .socketError, error: error)))
        if transaction.hostToken != nil {
            resetTransaction()
        }
    }

    private func handleErrorType(_ body: String) {
        useCompletionHandler(.failure(PTError(code: .socketError, error: body)))
        if transaction.hostToken != nil {
            resetTransaction()
        }
    }

    private func handleMessageType(_ type: String, _ parsedBody: [String: Any]) {
        switch type {
        case TRANSFER_COMPLETE_TYPE:
            handleTransferComplete(parsedBody)
        case BARCODE_COMPLETE_TYPE:
            handleBarcodeComplete(parsedBody)
        case TOKENIZE_COMPLETE_TYPE:
            handleTokenizeComplete(parsedBody)
        case CALCULATE_FEE_TYPE:
            handleCalcFeeResponse(parsedBody)
        default:
            debugPrint("Unknown message type returned")
        }
    }

    private func handleTransferComplete(_ parsedBody: [String: Any]) {
        if parsedBody["state"] as? String ?? "" == "FAILURE" {
            useCompletionHandler(.success(.Failure(FailedTransaction(response: parsedBody))))
            resetTransaction()
        } else {
            isComplete = true
            useCompletionHandler(.success(.Success(SuccessfulTransaction(response: parsedBody))))
        }
    }

    private func handleBarcodeComplete(_ parsedBody: [String: Any]) {
        isComplete = true
        useCompletionHandler(.success(.Cash(CashBarcode(response: parsedBody))))
    }

    private func handleTokenizeComplete(_ parsedBody: [String: Any]) {
        isComplete = true
        useCompletionHandler(.success(.Tokenized(TokenizedPaymentMethod(response: parsedBody))))
    }

    private func finishProcessing() {
        if isAwaitingResponse {
            isAwaitingResponse = false
            
            if UIApplication.shared.applicationState == .background {
                endBackgroundTask()
            }
        }
        
        if completion == nil {
            debugPrint("There is no completion handler to handle the response")
        }
    }
    
    // Create the body needed for fetching a Host Token and send it to the websocket
    func sendHostTokenMessage() async throws {
        do {
            var message: [String: Any] = ["action": HOST_TOKEN]
            let hostToken: [String: Any] = [
                "ptToken": ptToken ?? "",
                "origin": "apple",
                "attestation": attestationString ?? "",
                "timing": Date().millisecondsSince1970,
                "appleEnvironment": appleEnvironment
            ]

            guard let encodedData = stringify(jsonDictionary: hostToken).data(using: .utf8) else {
                throw ConnectionError.hostTokenCallFailed
            }
            message["encoded"] = encodedData.base64EncodedString()
            
            let response = try await session.sendMessageAndWaitForResponse(messageBody: stringify(jsonDictionary: message))
            
            // Parse response
            guard let dictionary = convertStringToDictionary(text: response) else {
                throw ConnectionError.hostTokenCallFailed
            }
            
            guard let type = dictionary["type"] as? String, type == HOST_TOKEN_TYPE else {
                throw ConnectionError.hostTokenCallFailed
            }
            
            // Set the values from the response on the class variables they associate with
            let body = dictionary["body"] as? [String: AnyObject] ?? [:]
            DispatchQueue.main.async {
                self.transaction.hostToken = body["hostToken"] as? String ?? ""
            }
            transaction.sessionKey = body["sessionKey"] as? String ?? ""
            let key = body["publicKey"] as? String ?? ""
            self.transaction.publicKey = convertStringToByte(string: key)
            
            // Set isReady to true
            self.isReady = true
        } catch {
            throw ConnectionError.hostTokenCallFailed
        }
    }

    // Create the body for calculating the fee and messaging the websocket to calc the fee.
    func sendCalcFeeMessage(card_bin: String? = nil) {
        Task {
            do {
                let _ = try await ensureConnected()
            } catch {
                handleConnectionError(error)
            }
        }
        if let calcAmount = amount {
            var message: [String: Any] = ["action": CALCULATE_FEE]
            if let bin = card_bin {
                // Build calc fee message if we are calculating for a card
                let calcFeeBody: [String: Any] = [
                    "amount": calcAmount,
                    "is_ach": false,
                    "bank_id": bin,
                    "timing": Date().millisecondsSince1970
                ]
                message["encoded"] = stringify(jsonDictionary: calcFeeBody).data(using: .utf8)!.base64EncodedString()
            } else {
                // Build a calc fee message if we are calculating for a bank account
                let calcFeeBody: [String: Any] = [
                    "amount": calcAmount,
                    "is_ach": true,
                    "bank_id": NSNull(),
                    "timing": Date().millisecondsSince1970
                ]
                message["encoded"] = stringify(jsonDictionary: calcFeeBody).data(using: .utf8)!.base64EncodedString()
            }
            do {
                try session.sendMessage(messageBody: stringify(jsonDictionary: message))
            } catch {
                useCompletionHandler(.failure(PTError(code: .socketError, error: "There was an error sending the socket message")))
            }
        }
    }
    
    func handleCalcFeeResponse(_ response: [String: Any]) {
        if let fee = response["fee"] as? Int {
            if let bank_id = response["bank_id"] as? String {
                // Only set the cardServiceFee if it is for the correct current cardBin.
                // This needs to be here in case someone changes the card number quickly before the response comes through
                if bank_id == cardBin {
                    cardServiceFee = fee
                }
            } else {
                bankServiceFee = fee
            }
        } else {
            debugPrint("Fee was not returned succesfully")
        }
    }
}
