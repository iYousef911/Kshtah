//
//  AIService.swift
//  Kashat
//
//  Created by Yousef Abu Sallamah on 31/01/2026.
//

import Foundation
import SwiftUI

class AIService {
    static let shared = AIService()
    
    // URL to your deployed Cloudflare Worker
    // Replace this with your actual Worker URL after deployment (e.g., https://kashat-ai-worker.yourname.workers.dev)
    private let workerURL = URL(string: "https://kashat-ai-worker.youssefzx.workers.dev")!
    private let session = URLSession.shared
    
    // Simple in-memory cache to save tokens
    private var insightCache: [String: String] = [:]
    
    func generateInsight(spotName: String, location: String, temperature: Double, condition: String, moonPhase: String? = nil, moonIllumination: Int? = nil, isPro: Bool) async -> String {
        // 0. Gate for PRO Users
        guard isPro else {
            return fallbackInsight(temperature: temperature)
        }

        // 1. Check Cache
        let cacheKey = "\(spotName)-\(Int(temperature))-\(condition)-\(moonPhase ?? "")"
        if let cached = insightCache[cacheKey] {
            return cached
        }
        
        // 2. Prepare Prompt
        var moonContext = ""
        if let phase = moonPhase, let illumination = moonIllumination {
            moonContext = "حالة القمر: \(phase)، نسبة الإضاءة: \(illumination)%."
        }
        
        let prompt = """
        اكتب جملة واحدة قصيرة وجذابة (باللهجة السعودية البيضاء) تنصح فيها بزيارة كشتة في "\(spotName)" في منطقة "\(location)".
        الجو الآن: \(Int(temperature)) درجة مئوية، وحالته: \(condition).
        \(moonContext) (إذا كان القمر بدراً أو ساطعاً، اذكر جمال ليلة القمراء).
        ركز على تجربة الكشتة والأجواء. لا تزيد عن 15 كلمة.
        """
        
        // 3. Prepare Request to Worker
        var request = URLRequest(url: workerURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "prompt": prompt,
            "temperature": temperature
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            // 4. Call Worker
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("⚠️ Worker Service Error: Status \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                return fallbackInsight(temperature: temperature)
            }
            
            // 5. Parse Response (Worker returns { "content": "..." })
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let content = json["content"] as? String {
                
                // Cache Result
                insightCache[cacheKey] = content
                return content
            }
        } catch {
            print("⚠️ Worker Service Error: \(error)")
        }
        
        return fallbackInsight(temperature: temperature)
    }
    
    func generatePackingList(spotName: String, location: String, type: String, temperature: Double, isPro: Bool) async -> [String] {
        // Gate for PRO Users
        guard isPro else {
            return ["ماء", "خيمة", "حطب", "فرشة", "كشاف", "شاحن"] // Immediate Fallback
        }

        let prompt = """
        اكتب قائمة تجهيز (packing list) مختصرة جداً لكشتة في "\(spotName)" بمنطقة "\(location)".
        نوع المكان: \(type).
        درجة الحرارة المتوقعة: \(Int(temperature))°C.
        اذكر فقط 6 أغراض أساسية (أهم شي للكشتة).
        أعطني قائمة مفصولة بفاصلة فقط.
        مثال: خيمة، حطب، ماء، شاحن متنقل، فرشة، كشاف.
        """
        
        var request = URLRequest(url: workerURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "prompt": prompt,
            "temperature": temperature
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
               let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let content = json["content"] as? String {
                return content.components(separatedBy: "،").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            }
        } catch {
            print("⚠️ Packing List Error: \(error)")
        }
        
        return ["ماء", "خيمة", "حطب", "فرشة", "كشاف", "شاحن"] // Fallback
    }
    
    func generateItinerary(carType: String, duration: Int, groupSize: Int, isPro: Bool) async -> String {
        // Gate for PRO Users
        guard isPro else {
            return "هذه الميزة حصرية للمشتركين. اشترك في PRO للحصول على خطط كشتة ذكية ومخصصة!"
        }

        let prompt = """
        اكتب خطة كشتة (itinerary) مفصلة وممتعة لمنطقة صحراوية في السعودية.
        السيارة: \(carType).
        المدة: \(duration) أيام.
        عدد الأشخاص: \(groupSize) أشخاص.
        اجعل الخطة تشمل: أماكن مقترحة (لا تسمي مكاناً محدداً بل صف النوع)، أنشطة (شب نار، شوي، تأمل نجوم)، ونصيحة سلامة خاصة بالسيارة.
        استخدم لغة جذابة باللهجة السعودية البيضاء.
        لا تزيد عن 100 كلمة.
        """
        
        var request = URLRequest(url: workerURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "prompt": prompt,
            "temperature": 0.7
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
               let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let content = json["content"] as? String {
                return content
            }
        } catch {
            print("⚠️ Itinerary Error: \(error)")
        }
        
        return "للأسف تعذر تجهيز الخطة الآن. تأكد من اتصالك بالإنترنت وحاول مرة أخرى." // Fallback
    }
    
    // Kashat Guide AI Chat
    func askGuide(query: String, isPro: Bool) async -> String {
        // System Prompt with rich persona and structured instructions
        let systemPrompt = """
        أنت "خبير كشتة" (Kashat Expert)، مساعد ذكي وودود متخصص في التخييم، الرحلات البرية، والسياحة الطبيعية في المملكة العربية السعودية.
        
        شخصيتك:
        - تتحدث بلهجة سعودية بيضاء طبيعية وقريبة من الناس
        - متحمس للطبيعة والكشتات، وتنقل هذا الحماس للمستخدم
        - خبير وتفعل توصيات دقيقة وعملية
        - دافئ وودود كأنك صديق خبير
        
        قدراتك:
        - اقتراح أماكن للكشتة بناءً على الاهتمامات (صحراء، جبال، شواطئ، أودية)
        - نصائح التخييم والتجهيز
        - وصفات طعام برية وأفكار شوي
        - معلومات الطقس والنجوم والقمر
        - خطط رحلات مخصصة (بيومياتها)
        - نصائح السلامة والإسعافات الأولية في البر
        - معلومات عن النباتات والحيوانات البرية السعودية
        
        قواعد الإجابة:
        - اجعل إجاباتك مفيدة ومحددة وعملية
        - استخدم رموز تعبيرية (emoji) باعتدال لإحياء الرسالة ⛺🏔️🌙
        - إذا كان السؤال يحتاج قائمة، استخدم نقاط واضحة ومختصرة
        - أكمل إجابتك دائماً حتى النهاية، لا تتوقف في منتصف الجملة أبداً
        - اختم إجابتك بجملة كاملة ومنتهية
        - إذا سألك عن شيء خارج التخييم والسياحة في السعودية، اعتذر بلطف
        \(isPro ? "- المستخدم مشترك في PRO، قدم له توصيات أكثر تفصيلاً وخصوصية" : "")
        """
        
        let prompt = "\(systemPrompt)\n\n---\nالمستخدم: \(query)\nخبير كشتة:"
        
        var request = URLRequest(url: workerURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 45
        
        let body: [String: Any] = [
            "prompt": prompt,
            "temperature": isPro ? 0.8 : 0.7,
            "max_tokens": isPro ? 1200 : 800
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
               let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let content = json["content"] as? String {
                return content.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            print("⚠️ Chat Guide Error: \(error)")
        }
        
        return "المعذرة، واجهت مشكلة في الاتصال 🙏 حاول مرة ثانية بعد شوي!"
    }
    
    private func fallbackInsight(temperature: Double) -> String {
        // Fallback context-aware logic if API fails or no key
        if temperature < 15 {
            return "الجو بارد (\(Int(temperature))°)، خذ معك فروة واستمتع بشبة النار! 🔥"
        } else if temperature > 30 {
            return "الجو حار شوي (\(Int(temperature))°)، انتبه من الشمس واجلس بالظل. ☀️"
        } else {
            return "الجو بطل (\(Int(temperature))°)! لا تفوتك الكشتة اليوم. ⛺️"
        }
    }
}
