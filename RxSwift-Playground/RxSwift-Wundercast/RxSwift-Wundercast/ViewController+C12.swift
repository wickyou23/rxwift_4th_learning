//
//  ViewController+C12.swift
//  RxSwift-Wundercast
//
//  Created by Apple on 1/20/21.
//

import Foundation
import RxSwift
import RxCocoa

extension ViewController {
    func C12_usingBindingData() {
        let search = self.searchCityName.rx.text.orEmpty
            .filter({ !$0.isEmpty })
            .flatMapLatest({
                data in
                ApiController.shared
                    .currentWeather(for: data)
                    .catchErrorJustReturn(.empty)
            })
            .share(replay: 1)
            .observeOn(MainScheduler.instance)
        
        search.map({ "\($0.temperature)°C" })
            .bind(to: self.tempLabel.rx.text)
            .disposed(by: self.bag)
        
        search
            .filter({ !$0.icon.isEmpty })
            .map({ URL(string: $0.icon) })
            .bind(to: self.iconImg.kf.rx.image())
            .disposed(by: self.bag)
        
        search.map({ "\($0.humidity)%" })
            .bind(to: self.humidityLabel.rx.text)
            .disposed(by: self.bag)
        
        search.map(\.cityName)
            .bind(to: self.cityNameLabel.rx.text)
            .disposed(by: self.bag)
    }
    
    func C12_usingSubscribeData() {
        self.searchCityName.rx.text.orEmpty
            .filter({ !$0.isEmpty })
            .flatMap({
                text in
                ApiController.shared
                    .currentWeather(for: text)
                    .catchErrorJustReturn(.empty)
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                [weak self] data in
                guard let self = self else { return }
                self.tempLabel.text = "\(data.temperature)°C"
                self.iconLabel.text = data.icon
                self.humidityLabel.text = "\(data.humidity)%"
                self.cityNameLabel.text = data.cityName
            })
            .disposed(by: self.bag)
    }
    
    //MARK: - Chapter 12 and Challenge
    
    func C12_usingDriveData() {
        //Challenge:
        let tempSwitchObs = self.switchTemp.rx
            .controlEvent(.valueChanged)
            .asObservable()
            .share(replay: 1)
        let searchObs = self.searchCityName.rx
            .controlEvent(.editingDidEndOnExit)
            .asObservable()
            .share(replay: 1)
        
        tempSwitchObs.subscribe(onNext: {
            [weak self] in
            guard let self = self else { return }
            ApiController.shared.isCelsius = self.switchTemp.isOn
            self.switchTitle.text = self.switchTemp.isOn ? "°C to °F:" : "°F to °C:"
        })
        .disposed(by: self.bag)
        
        let search = Observable
            .merge(searchObs, tempSwitchObs)
            .map({ self.searchCityName.text ?? "" })
            .filter({ !$0.isEmpty })
            .flatMapLatest({
                data in
                ApiController.shared
                    .currentWeather(for: data)
                    .catchErrorJustReturn(.empty)
            })
            .asDriver(onErrorJustReturn: .empty)
        
        search.map({ "\($0.temperature)\(self.switchTemp.isOn ? "°C" : "°F")" })
            .drive(self.tempLabel.rx.text)
            .disposed(by: self.bag)
        
        search.filter({ !$0.icon.isEmpty })
            .map({ URL(string: $0.icon) })
            .drive(self.iconImg.kf.rx.image())
            .disposed(by: self.bag)
        
        search.map({ "\($0.humidity)%" })
            .drive(self.humidityLabel.rx.text)
            .disposed(by: self.bag)
        
        search.map(\.cityName)
            .drive(self.cityNameLabel.rx.text)
            .disposed(by: self.bag)
    }
}
