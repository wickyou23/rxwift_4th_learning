//
//  ViewController.swift
//  RxSwift-Wundercast
//
//  Created by Apple on 1/12/21.
//

import UIKit
import RxSwift
import RxCocoa
import RxKingfisher
import CoreLocation
import MapKit

class ViewController: UIViewController {
    @IBOutlet var searchCityName: UITextField!
    @IBOutlet var tempLabel: UILabel!
    @IBOutlet var humidityLabel: UILabel!
    @IBOutlet var iconLabel: UILabel!
    @IBOutlet var cityNameLabel: UILabel!
    @IBOutlet var iconImg: UIImageView!
    
    //C12 - Challenge:
    @IBOutlet var switchTemp: UISwitch!
    @IBOutlet var switchTitle: UILabel!
    
    //Chapter 13:
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var mapButton: UIButton!
    @IBOutlet var geoLocationButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    let bag = DisposeBag()
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        style()
        
        //MARK: - using Subscribe
        
//        self.C12_usingSubscribeData()
        
        //MARK: - using BindingData
        
//        self.C12_usingBindingData()
        
        //MARK: - using DriveData
        
//        self.C12_usingDriveData()
        
        //MARK: - Chapter 13
        
//        self.C13_usingDriveData()
        
//        self.geoLocationButton.rx.tap
//            .subscribe(onNext: { [weak self] in
//                guard let self = self else { return }
//                self.locationManager.requestWhenInUseAuthorization()
//                self.locationManager.startUpdatingLocation()
//            })
//            .disposed(by: self.bag)
//
//        self.locationManager.rx.didUpdateLocations
//            .subscribe(onNext: {
//                locations in
//            })
//            .disposed(by: self.bag)
        
//        self.C13_usingNewAuthCurrentLocation()
        
        self.C13_usingMapView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        Appearance.applyBottomLine(to: searchCityName)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Style
    
    private func style() {
        view.backgroundColor = UIColor.aztec
        searchCityName.attributedPlaceholder = NSAttributedString(string: "City's Name",
                                                                  attributes: [.foregroundColor: UIColor.textGrey])
        searchCityName.textColor = UIColor.ufoGreen
        tempLabel.textColor = UIColor.cream
        humidityLabel.textColor = UIColor.cream
        iconLabel.textColor = UIColor.cream
        cityNameLabel.textColor = UIColor.cream
        self.switchTitle.text = self.switchTemp.isOn ? "°C to °F:" : "°F to °C:"
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let overlay = overlay as? ApiController.Weather.Overlay else {
            return MKOverlayRenderer()
        }
        
        return ApiController.Weather.OverlayView(overlay: overlay,
                                                 overlayIconURL: overlay.icon)
    }
}
