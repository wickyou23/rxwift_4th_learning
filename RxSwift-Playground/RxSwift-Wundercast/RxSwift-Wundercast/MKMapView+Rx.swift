//
//  MKMapView+Rx.swift
//  RxSwift-Wundercast
//
//  Created by Apple on 1/20/21.
//

import Foundation
import RxSwift
import RxCocoa
import MapKit

extension MKMapView: HasDelegate {}

class RxMKMapViewDelegateProxy: DelegateProxy<MKMapView, MKMapViewDelegate>, DelegateProxyType, MKMapViewDelegate {
    weak private(set) var mapView: MKMapView?
    
    init(mapView: ParentObject) {
        self.mapView = mapView
        super.init(parentObject: mapView,
                   delegateProxy: RxMKMapViewDelegateProxy.self)
    }
    
    static func registerKnownImplementations() {
        self.register(make: {
            RxMKMapViewDelegateProxy(mapView: $0)
        })
    }
}

extension Reactive where Base: MKMapView {
    var delegate: DelegateProxy<MKMapView, MKMapViewDelegate> {
        RxMKMapViewDelegateProxy.proxy(for: self.base)
    }
    
    func setDelegate(_ delegate: MKMapViewDelegate) -> Disposable {
        RxMKMapViewDelegateProxy
            .installForwardDelegate(delegate,
                                    retainDelegate: false,
                                    onProxyForObject: self.base)
    }
    
    var overlay: Binder<MKOverlay> {
        return Binder(self.base) {
            mapView, overlay in
            mapView.removeOverlays(mapView.overlays)
            mapView.addOverlay(overlay)
        }
    }
    
    var regionDidChangeAnimated: ControlEvent<Bool> {
        let source = delegate
            .methodInvoked(#selector(MKMapViewDelegate.mapView(_:regionDidChangeAnimated:)))
            .map({
                parameters in
                return (parameters[1] as? Bool) ?? false
            })
        
        return ControlEvent(events: source)
    }
}
