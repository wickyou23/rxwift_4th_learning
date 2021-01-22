//
//  ActivityTrendingViewController.swift
//  RxSwift-chapter-8
//
//  Created by Apple on 12/10/20.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import RxSwiftExt

//Challenge 8:

class ActivityTrendingViewController: UITableViewController {
    fileprivate let topTrendingUrl = "https://api.github.com/search/repositories?q=language:swift&per_page=5"
    fileprivate let repos = BehaviorRelay<[Repo]>(value: [])
    fileprivate let events = BehaviorRelay<[Int: [Event]]>(value: [:])
    fileprivate let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl = UIRefreshControl()
        let refreshControl = self.refreshControl!
        
        refreshControl.backgroundColor = UIColor(white: 0.98, alpha: 1.0)
        refreshControl.tintColor = UIColor.darkGray
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        self.refresh()
    }
    
    deinit {
        debugPrint("ActivityTrendingViewController deinit ===========")
    }
    
    @objc func refresh() {
        DispatchQueue.global(qos: .background).async {
            self.fetchTopTrendingRepo()
        }
    }
    
    func fetchTopTrendingRepo() {
        let response = Observable.from([self.topTrendingUrl])
            .map({ URL(string: $0) })
            .unwrap()
            .map({ URLRequest(url: $0) })
            .flatMap({ URLSession.shared.rx.json(request: $0) })
            .share(replay: 1)
        
        response
            .map { data -> [Repo] in
                guard let mainDict = data as? [String: Any],
                      let items = mainDict["items"] as? [[String: Any]],
                      let jsData = try? JSONSerialization.data(withJSONObject: items, options: [])
                else { return [] }
                
                let decoder = JSONDecoder()
                return (try? decoder.decode([Repo].self, from: jsData)) ?? []
            }
            .filter({ !$0.isEmpty })
            .subscribe(onNext: {
                [weak self] (repos) in
                self?.processRepos(repos)
            })
            .disposed(by: self.bag)
    }
    
    func fetchEvents() {
        let response = Observable.from(self.repos.value.compactMap({ "https://api.github.com/repos/\($0.repoName)/events?per_page=5" }))
            .map { (urlStr) -> URLRequest? in
                guard let url = URL(string: urlStr) else { return nil }
                return URLRequest(url: url)
            }
            .unwrap()
            .flatMap({ URLSession.shared.rx.response(request: $0) })
            .share(replay: 1)
        
        response
            .filter { res, _ -> Bool in
                return 200..<300 ~= res.statusCode
            }
            .map { _, data -> [Event] in
                let decoder = JSONDecoder()
                return (try? decoder.decode([Event].self, from: data)) ?? []
            }
            .filter({ !$0.isEmpty })
            .subscribe(onNext: {
                [weak self] (events) in
                guard let self = self else { return }
                self.processEvents(events)
            }, onCompleted: {
                DispatchQueue.main.async {
                    [weak self] in
                    guard let self = self else { return }
                    self.tableView.reloadData()
                    self.refreshControl?.endRefreshing()
                }
            })
            .disposed(by: self.bag)
    }
    
    func processRepos(_ newRepos: [Repo]) {
        self.repos.accept(newRepos)
        self.fetchEvents()
        DispatchQueue.main.async {
            [weak self] in
            guard let self = self else { return }
            self.tableView.reloadData()
        }
    }
    
    func processEvents(_ newEvents: [Event]) {
        var value = self.events.value
        newEvents.forEach({
            if var evItems = value[$0.repoId] {
                evItems.append($0)
                value[$0.repoId] = evItems
            }
            else {
                value[$0.repoId] = [$0]
            }
        })
        
        self.events.accept(value)
    }
    
    //MARK: - TableView
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.repos.value.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let repo = self.repos.value[section]
        return repo.name
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let repo = self.repos.value[section]
        return self.events.value[repo.id]?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        let repo = self.repos.value[indexPath.section]
        guard let event = self.events.value[repo.id]?[indexPath.row] else {
            return cell
        }
        
        cell.textLabel?.text = event.actorName
        cell.detailTextLabel?.text = event.repoName + ", " + event.action.replacingOccurrences(of: "Event", with: "").lowercased()
        cell.imageView?.kf.setImage(with: event.imageUrl, placeholder: UIImage(named: "blank-avatar"))
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
}
