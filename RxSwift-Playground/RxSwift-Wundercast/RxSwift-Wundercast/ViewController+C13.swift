//
//  ViewController+C13.swift
//  RxSwift-Wundercast
//
//  Created by Apple on 1/20/21.
//

import Foundation
import RxSwift
import RxCocoa
import CoreLocation

extension ViewController {
    func C13_usingDriveData() {
        let searchInput = self.searchCityName.rx
            .controlEvent(.editingDidEndOnExit)
            .map({ self.searchCityName.text ?? "" })
            .filter({ !$0.isEmpty })
        
        let search = searchInput
            .flatMapLatest({
                text in
                ApiController.shared
                    .currentWeather(for: text)
                    .catchErrorJustReturn(.empty)
            })
            .asDriver(onErrorJustReturn: .empty)
        
        let running = Observable.merge(
            searchInput.map({ _ in true }),
            search.map({ _ in false }).asObservable()
        )
        .startWith(true)
        .asDriver(onErrorJustReturn: false)
        
        running
            .skip(1)
            .drive(self.activityIndicator.rx.isAnimating)
            .disposed(by: self.bag)
        
        running
            .drive(tempLabel.rx.isHidden)
            .disposed(by: self.bag)
        
        running
            .drive(iconImg.rx.isHidden)
            .disposed(by: self.bag)
        
        running
            .drive(humidityLabel.rx.isHidden)
            .disposed(by: self.bag)
        
        running
            .drive(cityNameLabel.rx.isHidden)
            .disposed(by: self.bag)
        
        running
            .drive(switchTemp.rx.isHidden)
            .disposed(by: self.bag)
        
        running
            .drive(switchTitle.rx.isHidden)
            .disposed(by: self.bag)
    }
    
    func C13_usingNewAuthCurrentLocation() {
        let searchInput = self.searchCityName.rx
            .controlEvent(.editingDidEndOnExit)
            .map({ self.searchCityName.text ?? "" })
            .filter({ !$0.isEmpty })
        
        let geoSearch = self.geoLocationButton.rx.tap
            .flatMapLatest { _ in
                self.locationManager.rx.getCurrentLocation()
            }
            .flatMapLatest({
                ApiController.shared
                    .currentWeather(at: $0.coordinate)
                    .catchErrorJustReturn(.empty)
            })
        
        let textSearch = searchInput.flatMap { city in
            ApiController.shared
                .currentWeather(for: city)
                .catchErrorJustReturn(.empty)
        }
        
        
        // Binding Data
        let search = Observable
            .merge(geoSearch, textSearch)
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
        
        
        // Show/Hide UI
        let running = Observable
            .merge(
                searchInput.map({ _ in true }),
                geoLocationButton.rx.tap.map({ _ in true }),
                search.map({ _ in false }).asObservable()
            )
            .startWith(true)
            .asDriver(onErrorJustReturn: false)
        
        running
            .skip(1)
            .drive(self.activityIndicator.rx.isAnimating)
            .disposed(by: self.bag)
        
        running
            .drive(tempLabel.rx.isHidden)
            .disposed(by: self.bag)
        
        running
            .drive(iconImg.rx.isHidden)
            .disposed(by: self.bag)
        
        running
            .drive(humidityLabel.rx.isHidden)
            .disposed(by: self.bag)
        
        running
            .drive(cityNameLabel.rx.isHidden)
            .disposed(by: self.bag)
        
        running
            .drive(switchTemp.rx.isHidden)
            .disposed(by: self.bag)
        
        running
            .drive(switchTitle.rx.isHidden)
            .disposed(by: self.bag)
    }
    
    func C13_usingMapView() {
        self.mapButton.rx.tap
            .subscribe(onNext: {
                self.mapView.isHidden.toggle()
            })
            .disposed(by: self.bag)
        
        self.mapView.rx
            .setDelegate(self)
            .disposed(by: self.bag)
        
        
        let searchInput = self.searchCityName.rx
            .controlEvent(.editingDidEndOnExit)
            .map({ self.searchCityName.text ?? "" })
            .filter({ !$0.isEmpty })
        
        let textSearch = searchInput.flatMap { city in
            ApiController.shared
                .currentWeather(for: city)
                .catchErrorJustReturn(.empty)
        }
        
        let mapInput = mapView.rx.regionDidChangeAnimated
            .skip(1)
            .map({ _ in
                CLLocation(latitude: self.mapView.centerCoordinate.latitude,
                           longitude: self.mapView.centerCoordinate.longitude)
            })
        
        let geoInput = self.geoLocationButton.rx.tap
            .flatMapLatest { _ in
                self.locationManager.rx.getCurrentLocation()
            }
        
        let geoSearch = Observable
            .merge(geoInput, mapInput)
            .flatMapLatest({
                ApiController.shared
                    .currentWeather(at: $0.coordinate)
                    .catchErrorJustReturn(.empty)
            })
        
        
        //Binding Data
        let search = Observable
            .merge(geoSearch, textSearch)
            .asDriver(onErrorJustReturn: .empty)
        
        search
            .map({ $0.overlay() })
            .drive(self.mapView.rx.overlay)
            .disposed(by: self.bag)
        
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
        
        
        // Show/Hide UI
        let running = Observable
            .merge(
                searchInput.map({ _ in true }),
                geoInput.map({ _ in true }),
                mapInput.map({ _ in true }),
                search.map({ _ in false }).asObservable()
            )
            .startWith(true)
            .asDriver(onErrorJustReturn: false)
        
        running
            .skip(1)
            .drive(self.activityIndicator.rx.isAnimating)
            .disposed(by: self.bag)
        
        running
            .drive(tempLabel.rx.isHidden)
            .disposed(by: self.bag)
        
        running
            .drive(iconImg.rx.isHidden)
            .disposed(by: self.bag)
        
        running
            .drive(humidityLabel.rx.isHidden)
            .disposed(by: self.bag)
        
        running
            .drive(cityNameLabel.rx.isHidden)
            .disposed(by: self.bag)
        
        running
            .drive(switchTemp.rx.isHidden)
            .disposed(by: self.bag)
        
        running
            .drive(switchTitle.rx.isHidden)
            .disposed(by: self.bag)
    }
}
