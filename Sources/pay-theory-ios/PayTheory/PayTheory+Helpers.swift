//
//  PayTheory+Helpers.swift
//  PayTheory
//
//  Created by Austin Zani on 8/7/24.
//

import Foundation
import CryptoKit

extension PayTheory {
    
    // Manages the socket as the app goes behind the
    @objc func appMovedToBackground() {
        session?.close()
    }
    
    @objc func appCameToForeground() {
        Task {
            await fetchToken()
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
    
    // Requests a Host Token and go through the App Attestation process if needed
    func fetchToken() async -> Bool {
        do {
            let tokenData = try await getToken(apiKey: apiKey, environment: environment, stage: stage, sessionKey: sessionId)
            ptToken = tokenData["pt-token"] as? String ?? ""
            if devMode {
                // Skip attestation if it is in devMode for testing in the simulator
                self.attestationString = ""
                return true
            } else if attestationString == nil {
                // Go through the attestation process to set the attestation string
                if let challenge = tokenData["challengeOptions"]?["challenge"] as? String {
                    do {
                        let key = try await service.generateKey()
                        let encodedChallengeData = challenge.data(using: .utf8)!
                        let hash = Data(SHA256.hash(data: encodedChallengeData))
                        let attestation = try await service.attestKey(key, clientDataHash: hash)
                        self.attestationString = attestation.base64EncodedString()
                        return true
                    }
                    catch {
                        self.completion?(.failure(PTError(code: .invalidApp, error: "App Attestation Failed.")))
                        session?.close()
                        return false
                    }
                } else {
                    completion?(.failure(PTError(code: .noToken, error: "Failed to fetch the PT Token")))
                    session?.close()
                    return false
                }
            } else {
                // If we already have the attestation string return true that we
                return true
            }
        } catch {
            completion?(.failure(PTError(code: .noToken, error: "Failed to fetch the PT Token")))
            session?.close()
            debugPrint("failed to fetch pt-token")
            return false
        }
    }
    
    // Completion handler for messaging coming in from the WebSocket
    func onMessage(response: String) {
        if let dictionary = convertStringToDictionary(text: response) {
            let type = dictionary["type"] as? String ?? ""
            if type == HOST_TOKEN_TYPE {
                // Mark the PayTheory class as ready and set the session_key and public_key
                let body = dictionary["body"] as? [String: AnyObject] ?? [:]
                let hostToken = body["hostToken"] as? String ?? ""
                DispatchQueue.main.async {
                    self.transaction.hostToken = hostToken
                }
                transaction.sessionKey = body["sessionKey"] as? String ?? ""
                let key = body["publicKey"] as? String ?? ""
                self.transaction.publicKey = convertStringToByte(string: key)
            }
            
            if var body = dictionary["body"] as? String {
                if ENCRYPTED_MESSAGES.contains(type) {
                    let publicKey = dictionary["public_key"] as? String ?? ""
                    body = transaction.decryptBody(body: body, publicKey: publicKey)
                }
                if type == ERROR_TYPE {
                    completion?(.failure(PTError(code: .socketError, error: body)))
                    if transaction.hostToken != nil {
                        resetTransaction()
                    }
                } else if let parsedbody = convertStringToDictionary(text: body) {
                    switch (type) {
                        case TRANSFER_COMPLETE_TYPE:
                            if parsedbody["state"] as? String ?? "" == "FAILURE" {
                                completion?(.success(.Failure(FailedTransaction(response: parsedbody))))
                                resetTransaction()
                            } else {
                                completion?(.success(.Success(SuccessfulTransaction(response: parsedbody))))
                                transaction.resetTransaction()
                            }
                        case BARCODE_COMPLETE_TYPE:
                            completion?(.success(.Cash(CashBarcode(response: parsedbody))))
                        case TOKENIZE_COMPLETE_TYPE:
                            completion?(.success(.Tokenized(TokenizedPaymentMethod(response: parsedbody))))
                        case CALCULATE_FEE_TYPE:
                            handleCalcFeeResponse(response: parsedbody)
                        default:
                            debugPrint("Unknown message type returned")
                    }
                }
            }

            if let errors = dictionary["error"] as? [Any] {
                var result = ""
                for error in errors {
                    if let errorString = error as? String {
                        result += errorString
                    }
                }
                if result != "" {
                    completion?(.failure(PTError(code: .socketError, error: result)))

                } else {
                    completion?(.failure(PTError(code: .socketError, error: "An unknown socket error occured")))
                }
            }
        } else {
            debugPrint("Could not convert the response to a Dictionary")
            completion?(.failure(PTError(code: .socketError, error: "An unknown socket error occured")))
            if transaction.hostToken != nil {
                resetTransaction()
            }
        }
        
        if completion == nil {
            debugPrint("There is no completion handler to handle the response")
        }
    }
    
    // Create the body needed for fetching a Host Token and send it to the websocket
    func sendHostTokenMessage() {
        var message: [String: Any] = ["action": HOST_TOKEN]
        let hostToken: [String: Any] = [
            "ptToken": ptToken!,
            "origin": "apple",
            "attestation": attestationString ?? "",
            "timing": Date().millisecondsSince1970,
            "appleEnvironment": appleEnvironment
        ]
        message["encoded"] = stringify(jsonDictionary: hostToken).data(using: .utf8)!.base64EncodedString()
        session!.sendMessage(messageBody: stringify(jsonDictionary: message), requiresResponse: session!.REQUIRE_RESPONSE)
    }

    // Create the body for calculating the fee and messaging the websocket to calc the fee.
    func sendCalcFeeMessage(card_bin: String? = nil) {
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
            session?.sendMessage(messageBody: stringify(jsonDictionary: message), requiresResponse: session!.REQUIRE_RESPONSE)
        }
    }
    
    func handleCalcFeeResponse(response: [String: Any]) {
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
    
    func calcFeesWithAmount () {
        if let amount = amount {
            // Send calc fee for Bank Fee
            sendCalcFeeMessage()
            if let cardBin = cardBin {
                sendCalcFeeMessage(card_bin: cardBin)
            }
        }
    }
    
    // Used to reset when a transaction fails or an error is returned. Also used by cancel function.
    func resetTransaction() {
        initialized = false
        transaction.resetTransaction()
        Task {
            await fetchToken()
        }
    }
}
