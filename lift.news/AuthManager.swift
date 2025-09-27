//
//  AuthManager.swift
//  lift.news
//
//  Created by Michael Kao on 9/27/25.
//

import Foundation
internal import Combine
import Supabase

class SupabaseAuth {
	let client = SupabaseClient(supabaseURL: URL(string: "https://sgtrwkdmpzbszwyprpot.supabase.co")!, supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNndHJ3a2RtcHpic3p3eXBycG90Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5OTIwNTksImV4cCI6MjA3NDU2ODA1OX0.rlckLh5aFnHamoq3fPxfwx6o4KkKuGKLgPbhTfqe3_o")
	
	func LoginUser() async throws -> User {
		do {
			let session = try await client.auth.session
			let metadata = session.user.userMetadata as [String: Any]
			let user = User(id: session.user.id, email: session.user.email ?? "", created_at: session.user.createdAt)
			//let user = User(id: session.user.id, username: metadata["username"] as? String ?? session.user.email ?? "", email: session.user.email ?? "", created_at: session.user.createdAt, updated_at: session.user.updatedAt, blocked_users: metadata["blocked_users"] as? Array<UUID> ?? [])
			return user
		} catch let error {
			throw error
		}
	}
	
	func SignIn(email: String, password: String) async throws -> User {
		do {
			let response = try await client.auth.signIn(email: email.lowercased(), password: password)
			let metadata = response.user.userMetadata as [String: Any]
			let user = User(id: response.user.id, email: response.user.email ?? "", created_at: response.user.createdAt)
			//let user = User(id: response.user.id, username: metadata["username"] as? String ?? response.user.email ?? "", email: response.user.email ?? "", created_at: response.user.createdAt, updated_at: response.user.updatedAt, blocked_users: metadata["blocked_users"] as? Array<UUID> ?? [])
			return user
		} catch let error{
			throw error
		}
	}
	
	
	func SignUp(email: String, password: String) async throws -> User {
		do {
			let response = try await client.auth.signUp(email: email.lowercased(), password: password)
			let metadata = response.user.userMetadata as [String: Any]
			let user = User(id: response.user.id, email: response.user.email ?? "", created_at: response.user.createdAt)
			//let user = User(id: response.user.id, username: metadata["username"] as? String ?? response.user.email ?? "", email: response.user.email ?? "", created_at: response.user.createdAt, updated_at: response.user.updatedAt, blocked_users: metadata["blocked_users"] as? Array<UUID> ?? [])
			return user
		} catch let error{
			throw error
		}
	}
	
	func signOut() async throws {
		do {
			try await client.auth.signOut()
		} catch let error{
			throw error
		}
	}
}

//MARK: - VIEW MODEL BELOW
enum AuthState: Hashable {
	case Initial
	case Signin
	case Signout
}

class AuthViewModel: ObservableObject {
	@Published var email: String = ""
	@Published var password: String = ""
	@Published var errorMessage: String = ""
	@Published var authState: AuthState = AuthState.Initial
	@Published var isLoading = false
	@Published var currentUser: User? = nil
	
	var cancellable = Set<AnyCancellable>()
	
	private var supabaseAuth: SupabaseAuth = SupabaseAuth()
	
	@MainActor
	func isUserSignIn() async {
		do {
			self.currentUser = try await supabaseAuth.LoginUser()
			authState = AuthState.Signin
		} catch _ {
			authState = AuthState.Signout
		}
	}
	
	@MainActor
	func signup(email: String, password: String) async {
		do {
			isLoading = true
			self.currentUser = try await supabaseAuth.SignUp(email: email, password: password)
			authState = AuthState.Signin
			isLoading = false
		} catch let error {
			errorMessage = error.localizedDescription
			isLoading = false
		}
	}
	
	@MainActor
	func signIn(email: String, password: String) async {
		do {
			isLoading = true
			self.currentUser = try await supabaseAuth.SignIn(email: email, password: password)
			authState = AuthState.Signin
			isLoading = false
		} catch let error {
			errorMessage = error.localizedDescription
			isLoading = false
		}
	}
	
	func validEmail() -> Bool {
		let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
		let isEmailValid = self.email.range(of: emailRegex, options: .regularExpression) != nil
		return isEmailValid
	}
	
	func validPassword() -> Bool {
		let passwordRegex = "^(?=.*[A-Z])(?=.*[a-z])(?=.*\\d)(?=.*\\.).{8,}$"
		let isPasswordValid = self.password.range(of: passwordRegex, options: .regularExpression) != nil
		return isPasswordValid
	}
	
	@MainActor
	func signoutUser() async {
		do {
			try await supabaseAuth.signOut()
			authState = AuthState.Signout
		} catch let error {
			errorMessage = error.localizedDescription
		}
	}
	
	@MainActor
	func deleteUserOnServer(userID: String, apiKey: String) async throws {
		guard let url = URL(string: "http://your-server-address:8000/delete-user") else {
			throw URLError(.badURL)
		}
		
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
		
		let body: [String: Any] = ["user_id": userID]
		request.httpBody = try JSONSerialization.data(withJSONObject: body)
		
		do {
			let (data, response) = try await URLSession.shared.data(for: request)
			
			guard let httpResponse = response as? HTTPURLResponse else {
				throw URLError(.badServerResponse)
			}

			if (200...299).contains(httpResponse.statusCode) {
				print("User deletion initiated successfully!")
			} else {
				if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
				   let errorMessage = jsonResponse["detail"] as? String {
					print("Error deleting user. Status code: \(httpResponse.statusCode)")
					print("Error message from server: \(errorMessage)")
				} else {
					print("Error deleting user. Status code: \(httpResponse.statusCode)")
					print("Failed to parse error message from server.")
				}
				throw URLError(.init(rawValue: httpResponse.statusCode))
			}
		} catch {
			print("Error during request: \(error)")
			throw error
		}
	}
}
