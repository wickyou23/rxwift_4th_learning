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

import UIKit
import RxSwift
import RxCocoa
import Kingfisher

func cachedFileURL(_ fileName: String) -> URL {
    return FileManager.default
        .urls(for: .cachesDirectory, in: .allDomainsMask)
        .first!
        .appendingPathComponent(fileName)
}

class ActivityController: UITableViewController {
    
    let repo = "ReactiveX/RxSwift"
    
    fileprivate let events = BehaviorRelay<[Event]>(value: [])
    fileprivate let lastModified = BehaviorRelay<String?>(value: nil)
    fileprivate let bag = DisposeBag()
    
    fileprivate let modifiedFileURL = cachedFileURL("modified.txt")
    fileprivate lazy var eventsFileURL = cachedFileURL("events.plist")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = repo
        
        let rightBarButton = UIBarButtonItem(title: "Trending", style: .plain, target: self, action: #selector(self.gotoTopTrending))
        self.navigationItem.rightBarButtonItem = rightBarButton
        
        self.refreshControl = UIRefreshControl()
        let refreshControl = self.refreshControl!
        
        refreshControl.backgroundColor = UIColor(white: 0.98, alpha: 1.0)
        refreshControl.tintColor = UIColor.darkGray
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        let decoder = JSONDecoder()
        if let eventsData = try? Data(contentsOf: self.eventsFileURL),
           let eventList = try? decoder.decode([Event].self, from: eventsData) {
            self.events.accept(eventList)
        }
        
        if let modifiedStr = try? String(contentsOf: self.modifiedFileURL, encoding: .utf8) {
            self.lastModified.accept(modifiedStr)
        }
        
        self.refresh()
    }
    
    @objc func refresh() {
        DispatchQueue.global(qos: .background).async {
            self.fetchEvents(repo: self.repo)
        }
    }
    
    func fetchEvents(repo: String) {
        let response = Observable.from([self.repo])
            .map({ URL(string: "https://api.github.com/repos/\($0)/events")! })
            .map({
                [weak self] (urlStr) in
                var req = URLRequest(url: urlStr)
                if let modified = self?.lastModified.value {
                    req.addValue(modified, forHTTPHeaderField: "Last-Modified")
                }
                
                return req
            })
            .flatMap({ URLSession.shared.rx.response(request: $0) }) //Call Api
            .share(replay: 1)
        
        //First Subscriber for Events
        response
            .filter { response, _ -> Bool in //Get reponse from server
                return 200..<300 ~= response.statusCode
            }
            .map { _, data -> [Event] in
                let decoder = JSONDecoder()
                let events = try? decoder.decode([Event].self, from: data)
                return events ?? []
            }
            .filter({ !$0.isEmpty })
            .subscribe { [weak self] (event) in
                self?.processEvents(event)
            }
            .disposed(by: self.bag)
        
        //Second Subscriber for Last-Modified
        response
            .filter { response, _ -> Bool in
                return 200..<400 ~= response.statusCode
            }
            .flatMap { response, _ -> Observable<String> in
                guard let vl = response.allHeaderFields["Last-Modified"] as? String else {
                    return Observable.empty()
                }
                
                return Observable.just(vl)
            }
            .subscribe(onNext: {
                [weak self] (last) in
                guard let self = self else { return }
                self.lastModified.accept(last)
                try? last.write(to: self.modifiedFileURL, atomically: true, encoding: .utf8)
            })
            .disposed(by: self.bag)
    }
    
    func processEvents(_ newEvents: [Event]) {
        var updateEvents = newEvents + self.events.value
        if updateEvents.count > 50 {
            updateEvents = [Event](updateEvents.prefix(50))
        }
        
        self.events.accept(updateEvents)
        DispatchQueue.main.async {
            [weak self] in
            self?.refreshControl?.endRefreshing()
            self?.tableView.reloadData()
        }
        
        let encoder = JSONEncoder()
        if let eventsData = try? encoder.encode(updateEvents) {
            try? eventsData.write(to: self.eventsFileURL, options: .atomicWrite)
        }
    }
    
    //MARK: - For Challenge
    @objc func gotoTopTrending() {
        guard let vc = self.storyboard?.instantiateViewController(identifier: "ActivityTrendingViewController") as? ActivityTrendingViewController else { return }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //MARK: - Table Data Source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.events.value.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = self.events.value[indexPath.item]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.textLabel?.text = event.actorName
        cell.detailTextLabel?.text = event.repoName + ", " + event.action.replacingOccurrences(of: "Event", with: "").lowercased()
        cell.imageView?.kf.setImage(with: event.imageUrl, placeholder: UIImage(named: "blank-avatar"))
        return cell
    }
}
