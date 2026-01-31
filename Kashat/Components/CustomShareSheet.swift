//
//  CustomShareSheet.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 31/01/2026.
//

import SwiftUI
import CoreLocation // Fix: Required for coordinate access

struct CustomShareSheet: View {
    let spot: CampingSpot
    let imageToShare: UIImage?
    var weatherTemp: String
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Drag Indicator
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 6)
                .padding(.top, 12)
            
            Text("مشاركة الكشتة ⛺️")
                .font(.headline)
                .padding(.bottom, 10)
            
            // Preview Card
            if let imageToShare = imageToShare {
                Image(uiImage: imageToShare)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 10)
            } else {
                // Fallback Preview
                ShareCardView(spot: spot, weatherTemp: weatherTemp)
                    .scaleEffect(0.6)
                    .frame(height: 300)
            }
            
            Divider()
            
            // Share Options
            HStack(spacing: 20) {
                // WhatsApp
                ShareButton(title: "WhatsApp", icon: "message.circle.fill", color: .green) {
                    shareToWhatsApp()
                }
                
                // Instagram (Image)
                ShareButton(title: "Instagram", icon: "camera.circle.fill", color: .purple) {
                    shareImage()
                }
                
                // Copy Link
                ShareButton(title: "نسخ الرابط", icon: "doc.on.doc.fill", color: .blue) {
                    copyLink()
                }
                
                // System Share (More)
                ShareButton(title: "المزيد", icon: "square.and.arrow.up.circle.fill", color: .gray) {
                    shareSystem()
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.bottom, 20)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Actions
    
    func shareToWhatsApp() {
        // WhatsApp URL Scheme
        // Text + Link
        let message = "شوف هالمكان الرهيب في كشتات: \(spot.name) ⛺️\n📍 \(spot.location)\n\nhttps://maps.google.com/?q=\(spot.coordinate.latitude),\(spot.coordinate.longitude)"
        
        let urlString = "whatsapp://send?text=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: urlString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // Fallback if WhatsApp not installed
                print("WhatsApp not installed")
            }
        }
    }
    
    func shareImage() {
        guard let image = imageToShare else { return }
        
        // Share Image via UIActivityViewController
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            // Find top controller to present
             var topController = rootVC
             while let presentedViewController = topController.presentedViewController {
                 topController = presentedViewController
             }
            topController.present(activityVC, animated: true)
        }
    }
    
    func copyLink() {
        let link = "https://maps.google.com/?q=\(spot.coordinate.latitude),\(spot.coordinate.longitude)"
        UIPasteboard.general.string = link
        dismiss()
    }
    
    func shareSystem() {
        guard let image = imageToShare else { return }
        let text = "شوف \(spot.name) في كشتات! ⛺️"
        let link = URL(string: "https://maps.google.com/?q=\(spot.coordinate.latitude),\(spot.coordinate.longitude)")!
        
        let activityVC = UIActivityViewController(activityItems: [text, image, link], applicationActivities: nil)
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
             var topController = rootVC
             while let presentedViewController = topController.presentedViewController {
                 topController = presentedViewController
             }
            topController.present(activityVC, animated: true)
        }
    }
}

struct ShareButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(color)
                    .padding(10)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
        }
    }
}
