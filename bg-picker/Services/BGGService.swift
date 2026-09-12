//
//  BGGService.swift
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

    /// The most ids /thing accepts in a single request.
    private static let batchSize = 20
    private static let retryLimit = 4
    /// How long to wait before re-asking for something BGG answered 202 for.
    private static let queuedRetryDelay: Duration = .milliseconds(1500)
    /// Breathing room between batches — BGG rate-limits bursts aggressively.
    private static let batchPause: Duration = .milliseconds(700)

    // MARK: - Request plumbing

    private func makeRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(appToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    /// BGG answers 202 ("queued") while it prepares data for something it hasn't
    /// served recently — both /thing and /geeklist do this — so every endpoint needs
    /// the same wait-and-retry. It lives here once rather than at each call site.
    private func fetch<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        let request = makeRequest(url: url)

        for _ in 0..<Self.retryLimit {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw BGGError.invalidResponse(statusCode: -1, body: nil)
            }

            switch http.statusCode {
            case 200:
                return try decoder.decode(type, from: data)
            case 202:
                try await Task.sleep(for: Self.queuedRetryDelay)
            default:
                throw BGGError.invalidResponse(
                    statusCode: http.statusCode,
                    body: String(data: data, encoding: .utf8)
                )
            }
        }

        throw BGGError.invalidResponse(statusCode: 202, body: "Still queued after several retries.")
    }

    // MARK: - Geeklist

    func fetchGeeklist(id: String) async throws -> BGGGeeklistResponse {
        guard let url = URL(string: "\(geeklistBaseURL)/\(id)") else {
            throw BGGError.invalidURL
        }
        return try await fetch(BGGGeeklistResponse.self, from: url)
    }

    /// The two-pull flow the swipe deck is built from.
    ///
    /// A geeklist entry only carries an object id and a name — no image, no players,
    /// no stats — so every id it yields has to be looked up again through /thing.
    func fetchGeeklistGames(id: String) async throws -> [BGGItem] {
        let geeklist = try await fetchGeeklist(id: id)

        var seen = Set<String>()
        let ids = geeklist.items
            .filter { $0.subtype == "boardgame" }
            .map(\.objectId)
            // The same game can legitimately appear twice in one geeklist.
            .filter { seen.insert($0).inserted }

        guard !ids.isEmpty else { return [] }

        let games = try await fetchGames(ids: ids)

        // Results come back grouped per batch, so put them back in the list's order.
        let gamesByID = Dictionary(games.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return ids.compactMap { gamesByID[$0] }
    }

    // MARK: - Things

    func fetchGame(id: String) async throws -> BGGItem {
        guard let game = try await fetchGames(ids: [id]).first else {
            throw BGGError.noResults
        }
        return game
    }

    /// Fetches full detail for many ids, batched to what /thing will accept.
    ///
    /// `stats=1` is what carries `averageweight` (complexity) and `average` (rating);
    /// without it both come back absent and the cards lose two of their four stats.
    func fetchGames(ids: [String]) async throws -> [BGGItem] {
        guard !ids.isEmpty else { return [] }

        var games: [BGGItem] = []

        for (index, batch) in ids.chunked(into: Self.batchSize).enumerated() {
            if index > 0 {
                try await Task.sleep(for: Self.batchPause)
            }

            guard var components = URLComponents(string: "\(baseURL)/thing") else {
                throw BGGError.invalidURL
            }
            components.queryItems = [
                URLQueryItem(name: "id", value: batch.joined(separator: ",")),
                URLQueryItem(name: "stats", value: "1")
            ]
            guard let url = components.url else { throw BGGError.invalidURL }

            games += try await fetch(BGGThingResponse.self, from: url).items
        }

        return games
    }

    // MARK: - Input parsing

    /// Pulls the list id out of a geeklist URL — `.../geeklist/331207/some-slug` — or
    /// accepts a bare numeric id that was typed in directly.
    ///
    /// `nonisolated` so views can validate input without awaiting the actor.
    nonisolated static func geeklistID(from input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if isNumericID(trimmed) { return trimmed }

        guard let url = URL(string: trimmed) else { return nil }
        return geeklistID(from: url)
    }

    nonisolated static func geeklistID(from url: URL) -> String? {
        let segments = url.pathComponents.filter { $0 != "/" }
        guard let marker = segments.firstIndex(of: "geeklist"),
              case let idIndex = segments.index(after: marker),
              segments.indices.contains(idIndex),
              isNumericID(segments[idIndex]) else {
            return nil
        }
        return segments[idIndex]
    }

    private nonisolated static func isNumericID(_ candidate: String) -> Bool {
        !candidate.isEmpty && candidate.allSatisfy(\.isNumber)
    }
}
