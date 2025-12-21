//
//  CompassManager.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 23/11/2025.
//


import Foundation
import CoreLocation
internal import Combine

class CompassManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var heading: Double = 0.0
    @Published var qiblaDirection: Double = 0.0
    
    // Makkah Coordinates
    let kaabaLat = 21.422487
    let kaabaLong = 39.826206
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        // Start tracking
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            // Smooth animation by taking the shortest path
            self.heading = -newHeading.magneticHeading
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        calculateQiblaAngle(userLocation: location)
    }
    
    private func calculateQiblaAngle(userLocation: CLLocation) {
        let userLat = userLocation.coordinate.latitude * .pi / 180.0
        let userLong = userLocation.coordinate.longitude * .pi / 180.0
        let destLat = kaabaLat * .pi / 180.0
        let destLong = kaabaLong * .pi / 180.0
        
        let dLong = destLong - userLong
        
        let y = sin(dLong) * cos(destLat)
        let x = cos(userLat) * sin(destLat) - sin(userLat) * cos(destLat) * cos(dLong)
        let radiansBearing = atan2(y, x)
        
        var degrees = radiansBearing * 180.0 / .pi
        if degrees < 0 { degrees += 360.0 }
        
        DispatchQueue.main.async {
            self.qiblaDirection = degrees
        }
    }
}
