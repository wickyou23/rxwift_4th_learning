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

struct EOEvent: Decodable {
    let id: String
    let title: String
    let description: String
    let link: URL?
    let closeDate: Date?
    let categories: [Int]
    let locations: [EOLocation]
    
    fileprivate enum EQEKey: String, CodingKey {
        case idKey = "id"
        case titleKey = "title"
        case descriptionKey = "description"
        case linkKey = "link"
        case closedKey = "closed"
        case categoriesKey = "categories"
        case locationsKey = "geometries"
    }
    
    fileprivate enum CategoryItemKey: String, CodingKey {
        case idKey = "id"
    }
    
    init(from decoder: Decoder) throws {
        do {
            let content = try decoder.container(keyedBy: EQEKey.self)
            self.id = try content.decode(String.self, forKey: .idKey)
            self.title = try content.decode(String.self, forKey: .titleKey)
            self.description = try content.decode(String.self, forKey: .descriptionKey)
            self.link = URL(string: try content.decode(String.self, forKey: .linkKey))
            self.closeDate = EONET.ISODateReader.date(from: (try? content.decode(String.self, forKey: .closedKey)) ?? "")
            
            let ct = try content.decode([[String: AnyDecodable]].self, forKey: .categoriesKey)
            self.categories = ct.compactMap({ dict -> Int? in
                return dict["id"]?.value as? Int
            })
            
            self.locations = try content.decode([EOLocation].self, forKey: .locationsKey)
        } catch {
            print(error.localizedDescription)
            throw error
        }
        
    }
    
    static func compareDates(lhs: EOEvent, rhs: EOEvent) -> Bool {
        switch (lhs.closeDate, rhs.closeDate) {
        case (nil, nil): return false
        case (nil, _): return true
        case (_, nil): return false
        case (let ldate, let rdate): return ldate! < rdate!
        }
    }
}
