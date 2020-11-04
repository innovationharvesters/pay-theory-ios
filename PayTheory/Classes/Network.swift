//
//  PayTheory.swift
//  PayTheory
//
//  Created by Austin Zani on 11/3/20.
//

import Foundation
import Alamofire
import AWSKMS

enum ResponseError: Error {
    case NoData
    case CanNotDecode
}

func handleResponse<T:Codable>(response: AFDataResponse<Any>, completion: @escaping (Result<T, Error>) -> Void) {
    guard response.error == nil else {
            print("Call failed")
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

class IdentityAPI {
    let baseUrl = "https://finix.sandbox-payments-api.com/identities"
    
    func create(auth: String, identity: Identity, completion: @escaping (Result<IdentityResponse, Error>) -> Void) {
    let body = IdentityBody(entity: identity)
    
    let headers: HTTPHeaders = [
        "Authorization": auth,
        "Content-Type": "application/vnd.json+api"
    ]
    
        AF.request(baseUrl, method: .post, parameters: body, encoder: JSONParameterEncoder.default, headers: headers).validate().responseJSON { response in
            handleResponse(response: response, completion: completion)
    }
    
    }

    func read(auth: String, id: String, completion: @escaping (Result<IdentityResponse, Error>) -> Void) {
        
        let url = "\(baseUrl)/\(id)"
        let headers: HTTPHeaders = [
            "Authorization": auth,
            "Content-Type": "application/vnd.json+api"
        ]
        
        AF.request(url, headers: headers).validate().responseJSON { response in
            handleResponse(response: response, completion: completion)
        }
    }
    
    func update(auth: String, id: String, identity: Identity, completion: @escaping (Result<IdentityResponse, Error>) -> Void) {
        let body = IdentityBody(entity: identity)
        
        let url = "\(baseUrl)/\(id)"
        let headers: HTTPHeaders = [
            "Authorization": auth,
            "Content-Type": "application/vnd.json+api"
        ]
        
        AF.request(url, method: .put, parameters: body, encoder: JSONParameterEncoder.default, headers: headers).validate().responseJSON { response in
            handleResponse(response: response, completion: completion)
        }
    }


}

class PaymentCardAPI {
    let baseUrl = "https://finix.sandbox-payments-api.com/payment_instruments"
    
    
    func create(auth: String, card: PaymentCard, completion: @escaping (Result<PaymentCardResponse, Error>) -> Void) {
    
    let headers: HTTPHeaders = [
        "Authorization": auth,
        "Content-Type": "application/vnd.json+api"
    ]
    
    AF.request(baseUrl, method: .post, parameters: card, encoder: JSONParameterEncoder.default, headers: headers).validate().responseJSON { response in
        debugPrint(response)
        handleResponse(response: response, completion: completion)
    }
    

    }

    func read(auth: String, cardId: String, completion: @escaping (Result<PaymentCardResponse, Error>) -> Void) {
        
        let url = "\(baseUrl)/\(cardId)"
        let headers: HTTPHeaders = [
            .contentType("application/vnd.json+api"),
            .authorization(auth)
        ]
        
        AF.request(url, headers: headers).validate().responseJSON { response in
            handleResponse(response: response, completion: completion)
        }
    }


}

class BankAccountAPI {
    let baseUrl = "https://finix.sandbox-payments-api.com/payment_instruments"
    
    
    func create(auth: String, bankAccount: BankAccount, completion: @escaping (Result<BankAccountResponse, Error>) -> Void) {
    
    let headers: HTTPHeaders = [
        "Authorization": auth,
        "Content-Type": "application/vnd.json+api"
    ]
    
    AF.request(baseUrl, method: .post, parameters: bankAccount, encoder: JSONParameterEncoder.default, headers: headers).validate().responseJSON { response in
        debugPrint(response)
        handleResponse(response: response, completion: completion)
    }
    

    }

    func read(auth: String, bankId: String, completion: @escaping (Result<BankAccountResponse, Error>) -> Void) {
        
        let url = "\(baseUrl)/\(bankId)"
        let headers: HTTPHeaders = [
            .contentType("application/vnd.json+api"),
            .authorization(auth)
        ]
        
        AF.request(url, headers: headers).validate().responseJSON { response in
            debugPrint(response)
            handleResponse(response: response, completion: completion)
        }
    }
}

class AuthorizationAPI {
    let baseUrl = "https://finix.sandbox-payments-api.com/authorizations"
    
    
    func create(auth: String, authorization: Authorization, completion: @escaping (Result<AuthorizationResponse, Error>) -> Void) {
    
    let headers: HTTPHeaders = [
        "Authorization": auth,
        "Content-Type": "application/vnd.json+api"
    ]
    
    AF.request(baseUrl, method: .post, parameters: authorization, encoder: JSONParameterEncoder.default, headers: headers).validate().responseJSON { response in
        debugPrint(response)
        handleResponse(response: response, completion: completion)
    }
    }
    
    func capture(auth: String, authorization: CaptureAuth, id: String, completion: @escaping (Result<AuthorizationResponse, Error>) -> Void) {
    
    let headers: HTTPHeaders = [
        "Authorization": auth,
        "Content-Type": "application/vnd.json+api"
    ]
    
    AF.request("\(baseUrl)/\(id)", method: .put, parameters: authorization, encoder: JSONParameterEncoder.default, headers: headers).validate().responseJSON { response in
        debugPrint(response)
        handleResponse(response: response, completion: completion)
    }
    

    }
    
    func void(auth: String, id: String, completion: @escaping (Result<AuthorizationResponse, Error>) -> Void) {
        
        class voidBody: Codable {
            var void_me = true
        }
    
    let headers: HTTPHeaders = [
        "Authorization": auth,
        "Content-Type": "application/vnd.json+api"
    ]
    
    AF.request("\(baseUrl)/\(id)", method: .put, parameters: voidBody(), encoder: JSONParameterEncoder.default, headers: headers).validate().responseJSON { response in
        debugPrint(response)
        handleResponse(response: response, completion: completion)
    }
    

    }
}
