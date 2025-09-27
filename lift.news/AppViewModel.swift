//
//  AppViewModel.swift
//  lift.news
//
//  Created by Michael Kao on 9/27/25.
//

import Foundation
internal import Combine

final class AppViewModel: ObservableObject {
	@Published var user: User?
	
	@Published var articles: [Article] = []
	@Published var positiveArticles: [Article] = []
	@Published var todaysArticle: Article? = nil
	@Published var isLoading = false
	@Published var errorMessage: String? = nil
	
	private let api = NewsAPI()
	
	func loadNews(maxRetries: Int = 10) async {
		isLoading = true
		errorMessage = nil
		
		do {
			let articles = try await api.fetchNews()
			self.articles = articles
			self.positiveArticles = articles.filterPositive()
			
			guard !positiveArticles.isEmpty else {
				throw URLError(.fileDoesNotExist)
			}
			
			var attempt = 0
			var currentArticleNumber = 0
			var success = false
			
			while attempt < maxRetries &&
					currentArticleNumber < positiveArticles.count &&
					!success {
				
				do {
					self.todaysArticle = positiveArticles[currentArticleNumber]
					
					if let content = self.todaysArticle?.fullContent, !content.isEmpty {
						success = true
						break
					} else {
						throw URLError(.cannotDecodeRawData)
					}
				} catch {
					attempt += 1
					currentArticleNumber += 1
					print("Retry #\(attempt) failed. Moving to next article...")
				}
			}
			
			if !success {
				errorMessage = "Could not load an article after \(maxRetries) attempts."
				self.todaysArticle = nil
			}
		} catch {
			self.errorMessage = "Error fetching news: \(error.localizedDescription)"
			print("Error fetching news: \(error)")
		}
		
		isLoading = false
	}
}

struct SentimentAnalyzer {
	private let positiveWords: Set<String> = [
		"breakthrough", "innovation", "discovery", "achievement", "recovery",
		"cure", "solution", "improvement", "progress", "kindness", "generosity",
		"volunteer", "help", "support", "community", "together", "unity",
		"hope", "inspiring", "uplifting", "celebration",
		"overcome", "resilience", "donated", "saved", "rescued",
		"renewable", "sustainable", "conservation", "restore", "protect",
		"scholarship", "education", "learning", "research", "scientific",
		"medical advance", "treatment", "therapy", "healing"
	]
	private let negativeWords: Set<String> = [
		"death", "murder", "war", "violence", "crash", "disaster", "terrorism",
		"crime", "scandal", "controversy", "conflict", "shooting", "attack",
		"fraud", "corruption", "lawsuit", "bankruptcy", "fired", "layoffs", "dies", "die"
	]
	
	func isPositive(_ text: String) -> Bool {
		let tokens = text.lowercased().split(separator: " ")
		let score = tokens.reduce(0) { score, word in
			if positiveWords.contains(String(word)) {
				return score + 1
			} else if negativeWords.contains(String(word)) {
				return score - 1
			}
			return score
		}
		return score >= 0
	}
}

extension Array where Element == Article {
	func filterPositive() -> [Article] {
		let analyzer = SentimentAnalyzer()
		return self.filter { article in
			analyzer.isPositive(article.title + " " + (article.description ?? ""))
		}
	}
}
