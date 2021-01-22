//
//  EventsViewController.swift
//  RxSwift-OutPlanet
//
//  Created by Apple on 12/28/20.
//

import UIKit
import RxSwift
import RxCocoa

class EventsViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var daysLabel: UILabel!
    
    let events = BehaviorRelay<[EOEvent]>(value: [])
    let days = BehaviorRelay<Int>(value: 360)
    let filterEvents = BehaviorRelay<[EOEvent]>(value: [])
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Observable.combineLatest(days, events) { (d, e) -> [EOEvent] in
            let maxInterval = TimeInterval(d * 24 * 3600)
            return e.filter { (event) -> Bool in
                if let date = event.closeDate {
                    return abs(date.timeIntervalSinceNow) < maxInterval
                }
                
                return true
            }
        }
        .bind(to: filterEvents)
        .disposed(by: self.bag)
        
        self.filterEvents
            .asObservable()
            .subscribe(onNext: {
                [weak self] _ in
                self?.tableView.reloadData()
            })
            .disposed(by: self.bag)
        
        self.days
            .asObservable()
            .subscribe {
                [weak self] (days) in
                self?.daysLabel.text = "Last \(days) days"
            }
            .disposed(by: self.bag)
    }
    
    @IBAction func sliderActionWithSlider(_ sender: Any) {
        self.days.accept(Int(self.slider.value))
    }
}

extension EventsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filterEvents.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell") as! EventCell
        let event = self.filterEvents.value[indexPath.item]
        cell.configure(event: event)
        return cell
    }
}
