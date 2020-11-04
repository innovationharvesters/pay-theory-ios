//
//  PayTheory.swift
//  PayTheory
//
//  Created by Austin Zani on 11/3/20.
//

import Foundation

public class Identity: ObservableObject, Codable {
    @Published var phone: String?
    @Published var first_name: String?
    @Published var last_name: String?
    @Published var email: String?
    @Published var personal_address = Address()
    
    enum CodingKeys: CodingKey {
        case phone, first_name, last_name, email, personal_address
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(phone, forKey: .phone)
        try container.encode(first_name, forKey: .first_name)
        try container.encode(last_name, forKey: .last_name)
        try container.encode(email, forKey: .email)
        try container.encode(personal_address, forKey: .personal_address)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        phone = try container.decodeIfPresent(String.self, forKey: .phone) ?? nil
        first_name = try container.decodeIfPresent(String.self, forKey: .first_name) ?? nil
        last_name = try container.decodeIfPresent(String.self, forKey: .last_name) ?? nil
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? nil
        personal_address = try container.decode(Address.self, forKey: .personal_address)
    }
    
    init() {}
    
    
}

class IdentityBody: Codable {
    var entity: Identity
    
    init(entity: Identity) {
        self.entity = entity
    }
}

class IdentityResponse: Codable {
    var id: String
    var application: String
    var entity: Identity
    var tags: Tags?
    var created_at: String
    var updated_at: String
    var links: ResponseLinks
    
    enum CodingKeys: String, CodingKey {
        case id
        case application
        case entity
        case tags
        case created_at
        case updated_at
        case links = "_links"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        application = try container.decode(String.self, forKey: .application)
        entity = try container.decode(Identity.self, forKey: .entity)
        created_at = try container.decode(String.self, forKey: .created_at)
        updated_at = try container.decode(String.self, forKey: .updated_at)
        links = try container.decode(ResponseLinks.self, forKey: .links)
        if let t = try? container.decode(Tags.self, forKey: .tags) {
            tags = t
        } else {
            tags = nil
        }
    }
}
