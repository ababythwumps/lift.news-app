//
//  ContentView.swift
//  lift.news
//
//  Created by Michael Kao on 9/27/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
	@StateObject var appViewModel: AppViewModel = AppViewModel()
	
	@State private var showingLogInsignUpView: Bool = false
	
	@State private var screenWidth = UIScreen.main.bounds.width
	@State private var screenHeight = UIScreen.main.bounds.height
	
    var body: some View {
		if let todaysArticle = appViewModel.todaysArticle {
			ZStack {
				Color(.systemBackground)
					.ignoresSafeArea()
				
				VStack {
					HStack {
						Text("lift.news")
							.font(.title)
							.foregroundStyle(.primary)
							.padding(.horizontal)
						
						Spacer()
						
						if appViewModel.user == nil {
							Button {
								showingLogInsignUpView = true
							} label: {
								Text("sign in")
									.font(.title3)
									.padding(.horizontal)
									.padding(.vertical, 5)
									.background(Color.clear)
									.overlay(
										Rectangle()
											.stroke(.primary, lineWidth: 2)
									)
									.padding(.trailing)
							}.buttonStyle(PlainButtonStyle())
						} else {
							Button {
								// show settings view
							} label: {
								Text("settings")
									.font(.title3)
									.padding(.horizontal)
									.padding(.vertical, 5)
									.background(Color.clear)
									.overlay(
										Rectangle()
											.stroke(.primary, lineWidth: 2)
									)
									.padding(.trailing)
							}.buttonStyle(PlainButtonStyle())
						}
					}
					
					Rectangle()
						.frame(width: screenWidth, height: screenHeight/300)
						.foregroundStyle(.primary)
					
					Group {
						ScrollView {
							HStack {
								Text(todaysArticle.source.name)
									.foregroundStyle(.secondary)
									.font(.caption)
									.padding(.leading)
									.padding(.top)
								
								Spacer()
							}
							
							Text(todaysArticle.title)
								.font(.title2)
								.padding(.trailing, screenWidth/3)
								.padding(.leading)
							
							if let author = todaysArticle.author {
								HStack {
									Text("by \(author)")
										.foregroundStyle(.secondary)
										.font(.caption)
										.padding(.leading)
									
									Spacer()
								}
							}
							
							HStack {
								Text(todaysArticle.formattedPublishedDate)
									.foregroundStyle(.secondary)
									.font(.caption)
									.padding(.leading)
								
								Spacer()
							}
							
							if let articleImageLink = todaysArticle.urlToImage {
								AsyncImage(url: URL(string: articleImageLink)) { image in
									image
										.resizable()
										.scaledToFit()
										.padding(.horizontal)
								} placeholder: {
									ProgressView()
								}
							}
							
							if let content = todaysArticle.fullContent {
								ArticleContentsView(markdownText: content)
									.font(.body)
									.foregroundStyle(.primary)
									.padding(.horizontal, 5)
							}
							
							Button {
								if let currentIndex = appViewModel.positiveArticles.firstIndex(of: todaysArticle) {
									
									let nextIndex = currentIndex + 1
									if nextIndex < appViewModel.positiveArticles.count {
										appViewModel.todaysArticle = appViewModel.positiveArticles[nextIndex]
									} else {
										appViewModel.todaysArticle = appViewModel.positiveArticles.first
									}
								}
							} label: {
								Text("next article ➡️")
									.font(.title3)
									.padding(.horizontal)
									.padding(.vertical, 5)
									.background(Color.clear)
									.overlay(
										Rectangle()
											.stroke(.primary, lineWidth: 2)
									)
									.padding(.trailing)
							}.buttonStyle(PlainButtonStyle())
						}
					}
				}
			}
			
			.sheet(isPresented: self.$showingLogInsignUpView) {
				LogInSignUpView(appViewModel: appViewModel)
			}
		} else {
			ProgressView()
				.onAppear {
					Task {
						await appViewModel.loadNews()
					}
				}
			
			Text("loading today's read...")
				.foregroundStyle(.secondary)
		}
    }
}

#Preview {
    ContentView()
}
