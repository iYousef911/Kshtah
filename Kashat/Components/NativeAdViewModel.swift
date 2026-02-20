//
//  NativeAdViewModel.swift
//  Kashat
//
//  Created for AdMob Native Advanced Integration
//

import SwiftUI
internal import Combine
import GoogleMobileAds

class NativeAdViewModel: NSObject, ObservableObject, NativeAdLoaderDelegate {
    @Published var nativeAds: [NativeAd] = []
    @Published var isLoading: Bool = false
    private var adLoader: AdLoader?
    
    // Set your ad unit ID here
    let adUnitID = "ca-app-pub-3298644446787962/9290943604"

    func refreshAd() {
        guard !isLoading else { return }
        isLoading = true
        nativeAds = [] // Clear previous ads
        
        let multipleAdsOptions = MultipleAdsAdLoaderOptions()
        multipleAdsOptions.numberOfAds = 5 // Fetch up to 5 ads
        
        // Use UIApplication to find rootViewController
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            isLoading = false
            return
        }

        adLoader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: rootViewController,
            adTypes: [.native],
            options: [multipleAdsOptions]
        )
        adLoader?.delegate = self
        adLoader?.load(Request())
    }

    // MARK: - NativeAdLoaderDelegate
    
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        DispatchQueue.main.async {
            self.nativeAds.append(nativeAd)
            self.isLoading = false
            print("Successfully loaded a native ad. Total: \(self.nativeAds.count)")
        }
    }
    
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            print("Failed to receive ad: \(error.localizedDescription)")
        }
    }
}
