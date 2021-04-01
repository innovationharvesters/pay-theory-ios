//
//  Websocket.swift
//  PayTheory
//
//  Created by Aron Price on 4/1/21.
//

import Foundation
/**
 * Responsible for managing websocket events
 */
public class WebSocketListener: NSObject, URLSessionWebSocketDelegate {
    
    private var session: WebSocketSession?
    
    func prepare(_session: WebSocketSession) {
        self.session = _session
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("connected")
        self.session!.handler!.handleConnect()
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("disconnected")
        self.session!.handler!.handleDisconnect()
    }
    
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError: Error?) {
        if (didBecomeInvalidWithError != nil) {
            self.session!.handler!.handleError(error:didBecomeInvalidWithError!)
        }
        print("errored")
        self.session?.close()
    }

}
