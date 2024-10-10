//
//  PayTheory+Helpers.swift
//  PayTheory
//
//  Created by Austin Zani on 8/7/24.
//
// Extension of the Pay Theory class that contains functions used for initializes and maintaing the websocket as well as making any HTTP calls

import Foundation
import CryptoKit

enum ConnectionError: Error {
    case attestationFailed
    case hostTokenCallFailed
    case socketConnectionFailed
    case tokenFetchFailed
}

extension PayTheory {
    
    func handleActiveState() {
        Task {
            do {
                let _ = try await ensureConnected()
            } catch {
                let _ = handleConnectionError(error, sendToErrorHandler: true)
            }
        }
    }
    
    // Closes the socket as the app goes behind the
    func handleBackgroundState() {
        if session.status != .connected { return }
        session.close()
    }
    
    // Requests a Host Token and go through the App Attestation process if needed
    func fetchToken() async throws {
        // Fetch token and set the ptToken variable from the response
        let tokenData = try await getToken(apiKey: apiKey, environment: environment, stage: stage, sessionKey: sessionId)
        ptToken = tokenData["pt-token"] as? String ?? ""
        if devMode {
            // Skip attestation if it is in devMode for testing in the simulator
            self.attestationString = ""
        } else if attestationString == nil {
            // Go through the attestation process to set the attestation string
            if let challenge = tokenData["challengeOptions"]?["challenge"] as? String {
                do {
                    let key = try await service.generateKey()
                    let encodedChallengeData = challenge.data(using: .utf8)!
                    let hash = Data(SHA256.hash(data: encodedChallengeData))
                    let attestation = try await service.attestKey(key, clientDataHash: hash)
                    self.attestationString = attestation.base64EncodedString()
                }
                catch {
                    if (session.status == .connected) {
                        session.close()
                    }
                    throw ConnectionError.attestationFailed
                }
            } else {
                if (session.status == .connected) {
                    session.close()
                }
                throw ConnectionError.tokenFetchFailed
            }
        }
    }
    
    func connectSocket(initial_connection: Bool = false) async throws {
        // Fetch the PT Token to pass into socket connection
        do {
            try await fetchToken()
        } catch ConnectionError.attestationFailed {
            throw ConnectionError.attestationFailed
        } catch {
            throw ConnectionError.tokenFetchFailed
        }
        // Open the websocket
        do {
            try await session.open(ptToken: ptToken!, environment: environment, stage: stage)
        } catch {
            throw ConnectionError.socketConnectionFailed
        }
        //Send the host token message
        do {
            try await sendHostTokenMessage()
        } catch {
            throw ConnectionError.hostTokenCallFailed
        }
    }
    
    func handleConnectionError(_ error: Error, sendToErrorHandler: Bool = true) -> PTError {
        var parsedError: PTError = PTError(code: .socketError, error: "An unknown error occurred")
        
        switch error {
        case ConnectionError.attestationFailed:
            parsedError = PTError(code: .attestationFailed, error: "Failed app attestation")
        case ConnectionError.socketConnectionFailed:
            parsedError = PTError(code: .socketError, error: "Socket failed to connect")
        case ConnectionError.hostTokenCallFailed:
            parsedError = PTError(code: .tokenFailed, error: "Host token message failed")
        default:
            // Skip because the error is already set to unknown error
            debugPrint("Unknown Socket Error")
        }
        if sendToErrorHandler {
            self.handleError(error: parsedError)
        }
        return parsedError
    }
    
    /// Checks to see if the socket is connected
    /// Returns true if socket was already connected or false if it had to reconnect
    func ensureConnected() async throws -> Bool {
        // Check if the socket is already connected
        if session.status == .connected {
            return true
        }
        // If not connected, try to reconnect
        do {
            try await connectSocket()
            return false
        } catch {
            throw error
        }
    }
}
