//
//  BannerAdView.swift
//  Kashat
//
//  Created for AdMob Integration
//

import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        
        // Test Ad Unit ID
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        bannerView.rootViewController = viewController
        
        viewController.view.addSubview(bannerView)
        
        // Constraints to keep banner centered or filling the width
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        if let view = viewController.view {
            NSLayoutConstraint.activate([
                bannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                bannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        }
        
        bannerView.load(GADRequest())
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
