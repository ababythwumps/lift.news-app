//
//  ArticleContentsView.swift
//  lift.news
//
//  Created by Michael Kao on 9/27/25.
//

import SwiftUI

struct ArticleContentsView: View {
	let markdownText: String
	
	var body: some View {
		ScrollView {
			if let attributed = try? AttributedString(markdown: markdownText) {
				Text(attributed)
					.padding()
			} else {
				Text(markdownText)
					.padding()
					.font(.body.monospaced())
			}
		}
	}
}

#Preview {
	ArticleContentsView(markdownText: "What's up")
}
