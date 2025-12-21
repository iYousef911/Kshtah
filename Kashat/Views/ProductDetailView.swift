//
//  ProductDetailView.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 21/11/2025.
//


import SwiftUI

struct ProductDetailView: View {
    let item: GearItem
    @EnvironmentObject var store: AppDataStore
    @Environment(\.dismiss) var dismiss
    
    @State private var showCheckoutSheet = false
    @State private var navigateToChat = false // NEW State
    @State private var ownerThreadId: String?
    
    var body: some View {
        ZStack {
            // Background
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 1. Large Product Image
                    ZStack {
                        RoundedRectangle(cornerRadius: 32)
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 300)
                        Image(systemName: item.imageName)
                            .font(.system(size: 100))
                            .foregroundStyle(Color.white)
                            .shadow(color: Color.blue.opacity(0.5), radius: 20)
                    }
                    .padding()
                    
                    // 2. Details Container
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(item.category)
                                .font(.caption)
                                .padding(6)
                                .background(Color.blue.opacity(0.2))
                                .clipShape(Capsule())
                                .foregroundStyle(Color.blue)
                            
                            Spacer()
                            
                            HStack {
                                Image(systemName: "star.fill").foregroundStyle(Color.yellow)
                                Text("\(item.rating, specifier: "%.1f")")
                            }
                            .foregroundStyle(Color.white)
                        }
                        
                        Text(item.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.white)
                        
                        Divider().background(Color.white.opacity(0.2))
                        
                        // Owner Info (UPDATED with Chat Action)
                        HStack {
                            Circle().fill(Color.gray).frame(width: 40, height: 40)
                            VStack(alignment: .leading) {
                                Text("المالك").font(.caption).foregroundStyle(Color.gray)
                                Text(item.ownerName).fontWeight(.bold).foregroundStyle(Color.white)
                            }
                            Spacer()
                            
                            // CHAT BUTTON
                            Button(action: startChatWithOwner) {
                                Image(systemName: "message.fill")
                                    .padding(10)
                                    .glassEffect(GlassStyle.regular.interactive(), in: Circle())
                                    .foregroundStyle(Color.white)
                            }
                        }
                        
                        Text("وصف")
                            .font(.headline)
                            .foregroundStyle(Color.white)
                            .padding(.top)
                        Text("هذا المنتج ممتاز للكشتات العائلية. نظيف جداً ويتم تعقيمه بعد كل استخدام. متوفر في شمال الرياض.")
                            .font(.body)
                            .foregroundStyle(Color.white.opacity(0.7))
                            .lineSpacing(5)
                    }
                    .padding()
                    .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal)
                    
                    Color.clear.frame(height: 150)
                }
            }
            
             // 3. Sticky Bottom Bar
            if store.rentButtonStyle == "floating_fab" {
                // Variant B: Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showCheckoutSheet = true }) {
                            Text("استأجر الآن ⛺️")
                                .fontWeight(.bold)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .clipShape(Capsule())
                                .shadow(color: .blue.opacity(0.5), radius: 10, x: 0, y: 5)
                        }
                        .padding()
                    }
                }
            } else {
                // Control (Blue Capsule) & Variant A (Green Rect)
                VStack {
                    Spacer()
                    HStack {
                        VStack(alignment: .leading) {
                            Text("السعر").font(.caption).foregroundStyle(Color.gray)
                            HStack(alignment: .firstTextBaseline) {
                                Text("\(item.pricePerDay) ﷼").font(.title2).fontWeight(.bold).foregroundStyle(Color.white)
                                Text("/ يوم").font(.caption).foregroundStyle(Color.gray)
                            }
                        }
                        Spacer()
                        
                        Button(action: { showCheckoutSheet = true }) {
                            Text("استأجر الآن")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(store.rentButtonStyle == "green_rect" ? Color.green : Color.blue) // Variant A
                                .clipShape(store.rentButtonStyle == "green_rect" ? AnyShape(RoundedRectangle(cornerRadius: 12)) : AnyShape(Capsule())) // Variant A Check
                                .shadow(radius: store.rentButtonStyle == "green_rect" ? 5 : 0)
                        }
                        .frame(width: 200)
                    }
                    .padding()
                    .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.right").padding(8).glassEffect(GlassStyle.regular.interactive(), in: Circle()).foregroundStyle(Color.white)
                }
            }
        }
        .sheet(isPresented: $showCheckoutSheet) {
            RentalCheckoutView(item: item).presentationDetents([.fraction(0.85)]).presentationDragIndicator(.visible)
        }
        // Navigation to Chat
        .navigationDestination(isPresented: $navigateToChat) {
            if let threadId = ownerThreadId {
                // Create a temporary ChatThread object to pass to the view
                // Uses real ownerId if available
                ChatDetailView(chat: ChatThread(id: threadId, otherUserName: item.ownerName, otherUserImage: "person.circle.fill", otherUserId: item.ownerId ?? "legacy_user", messages: [], lastMessageText: "", lastMessageTime: Date()))
            }
        }
    }
    
    // Logic to start chat
    func startChatWithOwner() {
        // Use real ownerId if available, fallback to name hash for legacy data
        let targetId = item.ownerId ?? item.ownerName.hashValue.description
        
        // Prevent chatting with yourself
        guard targetId != store.userProfile?.id else { return }
        
        store.getChatThreadId(otherUserId: targetId) { threadId in
            self.ownerThreadId = threadId
            self.navigateToChat = true
        }
    }
}
