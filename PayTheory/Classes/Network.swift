//
//  PayTheory.swift
//  PayTheory
//
//  Created by Austin Zani on 11/3/20.
//

import Foundation
import Alamofire

enum ResponseError: String, Error {
    case NoData = "There was no data in the repsonse"
    case CanNotDecode = "Unable to decode the response"
}

class FinixError: Error {
    var errors: [[String: String]]
    
    init(errors: [[String: String]]) {
        self.errors = errors
    }
}

func convertStringToDictionary(text: String) -> [String:AnyObject]? {
    if let data = text.data(using: .utf8) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:AnyObject]
            return json
        } catch {
            print("Something went wrong")
        }
    }
    return nil
}

func handleResponse<T:Codable>(response: AFDataResponse<Any>, completion: @escaping (Result<T, Error>) -> Void) {
    debugPrint(response)
    guard response.error == nil else {
            print("Call failed")
            if let value = response.value as? [String: AnyObject] {
                      print(value)
                   }
        if let data = response.data {
            let json = String(data: data, encoding: String.Encoding.utf8)
            let errorArray = convertStringToDictionary(text: json!)?["_embedded"]?["errors"] as? [[String: Any]]
            if let errors = errorArray {
               var response :[[String: String]] = []
                for err in errors {
                    var x: [String: String] = [:]
                    x["code"] = err["code"] as? String
                    if err["code"] as? String == "INVALID_FIELD" {
                        x["message"] = "\(err["field"] as? String ?? ""): \(err["message"] as? String ?? "")"
                    } else {
                        x["message"] = err["message"] as? String ?? "Unable to read error message"
                    }
                    
                    response.append(x)
                }
                completion(.failure(FinixError(errors: response)))
                return
            }
        }
        completion(.failure(response.error!))
            return
            }
   guard let data = response.data else {
            print("No Data")
    completion(.failure(ResponseError.NoData))
            return
            }
    
    if let decodedResponse = try? JSONDecoder().decode(T.self, from: data) {
        print("Call successfull")
        completion(.success(decodedResponse))
       } else {
            print("Can't decode")
        completion(.failure(ResponseError.CanNotDecode))
       }
}

//class IdentityAPI {
//    
//    
//
//    let baseUrl = "https://finix.sandbox-payments-api.com/identities"
//    
//    func create(auth: String, identity: [String: Any], completion: @escaping (Result<IdentityResponse, Error>) -> Void) {
//    
//    let headers: HTTPHeaders = [
//        "Authorization": "Basic \(auth)",
//        "Content-Type": "application/vnd.json+api"
//    ]
//    
//        AF.request(baseUrl, method: .post, parameters: identity, encoding: JSONEncoding.default, headers: headers).validate().responseJSON { response in
//            handleResponse(response: response, completion: completion)
//    }
//    
//    }
//
//    func read(auth: String, id: String, completion: @escaping (Result<IdentityResponse, Error>) -> Void) {
//        
//        let url = "\(baseUrl)/\(id)"
//        let headers: HTTPHeaders = [
//            "Authorization": "Basic \(auth)",
//            "Content-Type": "application/vnd.json+api"
//        ]
//        
//        AF.request(url, headers: headers).validate().responseJSON { response in
//            handleResponse(response: response, completion: completion)
//        }
//    }
//    
//    func update(auth: String, id: String, identity: Buyer, completion: @escaping (Result<IdentityResponse, Error>) -> Void) {
//        let body = IdentityBody(entity: identity)
//        
//        let url = "\(baseUrl)/\(id)"
//        let headers: HTTPHeaders = [
//            "Authorization": "Basic \(auth)",
//            "Content-Type": "application/vnd.json+api"
//        ]
//        
//        AF.request(url, method: .put, parameters: body, encoder: JSONParameterEncoder.default, headers: headers).validate().responseJSON { response in
//            handleResponse(response: response, completion: completion)
//        }
//    }
//
//
//}
//
//class PaymentCardAPI {
//    let baseUrl = "https://finix.sandbox-payments-api.com/payment_instruments"
//    
//    
//    func create(auth: String, card: [String: Any], completion: @escaping (Result<PaymentCardResponse, Error>) -> Void) {
//    
//    let headers: HTTPHeaders = [
//        "Authorization": "Basic \(auth)",
//        "Content-Type": "application/vnd.json+api"
//    ]
//    
//    AF.request(baseUrl, method: .post, parameters: card, encoding: JSONEncoding.default, headers: headers).validate().responseJSON { response in
//        handleResponse(response: response, completion: completion)
//    }
//    
//
//    }
//
//    func read(auth: String, cardId: String, completion: @escaping (Result<PaymentCardResponse, Error>) -> Void) {
//        
//        let url = "\(baseUrl)/\(cardId)"
//        let headers: HTTPHeaders = [
//            .contentType("application/vnd.json+api"),
//            .authorization("Basic \(auth)")
//        ]
//        
//        AF.request(url, headers: headers).validate().responseJSON { response in
//            handleResponse(response: response, completion: completion)
//        }
//    }
//
//
//}
//
//class BankAccountAPI {
//    let baseUrl = "https://finix.sandbox-payments-api.com/payment_instruments"
//    
//    
//    func create(auth: String, bankAccount: BankAccount, completion: @escaping (Result<BankAccountResponse, Error>) -> Void) {
//    
//    let headers: HTTPHeaders = [
//        "Authorization": "Basic \(auth)",
//        "Content-Type": "application/vnd.json+api"
//    ]
//    
//    AF.request(baseUrl, method: .post, parameters: bankAccount, encoder: JSONParameterEncoder.default, headers: headers).validate().responseJSON { response in
//        handleResponse(response: response, completion: completion)
//    }
//    
//
//    }
//
//    func read(auth: String, bankId: String, completion: @escaping (Result<BankAccountResponse, Error>) -> Void) {
//        
//        let url = "\(baseUrl)/\(bankId)"
//        let headers: HTTPHeaders = [
//            .contentType("application/vnd.json+api"),
//            .authorization("Basic \(auth)")
//        ]
//        
//        AF.request(url, headers: headers).validate().responseJSON { response in
//            handleResponse(response: response, completion: completion)
//        }
//    }
//}
//
//class AuthorizationAPI {
//    let baseUrl = "https://finix.sandbox-payments-api.com/authorizations"
//    
//    
//    func create(auth: String, authorization: Parameters, completion: @escaping (Result<AuthorizationResponse, Error>) -> Void) {
//    
//    let headers: HTTPHeaders = [
//        "Authorization": "Basic \(auth)",
//        "Content-Type": "application/vnd.json+api"
//    ]
//    
//        AF.request(baseUrl, method: .post, parameters: authorization, encoding: JSONEncoding.default, headers: headers).validate().responseJSON { response in
//        handleResponse(response: response, completion: completion)
//    }
//    }
//    
//    func capture(auth: String, authorization: CaptureAuth, id: String, completion: @escaping (Result<AuthorizationResponse, Error>) -> Void) {
//    
//    let headers: HTTPHeaders = [
//        "Authorization": "Basic \(auth)",
//        "Content-Type": "application/vnd.json+api"
//    ]
//    
//    AF.request("\(baseUrl)/\(id)", method: .put, parameters: authorization, encoder: JSONParameterEncoder.default, headers: headers).validate().responseJSON { response in
//        handleResponse(response: response, completion: completion)
//    }
//    
//
//    }
//    
//    func void(auth: String, id: String, completion: @escaping (Result<AuthorizationResponse, Error>) -> Void) {
//        
//        class voidBody: Codable {
//            var void_me = true
//        }
//    
//    let headers: HTTPHeaders = [
//        "Authorization": "Basic \(auth)",
//        "Content-Type": "application/vnd.json+api"
//    ]
//    
//    AF.request("\(baseUrl)/\(id)", method: .put, parameters: voidBody(), encoder: JSONParameterEncoder.default, headers: headers).validate().responseJSON { response in
//        handleResponse(response: response, completion: completion)
//    }
//    
//
//    }
//}
let endpoints = ["https://dev.attested.api.paytheorystudy.com", "https://demo.attested.api.paytheorystudy.com", "https://attested.api.paytheorystudy.com"]


func getChallenge(apiKey: String, endpoint: Int, completion: @escaping (Result<Challenge, Error>) -> Void) {
    
    let url = "\(endpoints[endpoint])/challenge"
    let headers: HTTPHeaders = [
        "X-API-Key": apiKey,
        "Content-Type": "application/json"
    ]
    
    AF.request(url, headers: headers).validate().responseJSON { response in
        handleResponse(response: response, completion: completion)
    }
}

func postIdempotency(body: Attestation, apiKey: String, endpoint: Int, completion: @escaping (Result<IdempotencyResponse, Error>) -> Void) {
    
    let url = "\(endpoints[endpoint])/idempotency"
    let headers: HTTPHeaders = [
        "X-API-Key": apiKey,
        "Content-Type": "application/json"
    ]
    
    AF.request(url, method: .post, parameters: body, encoder: JSONParameterEncoder.default, headers: headers).validate().responseJSON { response in
        handleResponse(response: response, completion: completion)
}
}

func postPayment(body: [String: Any], apiKey: String, endpoint: Int, completion: @escaping (Result<[String: AnyObject], Error>) -> Void) {

    let url = "\(endpoints[endpoint])/payment"
    let headers: HTTPHeaders = [
        "X-API-Key": apiKey,
        "Content-Type": "application/json"
    ]

    AF.request(url, method: .post, parameters: body, encoding: JSONEncoding.default, headers: headers).validate().responseJSON { response in
        debugPrint(response)
        guard response.error == nil else {
                print("Call failed")
                if let value = response.value as? [String: AnyObject] {
                          print(value)
                       }
            if let data = response.data {
                let json = String(data: data, encoding: String.Encoding.utf8)
                let errorArray = convertStringToDictionary(text: json!)?["_embedded"]?["errors"] as? [[String: Any]]
                if let errors = errorArray {
                   var response :[[String: String]] = []
                    for err in errors {
                        var x: [String: String] = [:]
                        x["code"] = err["code"] as? String
                        if err["code"] as? String == "INVALID_FIELD" {
                            x["message"] = "\(err["field"] as? String ?? ""): \(err["message"] as? String ?? "")"
                        } else {
                            x["message"] = err["message"] as? String ?? "Unable to read error message"
                        }
                        
                        response.append(x)
                    }
                    completion(.failure(FinixError(errors: response)))
                    return
                }
            }
            completion(.failure(response.error!))
                return
                }
        
        if let value = response.value as? [String: AnyObject] {
            completion(.success(value))
                } else {
                print("Can't decode")
            completion(.failure(ResponseError.CanNotDecode))
           }
}
}
