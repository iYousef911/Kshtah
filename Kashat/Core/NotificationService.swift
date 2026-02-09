import Foundation
import OneSignalFramework

class NotificationService {
    static let shared = NotificationService()
    
    // Replace with your REST API Key from OneSignal Dashboard
    // CAUTION: In a real production app, this should be in a backend function.
    // Putting it here is for MVP/Client-side implementation as requested.
    private let oneSignalAppId = "425a7450-e204-4d77-b5f3-9f9246ae9d3f"
    private let restApiKey = "os_v2_app_g76q2w4uozcrrn37vbwwdgy27k3yl7255vxc273a5a4j6tij5ilgn2l52777274534a2e554g6436f5223c323f4625b53g2" // Placeholder, user needs to replace
    
    func sendPushNotification(to recipientIds: [String], title: String, message: String, data: [String: Any]? = nil) {
        guard !recipientIds.isEmpty else { return }
        
        let url = URL(string: "https://onesignal.com/api/v1/notifications")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(restApiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "app_id": oneSignalAppId,
            "include_external_user_ids": recipientIds, // Targeting by Firebase UID
            "headings": ["en": title],
            "contents": ["en": message],
            "ios_sound": "ping.wav" // Custom sound if available, otherwise default
        ]
        
        if let data = data {
            body["data"] = data
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Notification Error: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print("✅ Notification Sent Successfully!")
                } else {
                    print("⚠️ Notification Failed: \(String(describing: response))")
                }
            }.resume()
        } catch {
            print("❌ JSON Error: \(error.localizedDescription)")
        }
    }
}
