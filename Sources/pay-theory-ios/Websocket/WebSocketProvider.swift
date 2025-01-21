//
//  WebSocketProvider.swift
//  PayTheory
//
//  Created by Aron Price on 4/1/21.
//

import Foundation

/**
 * Responsible for all calls made to websocket server
 */
public class WebSocketProvider: NSObject {
    var webSocket: URLSessionWebSocketTask?
    var handler: WebSocketProtocol?
    private var defaultHandler: WebSocketProtocol?
    private var asyncResponseHandler: ((Result<String, Error>) -> Void)?
    private var connectionCompletion: ((Result<Void, Error>) -> Void)?

    override init() {
        super.init()
    }
    
    func setDefaultHandler(_ handler: WebSocketProtocol) {
        log.info("WebSocketProvider::setDefaultHandler")
        self.defaultHandler = handler
    }
        
    private(set) var status: WebSocketStatus = .notConnected
    
    func startSocket(environment: String,
                     stage: String,
                     ptToken: String,
                     listener: WebSocketListener,
                     socketHandler: WebSocketProtocol) async throws {
        log.info("WebSocketProvider::startSocket")

        return try await withCheckedThrowingContinuation { continuation in
            let urlSession = URLSession(configuration: .default, delegate: listener, delegateQueue: OperationQueue())
            let socketUrl = "wss://\(environment).secure.socket.\(stage).com/\(environment)/?pt_token=\(ptToken)"
            
            guard let url = URL(string: socketUrl) else {
                continuation.resume(throwing: NSError(domain: "WebSocket", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
                return
            }
            
            var request = URLRequest(url: url)
            // Add required headers
            request.addValue("websocket", forHTTPHeaderField: "Upgrade")
            request.addValue("Upgrade", forHTTPHeaderField: "Connection")
            request.addValue("13", forHTTPHeaderField: "Sec-WebSocket-Version")
            
            handler = socketHandler
            webSocket = urlSession.webSocketTask(with: request)
            status = .connecting
            
            connectionCompletion = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
                self.connectionCompletion = nil
            }
            
            self.webSocket!.resume()
            log.info("WebSocketProvider::Socket connecting...")
        }
    }
    
    func connectionEstablished() {
        log.info("WebSocketProvider::connectionEstablished")
        status = .connected
        connectionCompletion?(.success(()))
        self.receive()
    }

    func connectionFailed(with error: Error) {
        log.info("WebSocketProvider::connectionFailed")
        status = .disconnected
        connectionCompletion?(.failure(error))
    }
    
    func receive() {
        // Don't start receiving if we're already disconnected
        guard status != .disconnected else { return }
        
        webSocket!.receive { [weak self] result in
            guard let self = self else { return }
            
            // Don't process messages if we're disconnected
            guard self.status != .disconnected else { return }
            
            switch result {
            case .success(let message):
                self.status = .connected
                switch message {
                case .string(let text):
                    if let asyncHandler = self.asyncResponseHandler {
                        asyncHandler(.success(text))
                        self.asyncResponseHandler = nil
                    } else {
                        self.defaultHandler?.receiveMessage(message: text)
                    }
                default:
                    let error = NSError(domain: "WebSocket", code: 0, userInfo: [NSLocalizedDescriptionKey: "Received unknown response type"])
                    if let asyncHandler = self.asyncResponseHandler {
                        asyncHandler(.failure(error))
                        self.asyncResponseHandler = nil
                    } else {
                        self.defaultHandler?.handleError(error: error)
                    }
                }
            case .failure(let error):
                // Only handle error if it's not a cancellation error
                if (error as NSError).code != URLError.cancelled.rawValue {
                    self.status = .disconnected
                    if let asyncHandler = self.asyncResponseHandler {
                        asyncHandler(.failure(error))
                        self.asyncResponseHandler = nil
                    } else {
                        self.defaultHandler?.handleError(error: error)
                    }
                }
            }
            
            // Only continue receiving if we're still connected
            if self.status == .connected {
                self.receive()
            }
        }
    }

    func sendMessageAndWaitForResponse(message: URLSessionWebSocketTask.Message) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            sendMessage(message: message, handler: defaultHandler!)

            self.asyncResponseHandler = { result in
                switch result {
                case .success(let text):
                    continuation.resume(returning: text)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func sendMessage(message: URLSessionWebSocketTask.Message, handler: WebSocketProtocol) {
        log.info("WebSocketProvider::sendMessage")

        if self.asyncResponseHandler != nil {
            log.error("WebSocketProvider::Cannot send message while waiting for response")
            return
        }
        webSocket?.send(message, completionHandler: { (error) in
            if error != nil {
                self.handler!.handleError(error: error!)
                self.stopSocket()
            }
        })
    }
    
    func stopSocket() {
        log.info("WebSocketProvider::stopSocket")

        // Set status to disconnected first to prevent new receive calls
        status = .disconnected
        
        // Clear any pending async handlers
        if let asyncHandler = asyncResponseHandler {
            asyncHandler(.failure(NSError(domain: "WebSocket", 
                                       code: URLError.cancelled.rawValue, 
                                       userInfo: [NSLocalizedDescriptionKey: "WebSocket connection closed"])))
            asyncResponseHandler = nil
        }
        
        // Close the socket
        webSocket?.cancel(with: .normalClosure, reason: webSocket?.closeReason)
        webSocket = nil
    }
}
    
enum WebSocketStatus {
    case notConnected
    case connecting
    case connected
    case disconnected
}
