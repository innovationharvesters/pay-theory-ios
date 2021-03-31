//
//  PayTheory.swift
//  PayTheory
//
//  Created by Austin Zani on 11/3/20.
//

import Foundation
import Alamofire
import Sodium

enum ResponseError: String, Error {
    case noData = "There was no data in the repsonse"
    case canNotDecode = "Unable to decode the response"
}

extension Date {
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }

    init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

func handleResponse<T: Codable>(response: AFDataResponse<Any>, completion: @escaping (Result<T, Error>) -> Void) {
    debugPrint(response)
    guard response.error == nil else {
            print("Call failed")
            if let value = response.value as? [String: AnyObject] {
                      print(value)
                   }
        if let data = response.data {
            let json = String(data: data, encoding: String.Encoding.utf8)
            let errorArray = convertStringToDictionary(text: json!)
            if let errors = errorArray {
                if let error = errors["reason"] {
                    completion(.failure(FailureResponse(type: error as? String ?? "Unknown Error")))
                    return
                }
                if let error = errors["message"] {
                    completion(.failure(FailureResponse(type: error as? String ?? "Unknown Error")))
                    return
                }
            }
        }
        completion(.failure(FailureResponse(type: response.error!.localizedDescription)))
            return
            }
   guard let data = response.data else {
            print("No Data")
    completion(.failure(FailureResponse(type: ResponseError.noData.rawValue)))
            return
            }
    
    if let decodedResponse = try? JSONDecoder().decode(T.self, from: data) {
        print("Call successfull")
        completion(.success(decodedResponse))
       } else {
            print("Can't decode")
        completion(.failure(FailureResponse(type: ResponseError.canNotDecode.rawValue)))
       }
}

func handleMapResponse(response: AFDataResponse<Any>, completion: @escaping (Result<[String: AnyObject], Error>) -> Void) {
                        
                        guard response.error == nil else {
                                print("Call failed")
                                if let value = response.value as? [String: AnyObject] {
                                          print(value)
                                       }
                            if let data = response.data {
                                let json = String(data: data, encoding: String.Encoding.utf8)
                                let errorArray = convertStringToDictionary(text: json!)
                                if let errors = errorArray {
                                    completion(.failure(FailureResponse(type: errors["reason"] as? String ?? "Unknown Error")))
                                    return
                                }
                            }
                            completion(.failure(FailureResponse(type: response.error!.localizedDescription)))
                                return
                                }
                        
                        if let value = response.value as? [String: AnyObject] {
                            if value["state"] as? String ?? "" == "FAILURE" {
                                completion(.failure(FailureResponse(type: value["type"] as? String ?? "",
                                                                    receiptNumber: value["receipt_number"] as? String ?? "",
                                                                    lastFour: value["last_four"] as? String ?? "",
                                                                    brand: value["brand"] as? String ?? "")))
                            } else {
                                completion(.success(value))
                            }
                                } else {
                                print("Can't decode")
                                    completion(.failure(FailureResponse(type: ResponseError.canNotDecode.rawValue)))
                           }
                        }



func getToken(apiKey: String,
              endpoint: String,
              completion: @escaping (Result<[String: AnyObject], Error>) -> Void) {
    
    let url = endpoint == "prod" ?
        "https://tags.api.paytheory.com/pt-token" :
        "https://\(endpoint).tags.api.paytheorystudy.com/pt-token"
    
    let headers: HTTPHeaders = [
        "X-API-Key": apiKey,
        "Content-Type": "application/json"
    ]
    
    AF.request(url, headers: headers).validate().responseJSON { response in
        handleMapResponse(response: response, completion: completion)
    }
}

func getChallenge(apiKey: String,
                  endpoint: String,
                  completion: @escaping (Result<Challenge, Error>) -> Void) {
    
    let url = endpoint == "prod" ?
        "https://attested.api.paytheory.com/challenge" :
        "https://\(endpoint).attested.api.paytheorystudy.com/challenge"
    
    let headers: HTTPHeaders = [
        "X-API-Key": apiKey,
        "Content-Type": "application/json"
    ]
    
    AF.request(url, headers: headers).validate().responseJSON { response in
        handleResponse(response: response, completion: completion)
    }
}

func postIdempotency(body: Attestation,
                     apiKey: String,
                     endpoint: String,
                     completion: @escaping (Result<IdempotencyResponse, Error>) -> Void) {
    
    let url = endpoint == "prod" ?
        "https://attested.api.paytheory.com/idempotency" :
        "https://\(endpoint).attested.api.paytheorystudy.com/idempotency"
    
    let headers: HTTPHeaders = [
        "X-API-Key": apiKey,
        "Content-Type": "application/json"
    ]
    
    AF.request(url, method: .post, parameters: body, encoder: JSONParameterEncoder.default,
               headers: headers).validate().responseJSON { response in
        handleResponse(response: response, completion: completion)
}
}

func postPayment(body: [String: Any],
                 apiKey: String,
                 endpoint: String,
                 completion: @escaping (Result<[String: AnyObject], Error>) -> Void) {

    let url = endpoint == "prod" ?
        "https://attested.api.paytheory.com/payment" :
        "https://\(endpoint).attested.api.paytheorystudy.com/payment"
    
    let headers: HTTPHeaders = [
        "X-API-Key": apiKey,
        "Content-Type": "application/json"
    ]

    AF.request(url, method: .post, parameters: body, encoding: JSONEncoding.default,
               headers: headers).validate().responseJSON { response in
        handleMapResponse(response: response, completion: completion)
}
}

class WebSocket: NSObject, URLSessionWebSocketDelegate {
    
    private let ptToken: String
    private let attestation: String
    private let transaction: Transaction
    
    public init(ptToken: String, attestation: String, transaction: Transaction) {
        self.ptToken = ptToken
        self.attestation = attestation
        self.transaction = transaction
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Web Socket did connect")
        receive(socket: webSocketTask, transaction: transaction)
        let hostToken: [String: Any] = [
            "ptToken": ptToken,
            "origin": "native",
            "timing": Date().millisecondsSince1970,
            "attestation": attestation
        ]
        
        sendMessage(socket: webSocketTask, action: HOST_TOKEN, messageBody: hostToken, transaction: transaction)
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Web Socket did disconnect")
    }
}

func close(socket: URLSessionWebSocketTask) {
  let reason = "Closing connection".data(using: .utf8)
    socket.cancel(with: .normalClosure, reason: reason)
}


func receive(socket: URLSessionWebSocketTask, transaction: Transaction) {
  socket.receive { result in
    switch result {
    case .success(let message):
      switch message {
      case .data(let data):
        print("Data received \(data)")
      case .string(let text):
        onMessage(response: text, transaction: transaction, socket: socket)
      default:
        print("recieved unknown response type")
      }
    case .failure(let error):
        print("Error when receiving \(error)")
    }
    receive(socket: socket, transaction: transaction)
  }
}

func sendMessage(socket: URLSessionWebSocketTask, action: String, messageBody: [String: Any], transaction: Transaction) {
    var message: [String: Any] = [
        "action": action
    ]
    if action == HOST_TOKEN {
        message["encoded"] = stringify(jsonDictionary: messageBody).data(using: .utf8)!.base64EncodedString()
    } else {
        let secretKey = transaction.keyPair.secretKey
        let strigifiedMessage = stringify(jsonDictionary: messageBody).bytes
        
        let encryptedMessage: Bytes =
            transaction.sodium.box.seal(message: strigifiedMessage,
                            recipientPublicKey: transaction.publicKey,
                            senderSecretKey: secretKey)!
        
        message["encoded"] = convertBytesToString(bytes: encryptedMessage)
        message["sessionKey"] = transaction.sessionKey
        message["publicKey"] = convertBytesToString(bytes: transaction.keyPair.publicKey)
    }
    
    transaction.lastMessage = stringify(jsonDictionary: message)
    socket.send(.string(stringify(jsonDictionary: message))) { error in
      if let error = error {
        print("Error when sending a message \(error)")
      }
    }
}

func onMessage(response: String, transaction: Transaction, socket: URLSessionWebSocketTask) {
    if let dictionary = convertStringToDictionary(text: response) {
        
        if let hostToken = dictionary["hostToken"] {
            DispatchQueue.main.async {
                transaction.hostToken = hostToken as? String ?? ""
            }
            transaction.sessionKey = dictionary["sessionKey"] as? String ?? ""
            let key = dictionary["publicKey"] as? String ?? ""
            transaction.publicKey = convertStringToByte(string: key)
            
        } else if let instrument = dictionary["pt-instrument"] {
            transaction.ptInstrument = instrument as? String ?? ""
            sendMessage(socket: socket, action: IDEMPOTENCY, messageBody: transaction.createIdempotencyBody()!, transaction: transaction)
            
        } else if let _ = dictionary["payment-token"] {
            transaction.paymentToken = dictionary
            if transaction.feeMode == .SURCHARGE {
                sendMessage(socket: socket, action: TRANSFER, messageBody: transaction.createTransferBody()!, transaction: transaction)
            } else {
                transaction.buttonCompletion!(.success(transaction.createTokenizationResponse()!))
            }
            
        } else if let _ = dictionary["state"] {
            transaction.transferToken = dictionary
            if transaction.feeMode == .SURCHARGE {
                transaction.buttonCompletion!(.success(transaction.createCompletionResponse()!))
                transaction.resetTransaction()
            } else {
                transaction.captureCompletion!(.success(transaction.createCompletionResponse()!))
                transaction.resetTransaction()
            }
            
        } else if let error = dictionary["error"] {
            print(error)
            
        } else if let serverError = dictionary["message"] {
            if serverError as? String ?? "" == "Internal server error" {
                if let message = transaction.lastMessage {
                    socket.send(.string(message)) { error in
                      if let error = error {
                        print("Error when sending a message \(error)")
                      }
                    }
                }
            }
        }
    } else {
        print("Could not convert the response to a Dictionary")
    }
}
