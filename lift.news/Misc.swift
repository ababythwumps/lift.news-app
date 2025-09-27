//
//  Misc.swift
//  lift.news
//
//  Created by Michael Kao on 9/27/25.
//

import Foundation

struct NewsResponse: Codable {
	let status: String
	let totalResults: Int
	let articles: [Article]
}

struct Article: Codable, Identifiable, Equatable {
	let id = UUID()
	let source: Source
	let author: String?
	let title: String
	let description: String?
	let url: String
	let urlToImage: String?
	let publishedAt: String
	let content: String?
	
	var fullContent: String? = nil
	
	private enum CodingKeys: String, CodingKey {
		case source, author, title, description, url, urlToImage, publishedAt, content
	}
	
	static func == (lhs: Article, rhs: Article) -> Bool {
		lhs.id == rhs.id
	}
}

extension Article {
	var publishedDate: Date? {
		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
		
		if let date = formatter.date(from: publishedAt) {
			return date
		}
		
		let fallbackFormatter = ISO8601DateFormatter()
		fallbackFormatter.formatOptions = [.withInternetDateTime]
		return fallbackFormatter.date(from: publishedAt)
	}
}

extension Article {
	var formattedPublishedDate: String {
		guard let date = publishedDate else { return "Unknown date" }
		
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		formatter.timeStyle = .short
		
		return formatter.string(from: date)
	}
}

struct Source: Codable {
	let id: String?
	let name: String
}

struct User: Codable, Identifiable, Hashable {
	var id: UUID
	var email: String
	var created_at: Date
	
	enum CodingKeys: String, CodingKey {
		case id, email, created_at
	}
}
