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
    private var isClosed: Bool?
    private var provider: WebSocketProvider?
    private var listener: WebSocketListener?
    public let REQUIRE_RESPONSE = true
    var handler: WebSocketProtocol?
    
    func prepare(_provider: WebSocketProvider, _handler: WebSocketProtocol) {
        self.handler = _handler
        self.provider = _provider
        self.listener = WebSocketListener()
        self.listener?.prepare(_session: self)
    }
    
    func open(ptToken: String, environment: String, stage: String) {

        self.provider!.startSocket(environment: environment, stage: stage, ptToken: ptToken, listener: self.listener!, _handler: self.handler!)
        
    }

    func close() {
        self.provider!.stopSocket()
    }

    
    func sendMessage(messageBody: String, requiresResponse: Bool = false) {

        self.provider!.sendMessage(message: .string(messageBody), handler: self.handler!)
        
        if (requiresResponse) {
            self.provider!.receive()
        }
    }
}
