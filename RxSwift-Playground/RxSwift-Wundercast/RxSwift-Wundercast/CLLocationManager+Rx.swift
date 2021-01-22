//
//  CCLocationManager+Rx.swift
//  RxSwift-Wundercast
//
//  Created by Apple on 1/13/21.
//

import Foundation
import RxSwift
import RxCocoa
import CoreLocation

extension CLLocationManager: HasDelegate {}

class RxCLLocationManagerDelegateProxy:
    DelegateProxy<CLLocationManager, CLLocationManagerDelegate>,
    DelegateProxyType, CLLocationManagerDelegate {
    
    weak private(set) var locationManager: CLLocationManager?
    
    init(locationManager: ParentObject) {
        self.locationManager = locationManager
        super.init(parentObject: locationManager,
                   delegateProxy: RxCLLocationManagerDelegateProxy.self)
    }
    
    static func registerKnownImplementations() {
        register {
            RxCLLocationManagerDelegateProxy(locationManager: $0)
        }
    }
}

extension Reactive where Base: CLLocationManager {
    var delegate: DelegateProxy<CLLocationManager, CLLocationManagerDelegate> {
        RxCLLocationManagerDelegateProxy.proxy(for: base)
    }
    
    var didUpdateLocations: Observable<[CLLocation]> {
        delegate
            .methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didUpdateLocations:)))
            .map({
                parameter in
                parameter[1] as! [CLLocation]
            })
    }
    
    var authorizationStatus: Observable<CLAuthorizationStatus> {
        delegate
            .methodInvoked(#selector(CLLocationManagerDelegate.locationManagerDidChangeAuthorization(_:)))
            .map({
                parameter in
                CLAuthorizationStatus(rawValue: parameter[1] as! Int32)!
            })
            .startWith(CLLocationManager().authorizationStatus)
    }
    
    func getCurrentLocation() -> Observable<CLLocation> {
        let location = authorizationStatus
            .filter({ $0 == .authorizedAlways || $0 == .authorizedWhenInUse })
            .flatMap { (_) in
                self.didUpdateLocations.compactMap(\.first)
            }
            .take(1)
            .do(onDispose: {
                [weak base] in
                base?.stopUpdatingLocation()
            })
        
        base.requestWhenInUseAuthorization()
        base.startUpdatingLocation()
        return location
    }
}
