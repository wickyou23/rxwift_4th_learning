//
//  ViewController.swift
//  RxSwift-OutPlanet
//
//  Created by Apple on 12/28/20.
//

import UIKit
import RxSwift
import RxCocoa

class CategoriesViewController: UITableViewController {
    
    //MARK: - Challenge 2
    fileprivate let downloadView = DownloadView.csView
    
    fileprivate let categories = BehaviorRelay<[EOCategory]>(value: [])
    fileprivate let bag = DisposeBag()
    fileprivate lazy var indicator: UIActivityIndicatorView = {
        let indi = UIActivityIndicatorView(style: .medium)
        indi.tintColor = .gray
        indi.hidesWhenStopped = true
        return indi
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.title = "Categories"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.indicator)
        
        //MARK: - Challenge 2
        self.view.addSubview(self.downloadView)
        
        self.categories
            .asObservable()
            .subscribe(onNext: { _ in
                DispatchQueue.main.async {
                    [weak self] in
                    self?.tableView.reloadData()
                }
            })
            .disposed(by: self.bag)
        
        self.startDownload()
    }
    
    func startDownload() {
        self.indicator.startAnimating()
        let eoCategories = EONET.categories
        let downloadedEvent = eoCategories
            .flatMap {
                categories in
                return Observable.from(categories.map {
                    category in
                    EONET.events(forLast: 360, category: category)
                })
            }
            .merge(maxConcurrent: 2)
        
        let updatedCategories = eoCategories
            .flatMap { categories in
                downloadedEvent.scan((0, categories)) { (tup, events) in
                    return (tup.0 + 1, tup.1.map { category in
                        let eventsForCategory = EONET.filteredEvents(events: events, forCategory: category)
                        if !eventsForCategory.isEmpty {
                            var cat = category
                            cat.events = cat.events + eventsForCategory
                            return cat
                        }
                        return category
                    })
                }
            }
            //MARK: - Challenge 1
            .do(onCompleted: {
                DispatchQueue.main.async {
                    [weak self] in
                    guard let self = self else { return }
                    self.indicator.stopAnimating()
                    self.downloadView.isHidden = true
                }
            })
            //MARK: - Challenge 2
            .do(onNext: {
                tup in
                DispatchQueue.main.async {
                    [weak self] in
                    guard let self = self else { return }
                    let progress = Float(tup.0) / Float(tup.1.count)
                    self.downloadView.progress.progress = progress
                    let percent = Int(progress * 100)
                    self.downloadView.titleLabel.text = "Download: \(percent)%"
                }
            })
        
        eoCategories
            .concat(updatedCategories.map(\.1))
            .bind(to: categories)
            .disposed(by: self.bag)
    }
    
    //MARK: - UITableViewDelegate, UITableViewDatasource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.categories.value.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell")!
        
        let category = self.categories.value[indexPath.row]
        cell.detailTextLabel?.text = category.description
        cell.textLabel?.text = "\(category.name) (\(category.events.count))"
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let ct = self.categories.value[indexPath.item]
        tableView.deselectRow(at: indexPath, animated: true)
        
        let evVC = self.storyboard?.instantiateViewController(identifier: "EventsViewController") as! EventsViewController
        evVC.events.accept(ct.events)
        self.navigationController?.pushViewController(evVC, animated: true)
    }
}

