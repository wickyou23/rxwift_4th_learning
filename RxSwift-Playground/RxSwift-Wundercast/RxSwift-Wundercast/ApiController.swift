/// Copyright (c) 2020 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import RxSwift
import RxCocoa
import CoreLocation
import MapKit
import Kingfisher

class ApiController {
    struct Weather: Decodable {
        let cityName: String
        let temperature: Int
        let humidity: Int
        let icon: String
        let coordinate: CLLocationCoordinate2D
        
        static let empty = Weather(
            cityName: "Unknown",
            temperature: -1000,
            humidity: 0,
            icon: iconNameToChar(icon: "e"),
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0)
        )
        
        init(cityName: String,
             temperature: Int,
             humidity: Int,
             icon: String,
             coordinate: CLLocationCoordinate2D) {
            self.cityName = cityName
            self.temperature = temperature
            self.humidity = humidity
            self.icon = icon
            self.coordinate = coordinate
        }
        
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            cityName = try values.decode(String.self, forKey: .cityName)
            let info = try values.decode([AdditionalInfo].self, forKey: .weather)
            icon = iconNameToChar(icon: info.first?.icon ?? "")
            
            let mainInfo = try values.nestedContainer(keyedBy: MainKeys.self, forKey: .main)
            temperature = Int(try mainInfo.decode(Double.self, forKey: .temp))
            humidity = try mainInfo.decode(Int.self, forKey: .humidity)
            let coordinate = try values.decode(Coordinate.self, forKey: .coordinate)
            self.coordinate = CLLocationCoordinate2D(latitude: coordinate.lat, longitude: coordinate.lon)
        }
        
        enum CodingKeys: String, CodingKey {
            case cityName = "name"
            case main
            case weather
            case coordinate = "coord"
        }
        
        enum MainKeys: String, CodingKey {
            case temp
            case humidity
        }
        
        private struct AdditionalInfo: Decodable {
            let id: Int
            let main: String
            let description: String
            let icon: String
        }
        
        private struct Coordinate: Decodable {
          let lat: CLLocationDegrees
          let lon: CLLocationDegrees
        }
    }
    
    /// The shared instance
    static var shared = ApiController()
    
    /// The api key to communicate with openweathermap.org
    /// Create you own on https://home.openweathermap.org/users/sign_up
    private let apiKey = "cc687d877461d86bd291b4396a3c79d3"
    
    /// API base URL
    let baseURL = URL(string: "http://api.openweathermap.org/data/2.5")!
    
    //Challenge:
    var isCelsius = true
    
    init() {
        Logging.URLRequests = { request in
            return true
        }
    }
    
    // MARK: - Api Calls
    func currentWeather(for city: String) -> Observable<Weather> {
        buildRequest(pathComponent: "weather", params: [("q", city)])
            .map { data in
                try JSONDecoder().decode(Weather.self, from: data)
            }
        
        //        return Observable.just(
        //            Weather(
        //                cityName: city,
        //                temperature: 20,
        //                humidity: 90,
        //                icon: iconNameToChar(icon: "01d")
        //            )
        //        )
    }
    
    func currentWeather(at coordinate: CLLocationCoordinate2D) -> Observable<Weather> {
        buildRequest(pathComponent: "weather",
                     params: [("lat", "\(coordinate.latitude)"),
                              ("lon", "\(coordinate.longitude)")])
            .map { data in
                try JSONDecoder().decode(Weather.self, from: data)
            }
    }
    
    // MARK: - Private Methods
    
    /**
     * Private method to build a request with RxCocoa
     */
    private func buildRequest(method: String = "GET", pathComponent: String, params: [(String, String)]) -> Observable<Data> {
        let url = baseURL.appendingPathComponent(pathComponent)
        var request = URLRequest(url: url)
        let keyQueryItem = URLQueryItem(name: "appid", value: apiKey)
        let unitsQueryItem = URLQueryItem(name: "units", value: (isCelsius) ? "metric" : "imperial")
        let urlComponents = NSURLComponents(url: url, resolvingAgainstBaseURL: true)!
        
        if method == "GET" {
            var queryItems = params.map { URLQueryItem(name: $0.0, value: $0.1) }
            queryItems.append(keyQueryItem)
            queryItems.append(unitsQueryItem)
            urlComponents.queryItems = queryItems
        } else {
            urlComponents.queryItems = [keyQueryItem, unitsQueryItem]
            
            let jsonData = try! JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
            request.httpBody = jsonData
        }
        
        request.url = urlComponents.url!
        request.httpMethod = method
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared
        
        return session.rx.data(request: request)
    }
    
}

/**
 * Maps an icon information from the API to a local char
 * Source: http://openweathermap.org/weather-conditions
 */
func iconNameToChar(icon: String) -> String {
    switch icon {
    case "01d":
        return "http://openweathermap.org/img/wn/01d@2x.png"
    case "01n":
        return "http://openweathermap.org/img/wn/01n@2x.png"
    case "02d":
        return "http://openweathermap.org/img/wn/02d@2x.png"
    case "02n":
        return "http://openweathermap.org/img/wn/02n@2x.png"
    case "03d", "03n":
        return "http://openweathermap.org/img/wn/03d@2x.png"
    case "04d", "04n":
        return "http://openweathermap.org/img/wn/04d@2x.png"
    case "09d", "09n":
        return "http://openweathermap.org/img/wn/09d@2x.png"
    case "10d", "10n":
        return "http://openweathermap.org/img/wn/10d@2x.png"
    case "11d", "11n":
        return "http://openweathermap.org/img/wn/11d@2x.png"
    case "13d", "13n":
        return "http://openweathermap.org/img/wn/13d@2x.png"
    case "50d", "50n":
        return "http://openweathermap.org/img/wn/50d@2x.png"
    default:
        return ""
    }
}

private func imageFromText(text: String, font: UIFont) -> UIImage {
    let size = text.size(withAttributes: [NSAttributedString.Key.font: font])
    
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    text.draw(at: CGPoint(x: 0, y:0), withAttributes: [NSAttributedString.Key.font: font])
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return image ?? UIImage()
}

extension ApiController.Weather {
    func overlay() -> Overlay {
        let coordinates: [CLLocationCoordinate2D] = [
            CLLocationCoordinate2D(latitude: self.coordinate.latitude - 0.25,
                                   longitude: self.coordinate.longitude - 0.25),
            CLLocationCoordinate2D(latitude: self.coordinate.latitude + 0.25,
                                   longitude: self.coordinate.longitude + 0.25)
        ]
        
        let points = coordinates.map { MKMapPoint($0) }
        let rects = points.map { MKMapRect(origin: $0, size: MKMapSize(width: 0, height: 0)) }
        let mapRectUnion: (MKMapRect, MKMapRect) -> MKMapRect = { $0.union($1) }
        let fittingRect = rects.reduce(MKMapRect.null, mapRectUnion)
        return Overlay(icon: self.icon, coordinate: self.coordinate, boundingMapRect: fittingRect)
    }
    
    class Overlay: NSObject, MKOverlay {
        var coordinate: CLLocationCoordinate2D
        var boundingMapRect: MKMapRect
        let icon: String
        
        init(icon: String, coordinate: CLLocationCoordinate2D, boundingMapRect: MKMapRect) {
            self.coordinate = coordinate
            self.boundingMapRect = boundingMapRect
            self.icon = icon
        }
    }
    
    class OverlayView: MKOverlayRenderer {
        var overlayIconURL: String
        var crTask: DownloadTask?
        var imageDownloaded: CGImage?
        
        fileprivate var imageDowloadDone = false
        
        init(overlay: MKOverlay, overlayIconURL: String) {
            self.overlayIconURL = overlayIconURL
            super.init(overlay: overlay)
        }
        
        override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
            self.downloadWeatherImage()
            guard let imageReference = self.imageDownloaded else {
                return
            }

            let theMapRect = self.overlay.boundingMapRect
            let theRect = self.rect(for: theMapRect)
            context.draw(imageReference, in: theRect)
        }
        
        fileprivate func downloadWeatherImage() {
            guard self.imageDowloadDone == false && self.crTask == nil else { return }
            self.crTask = KingfisherManager.shared.retrieveImage(with: URL(string: self.overlayIconURL)!) {
                [weak self] (rs) in
                guard let self = self else { return }
                switch rs {
                case .success(let rsImg):
                    self.imageDownloaded = rsImg.image.cgImage
                    self.setNeedsDisplay()
                case.failure(_):
                    break
                }
            }
            
            if self.crTask == nil {
                self.imageDowloadDone = true
            }
        }
    }
}
