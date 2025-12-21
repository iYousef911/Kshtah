//
//  ReviewView.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 23/11/2025.
//


import SwiftUI

struct ReviewView: View {
    let booking: Booking
    @EnvironmentObject var store: AppDataStore
    @Environment(\.dismiss) var dismiss
    
    @State private var rating: Int = 5
    @State private var comment: String = ""
    
    var body: some View {
        ZStack {
            LiquidBackgroundView()
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Text("كيف كانت تجربتك؟")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.white)
                    
                    Text(booking.item.name)
                        .font(.headline)
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                .padding(.top, 40)
                
                // Stars
                HStack(spacing: 15) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.yellow)
                            .onTapGesture {
                                withAnimation(.spring) {
                                    rating = star
                                }
                            }
                    }
                }
                .padding()
                .glassEffect(GlassStyle.regular, in: Capsule())
                
                // Text Editor
                VStack(alignment: .leading) {
                    Text("اكتب تعليقك")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.7))
                        .padding(.horizontal)
                    
                    TextField("ملاحظاتك...", text: $comment, axis: .vertical)
                        .lineLimit(4...6)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(Color.white)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Submit Button
                Button(action: {
                    store.submitReview(booking: booking, rating: rating, comment: comment)
                    dismiss()
                }) {
                    Text("إرسال التقييم")
                        .fontWeight(.bold)
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
    }
}
