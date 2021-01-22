//
//  Repo.swift
//  RxSwift-GitFeed
//
//  Created by Apple on 12/15/20.
//

import Foundation

class Repo: Codable {
    var id: Int
    var name: String
    var url: String
    var description: String
    var repoName: String
    
    enum RepoKey: String, CodingKey {
        case id = "id"
        case name = "name"
        case url = "html_url"
        case description = "description"
        case repoName = "full_name"
    }
    
    required init(from decoder: Decoder) throws {
        let repo = try decoder.container(keyedBy: RepoKey.self)
        self.id = try repo.decode(Int.self, forKey: .id)
        self.name = try repo.decode(String.self, forKey: .name)
        self.url = try repo.decode(String.self, forKey: .url)
        self.description = try repo.decode(String.self, forKey: .description)
        self.repoName = try repo.decode(String.self, forKey: .repoName)
    }
}
