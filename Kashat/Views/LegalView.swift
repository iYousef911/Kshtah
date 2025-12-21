//
//  LegalView.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 28/11/2025.
//


import SwiftUI

struct LegalView: View {
    let title: String
    let content: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                
                ScrollView {
                    Text(content)
                        .font(.body)
                        .foregroundStyle(Color.white.opacity(0.8))
                        .padding()
                        .multilineTextAlignment(.leading) // Better for reading
                }
            }
            .navigationTitle(title)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("إغلاق") { dismiss() }
                        .foregroundStyle(Color.white)
                }
            }
        }
    }
}

// Hardcoded text for MVP (Move to a hosted URL for production)
// TODO: Apple recommends using a URL for Privacy Policy. Consider replacing this text view with a WebLink or SFSafariViewController.
struct LegalData {
    static let privacyPolicy = """
    سياسة الخصوصية
    
    نحن في "كشتات" نلتزم بحماية خصوصيتك. توضح هذه السياسة كيفية جمع واستخدام بياناتك.
    
    ١. البيانات التي نجمعها:
    - رقم الهاتف (للتحقق من الهوية).
    - الموقع الجغرافي (لعرض أماكن الكشتات القريبة).
    - الصور (عند رفع صور للمكان أو المنتج).
    
    ٢. كيف نستخدم بياناتك:
    - لتسهيل عملية التأجير بين المستخدمين.
    - لعرض الأماكن المضافة على الخريطة.
    
    ٣. مشاركة البيانات:
    - لا نشارك بياناتك مع أطراف ثالثة إلا لغرض الدفع (مثل بوابة ميسر) أو الامتثال القانوني.
    
    للتواصل: support@kashat.sa
    """
    
    static let termsOfService = """
    شروط الاستخدام (EULA)
    
    باستخدامك لتطبيق "كشتات"، فإنك توافق على الشروط التالية:
    
    ١. المحتوى المسموح:
    - يمنع نشر أي محتوى مسيء، غير قانوني، أو ينتهك حقوق الآخرين.
    - نحتفظ بالحق في حذف أي محتوى مخالف وحظر المستخدم.
    
    ٢. التأجير:
    - "كشتات" هي منصة وسيطة فقط. المسؤولية تقع على المؤجر والمستأجر فيما يخص جودة المعدات وسلامتها.
    
    ٣. الدفع:
    - جميع العمليات المالية تتم عبر بوابات دفع آمنة ومرخصة.
    
    ٤. إلغاء الحساب:
    - يمكنك طلب حذف حسابك وبياناتك في أي وقت عبر الإعدادات.
    """
}