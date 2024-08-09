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

import Foundation

enum NetworkError: Error {
    case transportError(Error)
    case serverError(statusCode: Int)
    case noData
    case decodingError
}

func makeRequest(request: URLRequest) async throws -> [String: AnyObject] {
    let config = URLSessionConfiguration.default
    config.allowsExpensiveNetworkAccess = false
    config.allowsConstrainedNetworkAccess = false
    config.waitsForConnectivity = true
    config.requestCachePolicy = .reloadIgnoringLocalCacheData

    let session = URLSession(configuration: config)

    let (data, response) = try await session.data(for: request)

    if let response = response as? HTTPURLResponse, !(200...299).contains(response.statusCode) {
        throw NetworkError.serverError(statusCode: response.statusCode)
    }

    do {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: AnyObject]
        return json!
    } catch {
        throw NetworkError.decodingError
    }
}

func getToken(apiKey: String, environment: String, stage: String, sessionKey: String) async throws -> [String: AnyObject] {
    guard let url = URL(string: "https://\(environment).\(stage).com/pt-token-service/") else {
        debugPrint("Url for host token cannot be decided")
        throw ConnectionError.hostTokenCallFailed
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    do {
        return try await makeRequest(request: request)
    } catch {
        throw ConnectionError.hostTokenCallFailed
    }
}

