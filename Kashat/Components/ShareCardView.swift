//
//  ShareCardView.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 31/01/2026.
//

import SwiftUI

struct ShareCardView: View {
    let spot: CampingSpot
    var weatherTemp: String = ""
    var loadedImage: UIImage? // NEW: Accept pre-loaded image
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background Image
            if let loadedImage = loadedImage {
                Image(uiImage: loadedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 330, height: 500)
                    .clipped()
            } else if let imageURL = spot.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.black
                }
                .frame(width: 330, height: 500)
                .clipped()
            } else {
                Rectangle()
                    .fill(Color.blue.gradient)
                    .frame(width: 330, height: 500)
            }
            
            // Gradient Overlay
            LinearGradient(
                colors: [.black, .black.opacity(0.4), .clear],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(width: 330, height: 500)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("KASHAT")
                        .font(.custom("Futura", size: 14))
                        .kerning(4)
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Spacer()
                    
                    if !weatherTemp.isEmpty && weatherTemp != "--" {
                        HStack(spacing: 4) {
                            Image(systemName: "cloud.sun.fill")
                                .symbolRenderingMode(.multicolor)
                            Text(weatherTemp)
                                .fontWeight(.bold)
                        }
                        .font(.caption)
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                }
                
                Spacer()
                
                Text(spot.type)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                
                Text(spot.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                    Text(spot.location)
                    Spacer()
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text(String(format: "%.1f", spot.rating))
                            .fontWeight(.bold)
                    }
                }
                .foregroundStyle(.white.opacity(0.9))
            }
            .padding(24)
            .frame(width: 330, height: 500)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .drawingGroup() // Important for rendering off-screen
    }
}
