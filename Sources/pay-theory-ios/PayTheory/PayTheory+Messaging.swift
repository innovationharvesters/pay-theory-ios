//
//  PayTheory+Helpers.swift
//  PayTheory
//
//  Created by Austin Zani on 8/7/24.
//
// Extension of the Pay Theory class that contains functions
// used for messaging the websocket and also handling messages from the socket

import Foundation
import CryptoKit

extension PayTheory {
    private func parseResponse(response: String) -> Result<(type: String, body: [String: Any]), PTError> {
        log.info("PayTheory::parseResponse")
        // Attempt to convert the response string to a dictionary
        guard let dictionary = convertStringToDictionary(text: response) else {
            // If conversion fails, handle it as an error and exit
            return .failure(handleErrors(["Could not convert the response to a Dictionary"]))
        }

        // Extract the message type, defaulting to an empty string if not present
        let type = dictionary["type"] as? String ?? ""
        
        // Check if the response contains any errors
        if let errors = dictionary["error"] as? [Any] {
            // If errors are present, handle them and exit
            return .failure(handleErrors(errors))
        }

        // Attempt to extract the body from the response
        guard let body = dictionary["body"] else {
            // If body is missing, handle it as an error and exit
            return .failure(handleErrors(["Missing body in response"]))
        }
        
        // Check if body is a String or [String: Any]
        var parsedBody: [String: Any]
        if var stringBody = body as? String {
            // If the message type requires decryption, decrypt the body
            if encryptedMessages.contains(type) {
                let publicKey = dictionary["public_key"] as? String ?? ""
                stringBody = transaction.decryptBody(body: stringBody, publicKey: publicKey)
                // Attempt to parse the body string into a dictionary
                guard let parsed = convertStringToDictionary(text: stringBody) else {
                    // If parsing fails, handle it as an error and exit
                    return .failure(handleErrors(["Could not parse body"]))
                }
                parsedBody = parsed
            } else if type == errorResponseMessage {
                return .failure(handleErrorType(stringBody))
            } else {
                return .failure(handleErrors(["Invalid body type in response"]))
            }
        } else if let dictBody = body as? [String: Any] {
            parsedBody = dictBody
        } else {
            // If body is neither String nor [String: Any], handle as error and exit
            return .failure(handleErrors(["Invalid body type in response"]))
        }
        
        return .success((type, parsedBody))
    }
    
    func onMessage(response: String) {
        log.info("PayTheory::onMessage")
        let response = parseResponse(response: response)
        if case .failure(let error) = response {
            self.errorHandler(error)
        } else if case .success(let (type, parsedBody)) = response {
            // Process the message based on its type
            handleMessageType(type, parsedBody)

            // Perform any necessary cleanup or final processing
            finishProcessing()
        }
    }

    private func handleErrors(_ errors: [Any]) -> PTError {
        log.info("PayTheory::handleErrors")
        let errorMessage = errors.compactMap { $0 as? String }.joined()
        let error = errorMessage.isEmpty ? "An unknown socket error occurred" : errorMessage
        let ptError = PTError(code: .socketError, error: error)
        if transaction.hostToken != nil {
            resetTransaction()
        }
        return ptError
    }

    private func handleErrorType(_ body: String) -> PTError {
        log.info("PayTheory::handleErrorType")
        if transaction.hostToken != nil {
            resetTransaction()
        }
        return PTError(code: .socketError, error: body)
    }

    private func handleMessageType(_ type: String, _ parsedBody: [String: Any]) {
        log.info("PayTheory::handleMessageType")
        switch type {
        case calculateFeeResponseMessage:
            handleCalcFeeResponse(parsedBody)
        default:
            debugPrint("Type not recognized. \(type)")
        }
    }

    private func finishProcessing() {
        log.info("PayTheory::finishProcessing")
        if isAwaitingResponse {
            isAwaitingResponse = false
        }
    }
    
    // Used to parse transaction repsponses to be used in the transact function logic
    func parseTransactResponse(_ response: String) -> TransactResponse {
        log.info("PayTheory::parseTransactResponse")
        let response = parseResponse(response: response)
        if case .failure(let error) = response {
            return .error(error)
        } else if case .success(let (type, parsedBody)) = response {
            switch type {
            case transferResponseMessage:
                if parsedBody["state"] as? String ?? "" == "FAILURE" {
                    resetTransaction()
                    return .failure(FailedTransaction(response: parsedBody))
                } else {
                    setComplete(true)
                    return .success(SuccessfulTransaction(response: parsedBody))
                }
            case barcodeResponseMessage:
                setComplete(true)
                return .barcode(CashBarcode(response: parsedBody))
            default:
                return .error(PTError(code: .socketError, error: "Unknown response type: \(type)"))
            }
        }
        resetTransaction()
        return .error(PTError(code: .socketError, error: "Unknown response type."))
    }
    
    // Used to parse the tokenization responses to be used in the tokenizePaymentMethod function logic
    func parseTokenizeResponse(_ response: String) -> TokenizePaymentMethodResponse {
        log.info("PayTheory::parseTokenizeResponse")
        let response = parseResponse(response: response)
        if case .failure(let error) = response {
            return .error(error)
        } else if case .success(let (type, parsedBody)) = response {
            switch type {
            case tokenizeResponseMessage:
                setComplete(true)
                return .success(TokenizedPaymentMethod(response: parsedBody))
            default:
                return .error(PTError(code: .socketError, error: "Unknown response type: \(type)"))
            }
        }
        resetTransaction()
        return .error(PTError(code: .socketError, error: "Unknown response type."))
    }
    
    // Create the body needed for fetching a Host Token and send it to the websocket
    func sendHostTokenMessage(calcFees: Bool = true) async throws {
        log.info("PayTheory::sendHostTokenMessage")
        
        do {
            var message: [String: Any] = ["action": hostTokenMessage]
            let hostToken: [String: Any] = [
                "ptToken": ptToken ?? "",
                "origin": "apple",
                "attestation": attestationString ?? "",
                "timing": Date().millisecondsSince1970,
                "appleEnvironment": appleEnvironment,
                "require_attestation": self.stage == "paytheory" ? true : !devMode
            ]
            
            log.info("PayTheory::sendHostTokenMessage - ptToken: \(String(describing: ptToken))")
            log.info("PayTheory::sendHostTokenMessage - attestation: \(String(describing: attestationString))")
            log.info("PayTheory::sendHostTokenMessage - require_attestation: \(String(describing: hostToken["require_attestation"]))")

            guard let encodedData = stringify(jsonDictionary: hostToken).data(using: .utf8) else {
                log.error("PayTheory::sendHostTokenMessage::stringify(jsonDictionary: hostToken).data(using: .utf8)")
                throw ConnectionError.hostTokenCallFailed
            }
            message["encoded"] = encodedData.base64EncodedString()
            
            let response = try await session.sendMessageAndWaitForResponse(messageBody: stringify(jsonDictionary: message))
            // Parse response
            guard let dictionary = convertStringToDictionary(text: response) else {
                log.error("PayTheory::sendHostTokenMessage::convertStringToDictionary(text: response)")
                throw ConnectionError.hostTokenCallFailed
            }
            
            guard let type = dictionary["type"] as? String else {
                log.error("PayTheory::sendHostTokenMessage::dictionary[\"type\"] as? String")
                throw ConnectionError.hostTokenCallFailed
            }
            
            if type == errorResponseMessage, let body = dictionary["body"] as? String {
                log.info("PayTheory::sendHostTokenMessage - body: \(body)")

                if body.lowercased().contains("attestation") {
                    throw ConnectionError.attestationFailed
                } else {
                    throw ConnectionError.hostTokenCallFailed
                }
            }
            
            // Set the values from the response on the class variables they associate with
            let body = dictionary["body"] as? [String: AnyObject] ?? [:]
            
            self.transaction.hostToken = body["hostToken"] as? String ?? ""
            self.transaction.sessionKey = body["sessionKey"] as? String ?? ""
            
            log.info("PayTheory::sendHostTokenMessage - hostToken: \(String(describing: self.transaction.hostToken))")
            
            let key = body["publicKey"] as? String ?? ""
            self.transaction.publicKey = convertStringToByte(string: key)
            
            // Set isReady to true, set the timestamp for the host token, and calc fees if needed
            setReady(true)
            self.hostTokenTimestamp = Date()
            if calcFees && (amount != nil) {
                calcFeesWithAmount()
            }
        } catch {
            if let error = error as? ConnectionError {
                throw error
            } else {
                throw ConnectionError.hostTokenCallFailed
            }
        }
    }

    // Create the body for calculating the fee and messaging the websocket to calc the fee.
    func sendCalcFeeMessage(cardBin: String? = nil) {
        log.info("PayTheory::sendCalcFeeMessage")
        Task {
            do {
                _ = try await ensureConnected()
            } catch {
                _ = handleConnectionError(error)
            }
        }
        if let calcAmount = amount {
            var message: [String: Any] = ["action": calculateFeeMessage]
            if let bin = cardBin {
                // Build calc fee message if we are calculating for a card
                let calcFeeBody: [String: Any] = [
                    "amount": calcAmount,
                    "is_ach": false,
                    "bank_id": bin,
                    "timing": Date().millisecondsSince1970,
                    "sessionKey": self.sessionId
                ]
                message["encoded"] = stringify(jsonDictionary: calcFeeBody).data(using: .utf8)!.base64EncodedString()
            } else {
                // Build a calc fee message if we are calculating for a bank account
                let calcFeeBody: [String: Any] = [
                    "amount": calcAmount,
                    "is_ach": true,
                    "bank_id": NSNull(),
                    "timing": Date().millisecondsSince1970,
                    "sessionKey": self.sessionId
                ]
                message["encoded"] = stringify(jsonDictionary: calcFeeBody).data(using: .utf8)!.base64EncodedString()
            }
            do {
                try session.sendMessage(messageBody: stringify(jsonDictionary: message))
            } catch {
                errorHandler(PTError(code: .socketError, error: "There was an error sending the socket message"))
            }
        }
    }
    
    func handleCalcFeeResponse(_ response: [String: Any]) {
        log.info("PayTheory::handleCalcFeeResponse")
        if let fee = response["fee"] as? Int {
            if let bankId = response["bank_id"] as? String {
                // Only set the cardServiceFee if it is for the correct current cardBin.
                // This needs to be here in case someone changes the card number quickly before the response comes through
                if bankId == cardBin {
                    self.cardServiceFee = fee
                }
            } else {
                self.bankServiceFee = fee
            }
        } else {
            self.errorHandler(PTError(code: .socketError, error: "There was an error calculating the fees"))
        }
    }
}
