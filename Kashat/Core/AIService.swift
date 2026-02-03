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
    
    func generateInsight(spotName: String, location: String, temperature: Double, condition: String) async -> String {
        // 1. Check Cache
        let cacheKey = "\(spotName)-\(Int(temperature))-\(condition)"
        if let cached = insightCache[cacheKey] {
            return cached
        }
        
        // 2. Prepare Prompt (Simple payload)
        let prompt = """
        اكتب جملة واحدة قصيرة وجذابة (باللهجة السعودية البيضاء) تنصح فيها بزيارة كشتة في "\(spotName)" في منطقة "\(location)".
        الجو الآن: \(Int(temperature)) درجة مئوية، وحالته: \(condition).
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
    
    func generatePackingList(spotName: String, location: String, type: String, temperature: Double) async -> [String] {
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
