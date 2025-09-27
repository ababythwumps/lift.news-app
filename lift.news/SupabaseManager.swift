//
//  SupabaseManager.swift
//  lift.news
//
//  Created by Michael Kao on 9/27/25.
//

import Foundation
import Supabase
internal import Combine

class TimelineArticlesViewModel: ObservableObject {
	
	@Published var articles = [Article]()
	@Published var isLoadingArticles = false
	@Published var isErrorLoadingArticles : String? = nil
	
	let supabase = SupabaseClient(
		supabaseURL: URL(string: "https://sgtrwkdmpzbszwyprpot.supabase.co")!,
		supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNndHJ3a2RtcHpic3p3eXBycG90Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5OTIwNTksImV4cCI6MjA3NDU2ODA1OX0.rlckLh5aFnHamoq3fPxfwx6o4KkKuGKLgPbhTfqe3_o"
	)
	
//	func toggleLike(articleId: UUID, currentLikes: Int, isLiked: Bool) async {
//		do {
//			let newLikesCount = isLiked ? currentLikes + 1 : max(0, currentLikes - 1)
//			
//			try await supabase
//				.from("posts")
//				.update(["likes": newLikesCount])
//				.eq("id", value: articleId)
//				.execute()
//			
//			DispatchQueue.main.async {
//				if let index = self.articles.firstIndex(where: { $0.id == articleId }) {
//					self.articles[index].likes = newLikesCount
//				}
//			}
//			
//		} catch {
//			print("Error updating likes: \(error.localizedDescription)")
//		}
//	}
	
	func fetchArticles() async throws {
		do {
			DispatchQueue.main.async {
				self.isLoadingArticles = true
			}
				
			let fetchedArticles: [Article] = try await supabase
				.from("posts")
				.select()
				.order("created_at", ascending: false)
				.execute()
				.value
				
			print("Fetched Articles: \(fetchedArticles) \n [END FETCHED ARTICLES]")
				
			DispatchQueue.main.async {
				self.articles = fetchedArticles
				self.isLoadingArticles = false
				self.isErrorLoadingArticles = nil
			}
			
		} catch let error as PostgrestError {
			DispatchQueue.main.async {
				self.isLoadingArticles = false
				self.isErrorLoadingArticles = error.localizedDescription
				print("PostgrestError:")
				print(error.localizedDescription)
			}
			
		} catch let error as URLError {
			DispatchQueue.main.async {
				self.isLoadingArticles = false
				self.isErrorLoadingArticles = error.localizedDescription
				print("URLError:")
				print(error.localizedDescription)
			}
			
		} catch {
			DispatchQueue.main.async {
				self.isLoadingArticles = false
				self.isErrorLoadingArticles = error.localizedDescription
				print("Unknown Error Type:")
				print(error.localizedDescription)
			}
		}
	}
}

class UsersViewModel: ObservableObject {
	
	@Published var users = [User]()
	@Published var isLoadingUsers = false
	@Published var isErrorLoadingUsers : String? = nil
	
	let supabase = SupabaseClient(
		supabaseURL: URL(string: "https://mgtgphruaveplwemotps.supabase.co")!,
		supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1ndGdwaHJ1YXZlcGx3ZW1vdHBzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIwNjAzNDQsImV4cCI6MjA1NzYzNjM0NH0.Ee8WhNa2A-iAoyVOI3uuyB1tGgO5P0pfiAtDt7s7dCw"
	)
	
	func fetchUsers() async throws {
		do {
			DispatchQueue.main.async {
				self.isLoadingUsers = true
			}
			
			let fetchedUsers: [User] = try await supabase
				.from("profiles")
				.select()
				.order("created_at", ascending: false)
				.execute()
				.value
				
			print("Fetched Users: \(fetchedUsers)")
				
			DispatchQueue.main.async {
				self.users = fetchedUsers
				self.isLoadingUsers = false
				self.isErrorLoadingUsers = nil
			}
			
		} catch let error as PostgrestError {
			DispatchQueue.main.async {
				self.isLoadingUsers = false
				self.isErrorLoadingUsers = error.localizedDescription
				print("PostgrestError:")
				print(error.localizedDescription)
			}
			
		} catch let error as URLError {
			DispatchQueue.main.async {
				self.isLoadingUsers = false
				self.isErrorLoadingUsers = error.localizedDescription
				print("URLError:")
				print(error.localizedDescription)
			}
			
		} catch {
			DispatchQueue.main.async {
				self.isLoadingUsers = false
				self.isErrorLoadingUsers = error.localizedDescription
				print("Unknown Error Type:")
				print(error.localizedDescription)
			}
		}
	}
}
