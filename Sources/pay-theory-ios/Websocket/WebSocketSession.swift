//
//  WebsocketSession.swift
//  PayTheory
//
//  Created by Aron Price on 4/1/21.
//

import Foundation
/**
 * Responsible for managing websocket session
 * including closing and restarting as appropriate
 */
public class WebSocketSession: NSObject {
    var handler: WebSocketProtocol?
    private var listener: WebSocketListener?
    var provider: WebSocketProvider?
    var status: WebSocketStatus {
        return provider?.status ?? .notConnected
    }
    
    func prepare(_provider: WebSocketProvider, _handler: WebSocketProtocol) {
        self.handler = _handler
        self.listener = WebSocketListener()
        self.provider = _provider
        self.listener?.prepare(_session: self)
        self.provider?.setDefaultHandler(_handler)
    }
    
    func open(ptToken: String, environment: String, stage: String) async throws {
        guard let provider = self.provider else {
            throw ConnectionError.socketConnectionFailed
        }
        do {
            try await provider.startSocket(environment: environment, stage: stage, ptToken: ptToken, listener: self.listener!, _handler: self.handler!)
        } catch {
            throw ConnectionError.socketConnectionFailed
        }
    }

    func close() {
        self.provider!.stopSocket()
    }

    
    func sendMessage(messageBody: String) throws {
        guard let provider = self.provider else {
            throw NSError(domain: "WebSocket", code: 0, userInfo: [NSLocalizedDescriptionKey: "WebSocket provider is not initialized"])
        }
        provider.sendMessage(message: .string(messageBody), handler: self.handler!)
    }
    
    func sendMessageAndWaitForResponse(messageBody: String) async throws -> String {
        guard let provider = self.provider else {
            throw NSError(domain: "WebSocket", code: 0, userInfo: [NSLocalizedDescriptionKey: "WebSocket provider is not initialized"])
        }
        
        let message = URLSessionWebSocketTask.Message.string(messageBody)
        return try await provider.sendMessageAndWaitForResponse(message: message)
    }
}
