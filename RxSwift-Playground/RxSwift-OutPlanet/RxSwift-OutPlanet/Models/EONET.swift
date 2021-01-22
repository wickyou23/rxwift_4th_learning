/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */


import Foundation
import RxSwift
import RxCocoa

extension CodingUserInfoKey {
    static let contentCodingKey = CodingUserInfoKey(rawValue: "ContentCodingKey")!
}

class EONET {
    static let API = "https://eonet.sci.gsfc.nasa.gov/api/v2.1"
    static let categoriesEndpoint = "/categories"
    static let eventsEndpoint = "/events"
    
    static var ISODateReader: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
        return formatter
    }()
    
    static var categories: Observable<[EOCategory]> = {
        let request: Observable<[EOCategory]> = EONET.request(endpoint: categoriesEndpoint, contentIdentifier: "categories")
        return request
            .map { rs in rs.sorted(by: { $0.name < $1.name }) }
            .catchErrorJustReturn([])
            .share(replay: 1, scope: .forever)
    }()
    
    static func getJsonDecoder(contentIdentifier: String) -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.userInfo[.contentCodingKey] = contentIdentifier
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
    
    static func request<T: Decodable>(endpoint: String, query: [String: Any] = [:], contentIdentifier: String) -> Observable<T> {
        do {
            guard let url = URL(string: API)?.appendingPathComponent(endpoint),
                  var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw EOError.invalidURL(endpoint)
            }
            
            components.queryItems = try query.compactMap({
                key, val -> URLQueryItem in
                guard let v = val as? CustomStringConvertible else {
                    throw EOError.invalidParameter(key, val)
                }
                
                return URLQueryItem(name: key, value: v.description)
            })
            
            guard let finalUrl = components.url else {
                throw EOError.invalidURL(endpoint)
            }
            
            let request = URLRequest(url: finalUrl)
            return URLSession.shared.rx
                .response(request: request)
                .map { res, data -> T in
                    let decoder = self.getJsonDecoder(contentIdentifier: contentIdentifier)
                    let rs = try decoder.decode(EOEnvelope<T>.self, from: data)
                    return rs.content
                }
        }
        catch {
            print(error.localizedDescription)
            return Observable.empty()
        }
    }
    
    static func events(forLast days: Int = 360, category: EOCategory) -> Observable<[EOEvent]> {
        let openEvents = self.events(forLast: days, closed: false, endpoint: category.endpoint)
        let closeEvents = self.events(forLast: days, closed: true, endpoint: category.endpoint)
        return Observable.of(openEvents, closeEvents)
            .merge()
            .reduce([]) {
                running, new in
                return running + new
            }
    }
    
    private static func events(forLast days: Int, closed: Bool, endpoint: String) -> Observable<[EOEvent]> {
        let query: [String: Any] = [
            "days": days,
            "status": (closed ? "closed" : "open")
        ]
        
        let request: Observable<[EOEvent]> = EONET.request(endpoint: endpoint, query: query, contentIdentifier: "events")
        return request.catchErrorJustReturn([])
    }
    
    static func filteredEvents(events: [EOEvent], forCategory category: EOCategory) -> [EOEvent] {
        return events.filter({
            $0.categories.contains(category.id)
        })
    }
}
