//
//  KashatMap.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 21/11/2025.
//

import SwiftUI
import MapKit

struct KashatMap: View {
    @EnvironmentObject var store: AppDataStore
    @State private var showAddSpotSheet = false
    @State private var showSpotDetailSheet = false // New State
    
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753),
            span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
        )
    )
    @State private var currentCenter: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753) // NEW: Track center
    @State private var selectedSpot: CampingSpot?
    
    @State private var isAddMode = false
    @State private var showLocationError = false
    @State private var locationManager = CLLocationManager()
    
    var body: some View {
        ZStack {
            // 1. Map
            Map(position: $position, selection: $selectedSpot) {
                UserAnnotation()
                
                ForEach(store.spots) { spot in
                    Annotation(spot.name, coordinate: spot.coordinate) {
                        Image(systemName: "tent.fill")
                            .padding(8)
                            .foregroundStyle(Color.white)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                            .scaleEffect(selectedSpot?.id == spot.id ? 1.5 : 1.0)
                            .animation(.spring, value: selectedSpot?.id)
                    }
                    .tag(spot)
                }
            }
            .mapStyle(.hybrid(elevation: .realistic))
            .onMapCameraChange { context in
                currentCenter = context.camera.centerCoordinate
            }
            .mapControls {
               // MapUserLocationButton() // Custom button used instead
                MapCompass()
                MapScaleView()
            }
            // Center Crosshair (Only in Add Mode)
            if isAddMode {
                Image(systemName: "plus")
                    .font(.largeTitle)
                    .foregroundStyle(Color.red)
                    .shadow(radius: 2)
            }
            
            // 2. UI Controls
            VStack {
                Spacer()
                HStack {
                    if isAddMode {
                        // Confirm / Cancel Buttons
                        Button(action: { isAddMode = false }) {
                            Text("إلغاء")
                                .fontWeight(.bold)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .foregroundStyle(Color.white)
                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                        
                        Button(action: validateAndAddSpot) {
                            Text("تأكيد الموقع 📍")
                                .fontWeight(.bold)
                                .padding()
                                .background(Color.green)
                                .foregroundStyle(Color.white)
                                .clipShape(Capsule())
                        }
                    } else {
                        // Standard Add Button
                        Spacer()
                        Button(action: {
                            withAnimation { isAddMode = true }
                        }) {
                            Image(systemName: "plus")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.white)
                                .frame(width: 60, height: 60)
                                .glassEffect(GlassStyle.regular.interactive(), in: Circle())
                                .shadow(color: Color.black.opacity(0.3), radius: 10)
                        }
                    }
                }
                .padding(.bottom, isAddMode ? 40 : 100)
                .padding(.horizontal, 20)
            }
            
            // 3. Detail Card (Only if NOT in Add Mode)
            if !isAddMode {
                VStack {
                    Spacer()
                    if let spot = selectedSpot {
                        GlassSpotCard(spot: spot)
                            .padding()
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .id(spot.id)
                            .onTapGesture {
                                showSpotDetailSheet = true // Open Sheet
                            }
                            .padding(.bottom, 60)
                    }
                }
            }
        }
        .onAppear { locationManager.requestWhenInUseAuthorization() }
        .sheet(isPresented: $showAddSpotSheet) {
            AddSpotView(coordinate: currentCenter)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        // NEW: Detail Sheet
        .sheet(isPresented: $showSpotDetailSheet) {
            if let spot = selectedSpot {
                SpotDetailView(spot: spot)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        // Error Alert for Geofencing
        .alert("لا يمكنك إضافة مكان هنا", isPresented: $showLocationError) {
            Button("حسناً", role: .cancel) { }
        } message: {
            Text("يجب أن تكون في نفس المنطقة لإضافة مكان جديد. (المسافة المسموحة 50 كم)")
        }
    }
    
    // Geofencing Logic
    func validateAndAddSpot() {
        guard let userLoc = locationManager.location else {
            print("User location unknown")
            return
        }
        
        // Use tracked center
        let mapCenter = currentCenter
        
        let centerLoc = CLLocation(latitude: mapCenter.latitude, longitude: mapCenter.longitude)
        let distance = userLoc.distance(from: centerLoc) // Distance in meters
        
        // Limit: 50km = 50,000 meters
        if distance < 50000 {
            showAddSpotSheet = true
            isAddMode = false
        } else {
            showLocationError = true
        }
    }
}

#Preview {
    KashatMap()
}
