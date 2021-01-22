//
//  EOEnvelope.swift
//  RxSwift-OutPlanet
//
//  Created by Apple on 12/28/20.
//

import Foundation

struct EOEnvelope<T: Decodable>: Decodable {
    
    let content: T
    
    fileprivate enum EnvelopeKey: String, CodingKey {
        case categories = "categories"
        case events = "events"
    }
    
    init(from decoder: Decoder) throws {
        guard let contentId = decoder.userInfo[.contentCodingKey] as? String else {
            throw EOError.decodeJSONError
        }
        
        let jsDecoder = try decoder.container(keyedBy: EnvelopeKey.self)
        if contentId == "categories" {
            self.content = try jsDecoder.decode(T.self, forKey: .categories)
        }
        else {
            self.content = try jsDecoder.decode(T.self, forKey: .events)
        }
    }
}
