//
//  MyBookingsView.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 22/11/2025.
//


import SwiftUI

struct MyBookingsView: View {
    @EnvironmentObject var store: AppDataStore
    @Environment(\.dismiss) var dismiss
    @State private var selectedSegment = 0 // 0 = Active, 1 = History
    @State private var bookingToRate: Booking? // State for sheet
    
    var filteredBookings: [Booking] {
        if selectedSegment == 0 {
            return store.bookings.filter { $0.status == .active }
        } else {
            // Completed or Cancelled
            return store.bookings.filter { $0.status == .completed || $0.status == .cancelled }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                
                VStack(spacing: 20) {
                    // Custom Segment Control
                    HStack {
                        SegmentButton(title: "الحالية", isSelected: selectedSegment == 0) { selectedSegment = 0 }
                        SegmentButton(title: "السابقة", isSelected: selectedSegment == 1) { selectedSegment = 1 }
                    }
                    .padding(4)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // List
                    ScrollView {
                        if filteredBookings.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "cube.box")
                                    .font(.system(size: 60))
                                    .foregroundStyle(Color.white.opacity(0.3))
                                Text("لا توجد طلبات")
                                    .font(.headline)
                                    .foregroundStyle(Color.white.opacity(0.5))
                            }
                            .frame(height: 400)
                        } else {
                            VStack(spacing: 15) {
                                ForEach(filteredBookings) { booking in
                                    // Pass closure to trigger rating
                                    BookingRow(booking: booking) {
                                        bookingToRate = booking
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("طلباتي")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("رجوع") { dismiss() }.foregroundStyle(Color.white)
                }
            }
            // REVIEW SHEET
            .sheet(item: $bookingToRate) { booking in
                ReviewView(booking: booking)
                    .presentationDetents([.medium])
            }
        }
        .trackScreen(name: "Bookings") // Analytic Screen
    }
}

struct BookingRow: View {
    let booking: Booking
    var onRateTap: (() -> Void)? = nil // Callback
    
    var statusColor: Color {
        switch booking.status {
        case .active: return .green
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // Image
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 70, height: 70)
                Image(systemName: booking.item.imageName)
                    .font(.title2)
                    .foregroundStyle(Color.white)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(booking.item.name)
                        .font(.headline)
                        .foregroundStyle(Color.white)
                    Spacer()
                    
                    // Status Label
                    Text(booking.status.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.2))
                        .foregroundStyle(statusColor)
                        .clipShape(Capsule())
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.5))
                    Text(booking.dateRangeString)
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                
                HStack {
                    Text("\(Int(booking.totalPrice)) ﷼")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.green)
                    
                    Spacer()
                    
                    // Show Rate Button if completed and not rated
                    if booking.status == .completed && !booking.isRated {
                        Button(action: { onRateTap?() }) {
                            Text("تقييم")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange)
                                .foregroundStyle(Color.white)
                                .clipShape(Capsule())
                        }
                    } else if booking.isRated {
                        // Already rated
                        HStack(spacing: 2) {
                            Text("تم التقييم")
                                .font(.caption)
                            Image(systemName: "checkmark.seal.fill")
                        }
                        .foregroundStyle(Color.orange.opacity(0.8))
                    }
                }
            }
        }
        .padding()
        .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct SegmentButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(isSelected ? .bold : .regular)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.white.opacity(0.2) : Color.clear)
                .clipShape(Capsule())
                .foregroundStyle(Color.white)
        }
    }
}
