//
//  PayTheory+Helpers.swift
//  PayTheory
//
//  Created by Austin Zani on 8/7/24.
//
// Extension of the Pay Theory class that contains functions
// used for initializes and maintaing the websocket as well as making any HTTP calls

import Foundation
import CryptoKit

enum ConnectionError: Error {
    case attestationFailed
    case hostTokenCallFailed
    case socketConnectionFailed
    case tokenFetchFailed
}

extension PayTheory {
    public func handleActiveState() {
        log.info("PayTheory::handleActiveState")
        Task {
            do {
                _ = try await ensureConnected()
            } catch {
                var connectionError: ConnectionError = .socketConnectionFailed
                if let error = error as? ConnectionError {
                    connectionError = error
                }
                _ = handleConnectionError(connectionError, sendToErrorHandler: true)
            }
        }
    }
    
    // Closes the socket and cleans up sensitive data as the app goes to background
    public func handleBackgroundState() {
        log.info("PayTheory::handleBackgroundState")
        if session.status != .connected { return }
        
        // Close the socket connection
        session.close()
        
        // Clear sensitive data
        ptToken = nil
        attestationString = nil
        
        // Reset any pending operations or state
        sessionId = UUID().uuidString
    }
    
    // Requests a Host Token and go through the App Attestation process if needed
    func fetchToken() async throws {
        log.info("PayTheory::fetchToken")
        // Fetch token and set the ptToken variable from the response
        let tokenData = try await getToken(apiKey: apiKey,
                                           environment: environment,
                                           stage: stage,
                                           sessionKey: sessionId)
        
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
                } catch {
                    if session.status == .connected {
                        session.close()
                    }
                    throw ConnectionError.attestationFailed
                }
            } else {
                if session.status == .connected {
                    session.close()
                }
                throw ConnectionError.tokenFetchFailed
            }
        }
    }
    
    func connectSocket() async throws  {
        log.info("PayTheory::connectSocket")
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
            log.error("PayTheory::connectSocket::Error sending host token message: \(error)")
            throw error
        }
    }
    
    func handleConnectionError(_ error: Error, sendToErrorHandler: Bool = true) -> PTError {
        let parsedError: PTError
        switch error {
        case ConnectionError.attestationFailed:
            parsedError = PTError(code: .attestationFailed, error: "Failed app attestation")
        case ConnectionError.socketConnectionFailed:
            parsedError = PTError(code: .socketError, error: "Socket failed to connect")
        case ConnectionError.hostTokenCallFailed:
            parsedError = PTError(code: .tokenFailed, error: "Host token message failed")
        case ConnectionError.tokenFetchFailed:
            parsedError = PTError(code: .tokenFailed, error: "There was an error fetching the token")
        default:
            parsedError = PTError(code: .socketError, error: "An unknown error occurred")
        }
        if sendToErrorHandler {
            self.errorHandler(parsedError)
        }
        return parsedError
    }
    
    /// Checks to see if the socket is connected
    /// Returns true if socket was already connected or false if it had to reconnect
    func ensureConnected() async throws -> Bool {
        log.info("PayTheory::ensureConnected")
        // Check if the socket is already connected
        if session.status == .connected {
            return true
        }
        // If not connected, try to reconnect
        do {
            try await connectSocket()
            return false
        } catch {
            log.error("PayTheory::ensureConnected::Error connecting to socket: \(error)")
            throw error
        }
    }
}
