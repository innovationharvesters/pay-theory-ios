//
//  PayTheory.swift
//  PayTheory
//
//  Created by Austin Zani on 11/3/20.
//

import Foundation
import Alamofire

enum ResponseError: String, Error {
    case noData = "There was no data in the repsonse"
    case canNotDecode = "Unable to decode the response"
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

let endpoints = [".attested.api.paytheorystudy.com",
                 "https://demo.attested.api.paytheorystudy.com",
                 "https://attested.api.paytheorystudy.com",
                 "https://test.attested.api.paytheorystudy.com"]

func getChallenge(apiKey: String,
                  endpoint: String,
                  completion: @escaping (Result<Challenge, Error>) -> Void) {
    
    let url = endpoint == "prod" ?
        "https://attested.api.paytheorystudy.com/challenge" :
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
        "https://attested.api.paytheorystudy.com/idempotency" :
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
        "https://attested.api.paytheorystudy.com/payment" :
        "https://\(endpoint).attested.api.paytheorystudy.com/payment"
    
    let headers: HTTPHeaders = [
        "X-API-Key": apiKey,
        "Content-Type": "application/json"
    ]

    AF.request(url, method: .post, parameters: body, encoding: JSONEncoding.default,
               headers: headers).validate().responseJSON { response in
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
                    completion(.failure(FailureResponse(type: errors["reason"] as? String ?? "Unknown Error")))
                    return
                }
            }
            completion(.failure(FailureResponse(type: response.error!.localizedDescription)))
                return
                }
        
        if let value = response.value as? [String: AnyObject] {
            completion(.success(value))
                } else {
                print("Can't decode")
                    completion(.failure(FailureResponse(type: ResponseError.canNotDecode.rawValue)))
           }
}
}
