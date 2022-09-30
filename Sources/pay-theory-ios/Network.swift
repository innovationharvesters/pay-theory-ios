//
//  PayTheory.swift
//  PayTheory
//
//  Created by Austin Zani on 11/3/20.
//

import Network
import Foundation

class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "Monitor")
    
    var isActive = false
    var isExpensive = false
    var isConstrained = false
    var connectionType = NWInterface.InterfaceType.other
    
    init() {
        monitor.pathUpdateHandler = { path in
            self.isActive = path.status == .satisfied
            self.isExpensive = path.isExpensive
            self.isConstrained = path.isConstrained

            let connectionTypes: [NWInterface.InterfaceType] = [.cellular, .wifi, .wiredEthernet]
            self.connectionType = connectionTypes.first(where: path.usesInterfaceType) ?? .other

            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }

        monitor.start(queue: queue)
    }
}

enum NetworkError: Error {
    case transportError(Error)
    case serverError(statusCode: Int)
    case noData
    case decodingError
    case encodingError
}

func makeRequest(request: URLRequest,completion: @escaping (Result<[String: AnyObject], NetworkError>) -> Void) {
    let config = URLSessionConfiguration.default
    config.allowsExpensiveNetworkAccess = false
    config.allowsConstrainedNetworkAccess = false
    config.waitsForConnectivity = true
    config.requestCachePolicy = .reloadIgnoringLocalCacheData

    let session = URLSession(configuration: config)

    session.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(.transportError(error)))
            return
        }
        
        if let response = response as? HTTPURLResponse, !(200...299).contains(response.statusCode) {
            completion(.failure(.serverError(statusCode: response.statusCode)))
            return
        }
        
        guard let data = data else {
            completion(.failure(.noData))
            return
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String : AnyObject]
            completion(.success(json!))
        } catch {
            completion(.failure(.decodingError))
        }
        
    }.resume()
}

func getToken(apiKey: String,
              environment: String,
              stage: String,
              completion: @escaping (Result<[String: AnyObject], NetworkError>) -> Void) {
    
    guard let url = URL(string:"https://\(environment).\(stage).com/pt-token-service/") else {
        completion(.failure(.decodingError))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    makeRequest(request: request, completion: completion)
}
