//
//  APIsManager.swift
//  lift.news
//
//  Created by Michael Kao on 9/27/25.
//

import Foundation
import FoundationModels

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
				decoded[index].fullContent = content.map { cleanArticleContent($0) }
			}
		}
		
		return decoded
	}

	func cleanArticleContent(_ rawContent: String) -> String {
		var content = rawContent
		
		// 1. Remove everything before "Markdown Content:" if it exists
		if let range = content.range(of: "Markdown Content:") {
			content = String(content[range.upperBound...])
		}
		
		// 2. Regex patterns for lines to remove
		let linesToRemove: [String] = [
			#"^Title:.*$"#,
			#"^URL Source:.*$"#,
			#"^Published Time:.*$"#,
			#"^Markdown Content:.*$"#,
			#"^===============.*$"#,
			#"^Skip to.*$"#,
			#"^Close dialogue.*$"#,
			#"^\[Support us.*$"#,
			#"^\[Print subscriptions.*$"#,
			#"^\[Skip to main content.*$"#,
			#"^\[Sign in.*$"#,
			#"^Support the Guardian.*$"#,
			#"^Fund the free press.*$"#,
			#"^Print subscriptions.*$"#,
			#"^Newsletters.*$"#,
			#"^Sign in.*$"#,
			#".*edition.*"#,
			#"^The Guardian - Back to home.*$"#,
			#"^\[x].*"#,
			#"^News$|^Opinion$|^Sport$|^Culture$|^Lifestyle$"#,
			#"^View all.*$"#,
			#"^Show more Hide.*$"#,
			#"^Search input.*$"#,
			#"^Download the app.*$"#,
			#"^Search jobs.*$"#,
			#"^Digital Archive.*$"#,
			#"^Guardian.*$"#,
			#"^About Us.*$"#,
			#"^Live events.*$"#,
			#"^Corrections.*$"#,
			#"^\*\s*.*$"#,
			#"^Tips.*$"#,
			#".*Crosswords.*"#,
			#".*Wordiply.*"#,
			#"^Image\s*\d+:?.*$"#,
			#"^View image.*$"#,
			#".*(cookie|cookies|cookie policy|privacy policy|consent|accept cookies).*"#,
			#"^\s*\*\s*\[.*\]\(.*\)\s*$"#,
			#"^\[[^\]]*?\]\(https?:\/\/(?:www\.)?theguardian\.com[^\)]*?\)$"#
		]
		
		// Apply regex cleaning
		for pattern in linesToRemove {
			content = content.replacingOccurrences(
				of: pattern,
				with: "",
				options: [.regularExpression, .caseInsensitive]
			)
		}
		
		// 3. Specific strings to remove
		let stringsToRemove: [String] = [
			"*   [About Us](https://www.pbs.org/newshour/about)",
			"*   [Facebook](https://www.facebook.com/newshour)",
			"*   [YouTube](https://www.youtube.com/user/PBSNewsHour)",
			"*   [Instagram](https://www.instagram.com/newshour/)",
			"*   [X](https://twitter.com/NewsHour)",
			"*   [TikTok](https://www.tiktok.com/@pbsnews)",
			"*   [Threads](https://www.threads.net/@newshour)",
			"*   [RSS](https://www.pbs.org/newshour/feeds/rss/headlines)",
			"Enter your email address",
			"*   [Wellness](https://www.theguardian.com/us/wellness)",
			"*   [Fashion](https://www.theguardian.com/fashion)",
			"*   [Food](https://www.theguardian.com/food)",
			"*   [Recipes](https://www.theguardian.com/tone/recipes)",
			"*   [Love & sex](https://www.theguardian.com/lifeandstyle/love-and-sex)",
			"*   [Home & garden](https://www.theguardian.com/lifeandstyle/home-and-garden)",
			"*   [Health & fitness](https://www.theguardian.com/lifeandstyle/health-and-wellbeing)",
			"*   [Family](https://www.theguardian.com/lifeandstyle/family)",
			"*   [Travel](https://www.theguardian.com/travel)",
			"*   [Money](https://www.theguardian.com/money)",
			"www.theguardian.com"
		]
		
		for str in stringsToRemove {
			content = content.replacingOccurrences(of: str, with: "")
		}
		
		// Special: remove ".theguardian.com"
		content = content.replacingOccurrences(of: ".theguardian.com", with: "")
		
		// 4. Collapse multiple newlines
		content = content.replacingOccurrences(
			of: #"\n{3,}"#,
			with: "\n\n",
			options: .regularExpression
		)
		
		// 5. Replace <em> with markdown-style **
		content = content.replacingOccurrences(
			of: #"^<em>"#,
			with: "**",
			options: .regularExpression
		)
		
		// 6. Trim up
		content = content.trimmingCharacters(in: .whitespacesAndNewlines)
		
		// 7. Try to find the "real" article start
		var lines = content.components(separatedBy: .newlines)
		var articleStartIndex = 0
		
		for (i, lineRaw) in lines.enumerated() {
			let line = lineRaw.trimmingCharacters(in: .whitespaces)
			if line.count > 50,
			   line.range(
				   of: #"^(News|Opinion|Sport|Culture|Lifestyle|View all|Show more|Search|Support|Sign|Download|About|The Guardian|Cookies?)"#,
				   options: .regularExpression
			   ) == nil {
				articleStartIndex = i
				break
			}
		}
		
		if articleStartIndex > 0 {
			lines = Array(lines.dropFirst(articleStartIndex))
			content = lines.joined(separator: "\n")
		}
		
		return content
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
