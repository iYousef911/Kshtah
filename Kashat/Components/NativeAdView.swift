//
//  NativeAdView.swift
//  Kashat
//
//  Created for AdMob Native Advanced Integration
//

import SwiftUI
import GoogleMobileAds

struct AdMobNativeView: UIViewRepresentable {
    var nativeAd: NativeAd
    
    func makeUIView(context: Context) -> NativeAdView {
        let nativeAdView = NativeAdView()
        nativeAdView.backgroundColor = .clear
        
        // --- 1. Background (Glassmorphism matching GlassSpotCard) ---
        let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.layer.cornerRadius = 24
        backgroundView.layer.masksToBounds = true
        nativeAdView.addSubview(backgroundView)
        
        // --- Setup Ad Components ---
        
        // 1. Icon View (Right Side)
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.layer.cornerRadius = 16
        iconView.layer.masksToBounds = true
        iconView.contentMode = .scaleAspectFill
        // Placeholder background for slow loading
        iconView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        nativeAdView.addSubview(iconView)
        nativeAdView.iconView = iconView
        
        // Content Stack (Left Side) - We use a container view to simulate VStack
        let contentStack = UIStackView()
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.alignment = .trailing // Right-aligned Arabic text
        contentStack.distribution = .equalSpacing
        contentStack.spacing = 4
        nativeAdView.addSubview(contentStack)
        
        // 2. Headline & Ad Badge Stack
        let titleStack = UIStackView()
        titleStack.axis = .horizontal
        titleStack.alignment = .center
        titleStack.spacing = 4
        
        // 2a. Headline Label
        let headlineLabel = UILabel()
        headlineLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold) // .headline
        headlineLabel.textColor = .white
        headlineLabel.textAlignment = .right
        headlineLabel.numberOfLines = 1
        titleStack.addArrangedSubview(headlineLabel)
        nativeAdView.headlineView = headlineLabel
        
        // 2b. Advertiser Label (Ad Badge)
        let advertiserLabel = UILabel()
        advertiserLabel.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        advertiserLabel.textColor = UIColor.systemBackground
        advertiserLabel.backgroundColor = UIColor.systemYellow
        advertiserLabel.layer.cornerRadius = 4
        advertiserLabel.layer.masksToBounds = true
        advertiserLabel.textAlignment = .center
        advertiserLabel.text = " إعلان "
        titleStack.addArrangedSubview(advertiserLabel)
        nativeAdView.advertiserView = advertiserLabel
        
        contentStack.addArrangedSubview(titleStack)
        
        // 3. Body Label (Secondary Text)
        let bodyLabel = UILabel()
        bodyLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular) // .caption
        bodyLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        bodyLabel.textAlignment = .right
        bodyLabel.numberOfLines = 2
        contentStack.addArrangedSubview(bodyLabel)
        nativeAdView.bodyView = bodyLabel
        
        // 4. CTA Button (Matching rating/action area)
        let ctaButton = UIButton(type: .system)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
        ctaButton.setTitleColor(.white, for: .normal)
        ctaButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        ctaButton.layer.cornerRadius = 8
        ctaButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
        nativeAdView.addSubview(ctaButton)
        nativeAdView.callToActionView = ctaButton
        
        // --- Layout Constraints ---
        NSLayoutConstraint.activate([
            // Background
            backgroundView.topAnchor.constraint(equalTo: nativeAdView.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor),
            
            // Icon View (Right aligned, matches the AsyncImage in GlassSpotCard)
            iconView.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -16),
            iconView.centerYAnchor.constraint(equalTo: nativeAdView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 80),
            iconView.heightAnchor.constraint(equalToConstant: 80),
            
            // Content Stack (Text on the left of Icon)
            contentStack.trailingAnchor.constraint(equalTo: iconView.leadingAnchor, constant: -16),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: nativeAdView.leadingAnchor, constant: 16),
            contentStack.topAnchor.constraint(equalTo: iconView.topAnchor),
            
            // CTA Button (Bottom Left)
            ctaButton.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 16),
            ctaButton.bottomAnchor.constraint(equalTo: iconView.bottomAnchor),
            ctaButton.trailingAnchor.constraint(lessThanOrEqualTo: iconView.leadingAnchor, constant: -16)
        ])
        
        return nativeAdView
    }
    
    func updateUIView(_ uiView: NativeAdView, context: Context) {
        // Populate the data from nativeAd into the UI elements
        
        // 1. Icon
        if let icon = nativeAd.icon {
            (uiView.iconView as? UIImageView)?.image = icon.image
            uiView.iconView?.isHidden = false
        } else {
            uiView.iconView?.isHidden = true
        }
        
        // 2. Headline
        (uiView.headlineView as? UILabel)?.text = nativeAd.headline
        
        // 3. Body
        if let body = nativeAd.body {
            (uiView.bodyView as? UILabel)?.text = body
            uiView.bodyView?.isHidden = false
        } else {
            uiView.bodyView?.isHidden = true
        }
        
        // 4. CTA
        if let cta = nativeAd.callToAction {
            (uiView.callToActionView as? UIButton)?.setTitle(cta, for: .normal)
            uiView.callToActionView?.isHidden = false
        } else {
            uiView.callToActionView?.isHidden = true
        }
        
        // Assign the ad to the view to enable click/impression tracking
        uiView.nativeAd = nativeAd
    }
}
