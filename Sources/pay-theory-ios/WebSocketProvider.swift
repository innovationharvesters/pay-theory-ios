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
    
    override init() {
        super.init()
    }
    
    func startSocket(environment:String, stage: String, ptToken:String, listener: WebSocketListener, _handler: WebSocketProtocol) {
        let urlSession = URLSession(configuration: .default, delegate: listener, delegateQueue: OperationQueue())
        let socketUrl = "wss://\(environment).secure.socket.\(stage).com/\(environment)/?pt_token=\(ptToken)"
        handler = _handler
        webSocket = urlSession.webSocketTask(with: URL(string:socketUrl)!)
        print("socket connected")
        self.webSocket!.resume()
    }
    
    func receive() {
        webSocket!.receive { result in
        switch result {
        case .success(let message):
          switch message {
          case .string(let text):
            self.handler!.receiveMessage(message: text)
          default:
            print("recieved unknown response type")
          }
        case .failure(let error):
            self.handler!.handleError(error: error)
            self.stopSocket()
        }
      }
    }
    
    func sendMessage(message:URLSessionWebSocketTask.Message, handler: WebSocketProtocol) {
        webSocket?.send(message, completionHandler: { (error) in
            if (error != nil) {
                self.handler!.handleError(error: error!)
                self.stopSocket()
            }
        })
    }
    
    func stopSocket() {
        webSocket?.cancel(with: .normalClosure, reason: webSocket?.closeReason)
    }
}
    
    
