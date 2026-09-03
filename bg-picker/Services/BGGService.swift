//
//  BGGError.swift
//  bg-picker
//
//  Created by Danniel on 02/09/26.
//

import Foundation
import XMLCoder

enum BGGError: LocalizedError {
    case invalidURL
    case invalidResponse(statusCode: Int, body: String?)
    case noResults

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .invalidResponse(let statusCode, let body):
            var message = "BGG returned status \(statusCode)."
            switch statusCode {
            case 401, 403:
                message += " Your Authorization token is missing, malformed, or not valid for this request — double-check it was pasted in exactly, with no extra spaces or quotes."
            case 429, 503:
                message += " BGG is rate-limiting requests. Wait a bit and try again."
            case 404:
                message += " Nothing was found at that URL — double-check the ID."
            default:
                break
            }
            if let body, !body.isEmpty {
                let snippet = body.prefix(300)
                message += " Response: \(snippet)"
            }
            return message
        case .noResults:
            return "No results found."
        }
    }
}

actor BGGService {
    static let shared = BGGService()
    private init() {}

    private let baseURL = "https://boardgamegeek.com/xmlapi2"
    // Geeklist hasn't been ported to xmlapi2 yet, so it's served from the
    // older v1 root instead.
    private let geeklistBaseURL = "https://boardgamegeek.com/xmlapi/geeklist"
    private let decoder = XMLDecoder()

    // Get this from https://boardgamegeek.com/applications after registering
    // and creating a Token for your application. BGG now requires every XML
    // API request to carry this as a Bearer token.
    private let appToken = SecretVariables.apiKey

    private func makeRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(appToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    // MARK: thing
    func fetchGame(id: String) async throws -> BGGItem {
        guard var components = URLComponents(string: "\(baseURL)/thing") else {
            throw BGGError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "id", value: id),
            URLQueryItem(name: "stats", value: "1")
        ]
        guard let url = components.url else { throw BGGError.invalidURL }
        let request = makeRequest(url: url)

        // BGG's /thing endpoint can briefly 202 ("please wait") while it prepares
        // data for an ID it hasn't served recently, so we retry a few times.
        for _ in 0..<4 {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw BGGError.invalidResponse(statusCode: -1, body: nil)
            }

            switch http.statusCode {
            case 200:
                let result = try decoder.decode(BGGThingResponse.self, from: data)
                guard let item = result.items.first else { throw BGGError.noResults }
                return item
            case 202:
                try await Task.sleep(nanoseconds: 1_500_000_000)
            default:
                throw BGGError.invalidResponse(statusCode: http.statusCode, body: String(data: data, encoding: .utf8))
            }
        }
        throw BGGError.invalidResponse(statusCode: 202, body: "Still queued after several retries.")
    }

    // MARK: Fetch Geek List
    func fetchGeeklist(id: String) async throws -> BGGGeeklistResponse {
        guard let url = URL(string: "\(geeklistBaseURL)/\(id)") else {
            throw BGGError.invalidURL
        }
        let request = makeRequest(url: url)

        // Like /thing, an infrequently-viewed geeklist can queue on BGG's end
        // and return 202 while it's prepared, so we retry a few times.
        for _ in 0..<4 {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw BGGError.invalidResponse(statusCode: -1, body: nil)
            }

            switch http.statusCode {
            case 200:
                return try decoder.decode(BGGGeeklistResponse.self, from: data)
            case 202:
                try await Task.sleep(nanoseconds: 1_500_000_000)
            default:
                throw BGGError.invalidResponse(statusCode: http.statusCode, body: String(data: data, encoding: .utf8))
            }
        }
        throw BGGError.invalidResponse(statusCode: 202, body: "Still queued after several retries.")
    }

    // MARK: Ambil Thumbnail
    /// Fetches thumbnail URLs for a set of thing ids, keyed by id. /search and
    /// /xmlapi/geeklist don't return images themselves, so callers use this
    /// to enrich list rows after the fact. Batches into groups of 20, since
    /// that's the max /thing accepts per request.
    func fetchThumbnails(ids: [String]) async throws -> [String: String] {
        guard !ids.isEmpty else { return [:] }
        var result: [String: String] = [:]
        for batch in ids.chunked(into: 20) {
            let batchResult = try await fetchThumbnailBatch(ids: batch)
            result.merge(batchResult) { current, _ in current }
        }
        return result
    }

    // MARK: Ambil Thumbnail dalam batch
    private func fetchThumbnailBatch(ids: [String]) async throws -> [String: String] {
        guard var components = URLComponents(string: "\(baseURL)/thing") else {
            throw BGGError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "id", value: ids.joined(separator: ","))
        ]
        guard let url = components.url else { throw BGGError.invalidURL }
        let request = makeRequest(url: url)

        for _ in 0..<4 {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw BGGError.invalidResponse(statusCode: -1, body: nil)
            }

            switch http.statusCode {
            case 200:
                let decoded = try decoder.decode(BGGThingResponse.self, from: data)
                var mapping: [String: String] = [:]
                for item in decoded.items {
                    if let thumbnail = item.thumbnail {
                        mapping[item.id] = thumbnail
                    }
                }
                return mapping
            case 202:
                try await Task.sleep(nanoseconds: 1_500_000_000)
            default:
                throw BGGError.invalidResponse(statusCode: http.statusCode, body: String(data: data, encoding: .utf8))
            }
        }
        throw BGGError.invalidResponse(statusCode: 202, body: "Still queued after several retries.")
    }

    
    private static func validate(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw BGGError.invalidResponse(statusCode: statusCode, body: String(data: data, encoding: .utf8))
        }
    }
}
