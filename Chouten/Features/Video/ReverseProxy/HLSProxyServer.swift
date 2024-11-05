//
//  HLSProxyServer.swift
//  HLSAVPlayerURLSession
//
//  Created by Aline Borges on 08/08/24.
//  Based on https://github.com/garynewby/HLS-video-offline-caching
//
//

/*

import Foundation
import Combine

struct HLSResponseItem: Codable {
    let data: Data
    let url: URL
    let mimeType: String
}

enum VideoProxyFormats: String, CaseIterable {
    case m3u8
    case ts
    case mp4
    case m4s
    case m4a
    case m4v
}

final class HLSVideoProxy {

    private let service: HLSService
    private var cancellables = Set<AnyCancellable>()

    private let originURLKey = "__hls_origin_url"

    init(service: HLSService = CustomHSLService()) {
        self.service = service
    }

    deinit {
        // Unregister the custom URLProtocol when done
        URLProtocol.unregisterClass(HLSVideoProxyURLProtocol.self)
    }

    // MARK: - Public functions

    func reverseProxyURL(from originURL: URL) -> URL? {
        guard var components = URLComponents(url: originURL, resolvingAgainstBaseURL: false) else {
            return nil
        }

        components.scheme = "http"
        components.host = "localhost"
        components.port = 8080 // Example port

        let originURLQueryItem = URLQueryItem(name: originURLKey, value: originURL.absoluteString)
        components.queryItems = (components.queryItems ?? []) + [originURLQueryItem]

        return components.url
    }

    // MARK: - Request Handling

    // This function is no longer using GCDWebServerDataResponse
    private func serverResponse(for url: URL) -> AnyPublisher<Data, Error> {
        service.dataTaskPublisher(url: url)
            .map { item in item.data }
            .catch { error in
                Just(Data()) // Return empty data in case of error
                    .setFailureType(to: Error.self)
            }
            .eraseToAnyPublisher()
    }

    private func playlistResponse(for url: URL) -> AnyPublisher<Data, Error> {
        service.dataTaskPublisher(url: url)
            .tryMap { item in
                try self.reverseProxyPlaylist(with: item, forOriginURL: url)
            }
            .catch { _ in
                Just(Data()) // Return empty data in case of error
                    .setFailureType(to: Error.self)
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Manipulating Playlist

    private func reverseProxyPlaylist(with item: HLSResponseItem, forOriginURL originURL: URL) throws -> Data {
        let original = String(data: item.data, encoding: .utf8)
        let parsed = original?
            .components(separatedBy: .newlines)
            .map { line in processPlaylistLine(line, forOriginURL: originURL) }
            .joined(separator: "\n")
        if let data = parsed?.data(using: .utf8) {
            return data
        } else {
            throw URLError(.badServerResponse)
        }
    }

    private func processPlaylistLine(_ line: String, forOriginURL originURL: URL) -> String {
        guard !line.isEmpty else { return line }

        if line.hasPrefix("#") {
            return lineByReplacingURI(line: line, forOriginURL: originURL)
        }

        if let originalSegmentURL = absoluteURL(from: line, forOriginURL: originURL),
           let reverseProxyURL = reverseProxyURL(from: originalSegmentURL) {
            return reverseProxyURL.absoluteString
        }
        return line
    }

    private func lineByReplacingURI(line: String, forOriginURL originURL: URL) -> String {
        guard let uriPattern = try? NSRegularExpression(pattern: "URI=\"([^\"]*)\"") else {
            return ""
        }

        let lineRange = NSRange(location: 0, length: line.count)
        guard let result = uriPattern.firstMatch(in: line, options: [], range: lineRange) else { return line }

        let uri = (line as NSString).substring(with: result.range(at: 1))
        guard let absoluteURL = absoluteURL(from: uri, forOriginURL: originURL) else { return line }
        guard let reverseProxyURL = reverseProxyURL(from: absoluteURL) else { return line }

        let newFile = uriPattern.stringByReplacingMatches(in: line, options: [], range: lineRange, withTemplate: "URI=\"\(reverseProxyURL.absoluteString)\"")
        return newFile
    }

    private func absoluteURL(from line: String, forOriginURL originURL: URL) -> URL? {
        if line.hasPrefix("http://") || line.hasPrefix("https://") {
            return URL(string: line)
        }

        guard let scheme = originURL.scheme,
              let host = originURL.host else {
            return nil
        }

        let path: String
        if line.hasPrefix("/") {
            path = line
        } else {
            path = originURL.deletingLastPathComponent().appendingPathComponent(line).path
        }

        return URL(string: scheme + "://" + host + path)?.standardized
    }
}

// Custom URLProtocol to intercept HTTP requests
class HLSVideoProxyURLProtocol: URLProtocol {

    // Custom headers you want to add to the requests
    private let customHeaders: [String: String] = [
        "X-Custom-Header": "YourCustomHeaderValue",
        "Authorization": "Bearer YourTokenHere"
    ]

    override class func canInit(with request: URLRequest) -> Bool {
        // Only intercept requests for the reverse proxy
        if let url = request.url,
           url.host == "localhost" {
            return true
        }
        return false
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        // Ensure the request is mutable so we can modify it
        guard var urlRequest = request.copy() as? URLRequest else {
            // If we cannot copy the request, fail gracefully
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        // Add custom headers to the request
        for (key, value) in customHeaders {
            urlRequest.addValue(value, forHTTPHeaderField: key)
        }

        // Extract the original URL from the query parameters
        let originURLString = request.url?.queryItems?.first(where: { $0.name == "__hls_origin_url" })?.value
        guard let originURLString = originURLString, let originURL = URL(string: originURLString) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        // Check if it's a playlist (.m3u8) or media segment (.ts, .mp4)
        if originURL.pathExtension == VideoProxyFormats.m3u8.rawValue {
            // Handle playlist request
            HLSVideoProxy().playlistResponse(for: originURL)
                .sink { result in
                    switch result {
                    case .failure(let error):
                        self.client?.urlProtocol(self, didFailWithError: error)
                    case .success(let data):
                        // Send the data to the client with the correct response
                        let response = HTTPURLResponse(url: urlRequest.url!,
                                                        statusCode: 200,
                                                        httpVersion: nil,
                                                        headerFields: nil)
                        self.client?.urlProtocol(self, didReceive: response!, cacheStoragePolicy: .notAllowed)
                        self.client?.urlProtocol(self, didLoad: data)
                    }
                }
                .store(in: &cancellables)
        } else {
            // Handle media segment request (e.g., .ts, .mp4)
            HLSVideoProxy().serverResponse(for: originURL)
                .sink { result in
                    switch result {
                    case .failure(let error):
                        self.client?.urlProtocol(self, didFailWithError: error)
                    case .success(let data):
                        // Send the data to the client with the correct response
                        let response = HTTPURLResponse(url: urlRequest.url!,
                                                        statusCode: 200,
                                                        httpVersion: nil,
                                                        headerFields: nil)
                        self.client?.urlProtocol(self, didReceive: response!, cacheStoragePolicy: .notAllowed)
                        self.client?.urlProtocol(self, didLoad: data)
                    }
                }
                .store(in: &cancellables)
        }

        // Create a new URL session task with the modified request
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                self.client?.urlProtocol(self, didFailWithError: error)
            } else if let data = data, let response = response {
                self.client?.urlProtocol(self, didLoad: data)
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
        }
        task.resume()
    }

    override func stopLoading() {
        // Handle stop loading if necessary
    }
}
*/
