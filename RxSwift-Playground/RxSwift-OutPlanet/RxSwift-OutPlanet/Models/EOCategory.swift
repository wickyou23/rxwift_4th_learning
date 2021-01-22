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

struct EOCategory: Equatable, Decodable {
    let id: Int
    let name: String
    let description: String
    let endpoint: String
    var events = [EOEvent]()
    
    //MARK: - Json Key Enum
    
    fileprivate enum CategoryKey: String, CodingKey {
        case idKey = "id"
        case titleKey = "title"
        case description  = "description"
    }
    
    init(from decoder: Decoder) throws {
        let content = try decoder.container(keyedBy: CategoryKey.self)
        self.id = try content.decode(Int.self, forKey: .idKey)
        self.name = try content.decode(String.self, forKey: .titleKey)
        self.description = try content.decode(String.self, forKey: .description)
        self.endpoint = "\(EONET.categoriesEndpoint)/\(id)"
    }
    
    // MARK: - Equatable
    
    static func ==(lhs: EOCategory, rhs: EOCategory) -> Bool {
        return lhs.id == rhs.id
    }
}
