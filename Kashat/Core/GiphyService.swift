//
//  GiphyService.swift
//  Kashat
//
//  Fetches GIFs from Giphy API. Get your key at https://developers.giphy.com/
//

import Foundation

struct GiphyItem: Identifiable {
    let id: String
    let url: String
    let previewURL: String
    let title: String?
}

final class GiphyService {
    static let shared = GiphyService()
    
    // IMPORTANT: Get your own free API key from https://developers.giphy.com/dashboard/
    // The public beta key below may be deprecated. Create an account and get your key.
    private let apiKey = "H3JEtA51V2OjQcNGzhZFfTU0eh18n8Hx" // Giphy public beta key (may be deprecated - replace with your own!)
    private let baseURL = "https://api.giphy.com/v1/gifs"
    
    private init() {}
    
    func search(query: String, limit: Int = 24) async throws -> [GiphyItem] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return try await trending(limit: limit)
        }
        var components = URLComponents(string: "\(baseURL)/search")!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "rating", value: "g")
        ]
        guard let url = components.url else { return [] }
        return try await fetchGifs(from: url)
    }
    
    func trending(limit: Int = 24) async throws -> [GiphyItem] {
        var components = URLComponents(string: "\(baseURL)/trending")!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "rating", value: "g")
        ]
        guard let url = components.url else { return [] }
        return try await fetchGifs(from: url)
    }
    
    private func fetchGifs(from url: URL) async throws -> [GiphyItem] {
        print("🔍 Fetching GIFs from: \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Check HTTP status
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 HTTP Status: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ Error response: \(errorString)")
                }
                throw NSError(domain: "GiphyService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])
            }
        }
        
        // Debug: Print raw response (first 500 chars)
        if let responseString = String(data: data, encoding: .utf8) {
            let preview = String(responseString.prefix(500))
            print("📦 Response preview: \(preview)...")
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decoded = try decoder.decode(GiphySearchResponse.self, from: data)
        print("✅ Decoded \(decoded.data.count) GIF items")
        
        let items = decoded.data.compactMap { item -> GiphyItem? in
            guard let url = item.images?.fixedHeight?.url ?? item.images?.original?.url else {
                print("⚠️ Skipping item \(item.id): no image URL found")
                return nil
            }
            let preview = item.images?.fixedHeightSmall?.url ?? url
            return GiphyItem(id: item.id, url: url, previewURL: preview, title: item.title)
        }
        
        print("✅ Returning \(items.count) valid GIF items")
        return items
    }
}

private struct GiphySearchResponse: Decodable {
    let data: [GiphyDataItem]
}

private struct GiphyDataItem: Decodable {
    let id: String
    let title: String?
    let images: GiphyImages?
}

private struct GiphyImages: Decodable {
    let original: GiphyImage?
    let fixedHeight: GiphyImage?
    let fixedHeightSmall: GiphyImage?
}

private struct GiphyImage: Decodable {
    let url: String
}
