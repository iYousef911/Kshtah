import SwiftUI

struct FoundingDayBadge: View {
    var body: some View {
        ZStack {
            // Background Crest
            Circle()
                .fill(Color(red: 0.96, green: 0.94, blue: 0.88)) // Cream Background
                .frame(width: 44, height: 44)
                .shadow(color: .black.opacity(0.1), radius: 2)
            
            // Outer Ring
            Circle()
                .stroke(Color(red: 0.29, green: 0.22, blue: 0.16), lineWidth: 1) // Coffee Brown Ring
                .frame(width: 40, height: 40)
            
            // Inner Symbolic Elements
            VStack(spacing: 2) {
                // Top Palm
                Image(systemName: "palm.tree.fill")
                    .font(.system(size: 14))
                
                // Heritage Pattern Shapes
                HStack(spacing: 4) {
                    Image(systemName: "tent.fill")
                    Image(systemName: "swords") // Hypothetical or similar heritage icon
                }
                .font(.system(size: 8))
            }
            .foregroundStyle(Color(red: 0.29, green: 0.22, blue: 0.16))
            
            // Text Wrap (Simulated with circles for MVP look)
            Circle()
                .strokeBorder(Color(red: 0.29, green: 0.22, blue: 0.16).opacity(0.2), style: StrokeStyle(lineWidth: 0.5, dash: [2]))
                .frame(width: 36, height: 36)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        FoundingDayBadge()
    }
}
