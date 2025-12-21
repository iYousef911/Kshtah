//
//  SpotDetailView.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 22/11/2025.
//


import SwiftUI
import SwiftUI
import MapKit
import WeatherKit // NEW
import PhotosUI // NEW: Image Picker

struct SpotDetailView: View {
    let spot: CampingSpot
    @EnvironmentObject var store: AppDataStore
    @Environment(\.dismiss) var dismiss
    @State private var newCommentText = ""
    @State private var newRating = 5
    
    @State private var showMapSelection = false // NEW

    // Weather State
    @State private var temperature: String = "--"
    @State private var windSpeed: String = "--"
    @State private var rainChance: String = "--"
    
    // Image Picking State
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    
    var body: some View {
        ZStack {
            LiquidBackgroundView()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Header Image & Rating (UPDATED)
                    ZStack(alignment: .bottomLeading) {
                        if let url = spot.imageURL, let validURL = URL(string: url) {
                            AsyncImage(url: validURL) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Color.white.opacity(0.1)
                            }
                            .frame(height: 250)
                            .clipped()
                        } else {
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 250)
                                .overlay(
                                    Image(systemName: "tent.fill")
                                        .font(.system(size: 80))
                                        .foregroundStyle(Color.white.opacity(0.2))
                                )
                        }
                        
                        LinearGradient(colors: [.black.opacity(0.8), .clear], startPoint: .bottom, endPoint: .top)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(spot.type).font(.caption).padding(6).background(Color.blue).clipShape(Capsule()).foregroundStyle(Color.white)
                            Text(spot.name).font(.largeTitle).fontWeight(.bold).foregroundStyle(Color.white)
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                Text(spot.location)
                                Spacer()
                                Image(systemName: "star.fill").foregroundStyle(Color.yellow)
                                Text("\(spot.rating, specifier: "%.1f")")
                                Text("(\(spot.numberOfRatings))")
                                    .font(.caption)
                                    .foregroundStyle(Color.white.opacity(0.7))
                            }
                            .foregroundStyle(Color.white.opacity(0.9))
                        }
                        .padding()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // 2. Weather Widget (Real Data)
                    HStack(spacing: 20) {
                        WeatherColumn(icon: "sun.max.fill", value: temperature, label: "الحرارة")
                        Divider().background(Color.white.opacity(0.3))
                        WeatherColumn(icon: "wind", value: windSpeed, label: "الرياح")
                        Divider().background(Color.white.opacity(0.3))
                        WeatherColumn(icon: "drop.fill", value: rainChance, label: "المطر")
                    }
                    .padding().glassEffect(GlassStyle.regular, in: Capsule()).padding(.horizontal)
                    
                    // 3. Actions
                    HStack(spacing: 15) {
                        Button(action: {
                            showMapSelection = true
                        }) {
                            Label("اتجاهات", systemImage: "arrow.triangle.turn.up.right.circle.fill").font(.headline).padding().frame(maxWidth: .infinity).background(Color.blue).clipShape(Capsule()).foregroundStyle(Color.white)
                        }
                        .confirmationDialog("اختر التطبيق", isPresented: $showMapSelection, titleVisibility: .visible) {
                            Button("Apple Maps") { openMap(app: .apple) }
                            
                            if canOpen(app: .google) {
                                Button("Google Maps") { openMap(app: .google) }
                            }
                            
                            if canOpen(app: .waze) {
                                Button("Waze") { openMap(app: .waze) }
                            }
                            
                            Button("إلغاء", role: .cancel) { }
                        }
                        
                        ShareLink(item: URL(string: "https://maps.google.com/?q=\(spot.coordinate.latitude),\(spot.coordinate.longitude)")!, subject: Text("كشتة في \(spot.name)"), message: Text("شوف هالمكان الرهيب في كشتات: \(spot.name) ⛺️\n📍 \(spot.location)")) {
                            Image(systemName: "square.and.arrow.up").padding().background(Color.white.opacity(0.1)).clipShape(Circle()).foregroundStyle(Color.white)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 4. Community Comments & Reviews
                    VStack(alignment: .leading, spacing: 15) {
                        Text("آراء الكشاتة").font(.headline).foregroundStyle(Color.white).padding(.horizontal)
                        
                        VStack(spacing: 10) {
                            HStack {
                                Text("تقييمك:").font(.caption).foregroundStyle(Color.white.opacity(0.7))
                                ForEach(1...5, id: \.self) { star in Image(systemName: star <= newRating ? "star.fill" : "star").foregroundStyle(Color.yellow).onTapGesture { withAnimation { newRating = star } } }
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            // Image Preview
                            if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    
                                    Button(action: {
                                        selectedItem = nil
                                        selectedImageData = nil
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(Color.red)
                                            .background(Color.white.clipShape(Circle()))
                                    }
                                    .offset(x: 5, y: -5)
                                }
                                .padding(.horizontal, 12)
                            }

                            HStack {
                                // Photo Picker Button
                                PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                                    Image(systemName: "camera.fill")
                                        .foregroundStyle(Color.blue)
                                        .padding(10)
                                        .background(Color.white.opacity(0.1))
                                        .clipShape(Circle())
                                }
                                .onChange(of: selectedItem) { _, newValue in
                                    Task {
                                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                            selectedImageData = data
                                        }
                                    }
                                }
                                
                                TextField("اكتب تجربتك...", text: $newCommentText).foregroundStyle(Color.white).padding(10).background(Color.white.opacity(0.1)).clipShape(Capsule())
                                
                                Button(action: { 
                                    if !newCommentText.isEmpty { 
                                        store.addComment(spotId: spot.id, text: newCommentText, rating: newRating, imageData: selectedImageData)
                                        newCommentText = ""
                                        newRating = 5
                                        selectedItem = nil
                                        selectedImageData = nil
                                    } 
                                }) { 
                                    Image(systemName: "paperplane.fill").foregroundStyle(Color.blue).padding(10).background(Color.white.opacity(0.1)).clipShape(Circle()) 
                                }
                            }
                        }
                        .padding().glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 20)).padding(.horizontal)
                        
                        if let comments = store.comments[spot.id], !comments.isEmpty {
                            ForEach(comments) { comment in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: comment.userImage).font(.title2).foregroundStyle(Color.gray).frame(width: 40, height: 40).background(Color.white.opacity(0.1)).clipShape(Circle())
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(comment.userName).fontWeight(.bold).foregroundStyle(Color.white)
                                            if comment.isAdmin {
                                                Image(systemName: "checkmark.shield.fill")
                                                    .foregroundStyle(Color.blue)
                                                    .font(.caption)
                                            }
                                            if let r = comment.rating { HStack(spacing: 2) { Image(systemName: "star.fill").font(.caption2).foregroundStyle(Color.yellow); Text("\(r)").font(.caption2).foregroundStyle(Color.white) }.padding(.horizontal, 6).padding(.vertical, 2).background(Color.white.opacity(0.1)).clipShape(Capsule()) }
                                            Spacer()
                                            Text(comment.timeAgo).font(.caption).foregroundStyle(Color.white.opacity(0.5))
                                        }
                                        Text(comment.text).font(.subheadline).foregroundStyle(Color.white.opacity(0.8)).fixedSize(horizontal: false, vertical: true)
                                        
                                        // Comment Image Display
                                        if let imageURL = comment.imageURL, let url = URL(string: imageURL) {
                                            AsyncImage(url: url) { image in
                                                image.resizable().scaledToFill()
                                            } placeholder: {
                                                Color.white.opacity(0.1)
                                            }
                                            .frame(height: 150)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .padding(.top, 4)
                                        }
                                    }
                                }
                                .padding().glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 16)).padding(.horizontal)
                            }
                        } else { Text("كن أول من يقيم المكان!").font(.caption).foregroundStyle(Color.white.opacity(0.5)).padding(.horizontal) }
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationTitle("").toolbarBackground(.hidden, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button(action: { dismiss() }) { Image(systemName: "xmark.circle.fill").font(.title2).foregroundStyle(Color.white.opacity(0.6)) } } }
            .onAppear { store.loadComments(for: spot.id) }
            // Fetch Weather
            .task {
                if let weather = await WeatherManager.shared.getWeather(latitude: spot.coordinate.latitude, longitude: spot.coordinate.longitude) {
                    let temp = weather.currentWeather.temperature.converted(to: .celsius).value
                    let wind = weather.currentWeather.wind.speed.converted(to: .kilometersPerHour).value

                    
                    // Update UI
                    self.temperature = "\(Int(temp))°C"
                    self.windSpeed = "\(Int(wind)) كم"
                    self.rainChance = (weather.dailyForecast.first?.precipitationChance ?? 0) > 0 ? "\(Int((weather.dailyForecast.first?.precipitationChance ?? 0) * 100))%" : "0%"
                }
            }
        }
    }
    enum MapApp { case apple, google, waze }
    
    func canOpen(app: MapApp) -> Bool {
        let scheme = app == .google ? "comgooglemaps://" : "waze://"
        return UIApplication.shared.canOpenURL(URL(string: scheme)!)
    }
    
    func openMap(app: MapApp) {
        let lat = spot.coordinate.latitude
        let long = spot.coordinate.longitude
        let urlString: String
        
        switch app {
        case .apple:
            urlString = "maps://?daddr=\(lat),\(long)"
        case .google:
             urlString = "comgooglemaps://?daddr=\(lat),\(long)&directionsmode=driving"
        case .waze:
            urlString = "waze://?ll=\(lat),\(long)&navigate=yes"
        }
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}


struct WeatherColumn: View { let icon: String, value: String, label: String; var body: some View { VStack(spacing: 4) { Image(systemName: icon).foregroundStyle(Color.yellow); Text(value).fontWeight(.bold).foregroundStyle(Color.white); Text(label).font(.caption).foregroundStyle(Color.white.opacity(0.6)) }.frame(maxWidth: .infinity) } }

