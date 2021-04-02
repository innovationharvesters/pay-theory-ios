//
//  PayTheory.swift
//  PayTheory
//
//  Created by Austin Zani on 11/3/20.
//

import Foundation
import Alamofire
//import Sodium

enum ResponseError: String, Error {
    case noData = "There was no data in the repsonse"
    case canNotDecode = "Unable to decode the response"
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
