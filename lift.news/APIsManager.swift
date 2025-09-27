//
//  APIsManager.swift
//  lift.news
//
//  Created by Michael Kao on 9/27/25.
//

import Foundation

class NewsAPI {
	private let apiKey = "f9a5486d7cca49d08fdfbf3fc46ae86d"
	private let baseURL = "https://newsapi.org/v2/top-headlines"
	private let jina = JinaAPI()
	
	func fetchNews(country: String = "us") async throws -> [Article] {
		guard var components = URLComponents(string: baseURL) else {
			throw URLError(.badURL)
		}
		components.queryItems = [
			URLQueryItem(name: "country", value: country),
			URLQueryItem(name: "apiKey", value: apiKey)
		]
		guard let url = components.url else { throw URLError(.badURL) }
		
		let (data, response) = try await URLSession.shared.data(from: url)
		guard let httpRes = response as? HTTPURLResponse,
			  (200..<300).contains(httpRes.statusCode) else {
			throw URLError(.badServerResponse)
		}
		
		var decoded = try JSONDecoder().decode(NewsResponse.self, from: data).articles
		
		try await withThrowingTaskGroup(of: (Int, String?).self) { group in
			for (index, article) in decoded.enumerated() {
				group.addTask {
					do {
						let md = try await self.jina.fetchMarkdown(for: article.url)
						
						let parts = md.components(separatedBy: "Content:")
						let content = parts.last?.trimmingCharacters(in: .whitespacesAndNewlines)
						
						return (index, content)
					} catch {
						print("Jina fetch failed for: \(article.url), \(error)")
						return (index, nil)
					}
				}
			}
			
			for try await (index, content) in group {
				decoded[index].fullContent = content
			}
		}
		
		return decoded
	}
}

class JinaAPI {
	func fetchMarkdown(for articleURL: String) async throws -> String {
		guard let encoded = articleURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
			  let url = URL(string: "https://r.jina.ai/\(encoded)") else {
			throw URLError(.badURL)
		}
		
		let (data, response) = try await URLSession.shared.data(from: url)
		
		guard let httpRes = response as? HTTPURLResponse,
			  (200..<300).contains(httpRes.statusCode) else {
			throw URLError(.badServerResponse)
		}
		
		guard let markdown = String(data: data, encoding: .utf8) else {
			throw URLError(.cannotDecodeRawData)
		}
		return markdown
	}
}
