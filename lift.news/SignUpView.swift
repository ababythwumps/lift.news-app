//
//  SignUpView.swift
//  lift.news
//
//  Created by Michael Kao on 9/27/25.
//

import SwiftUI

struct SignUpView: View {
	@ObservedObject var authViewModel: AuthViewModel
	@ObservedObject var appViewModel: AppViewModel
	
	@Environment(\.dismiss) var dismiss
	
	@State var email: String = ""
	@State var password: String = ""
	
	var screenWidth = UIScreen.main.bounds.width
	var screenHeight = UIScreen.main.bounds.height
	
	var body: some View {
		VStack {
			Spacer()
				.frame(height: screenHeight/15)
			
			HStack {
				Text("Create an account")
					.bold()
					.font(.largeTitle)
					.foregroundStyle(.primary)
					.padding(25)
				
				Spacer()
			}
			
			if authViewModel.errorMessage != "" {
				ZStack {
					RoundedRectangle(cornerRadius: 10)
						.frame(width: screenWidth * 0.9, height: screenHeight/15)
						.foregroundStyle(.red)
						.opacity(0.75)
					
					Text(authViewModel.errorMessage)
						.foregroundStyle(.white)
						.font(.body)
					
				}.padding(.bottom, 25)
			}
			
			ZStack {
				RoundedRectangle(cornerRadius: 30)
					.frame(width: screenWidth * 0.9, height: screenHeight/15)
					.foregroundStyle(.white)
				
				TextField("Email", text: $email)
					.keyboardType(.emailAddress)
					.padding(.horizontal, 40)
			}
			
			ZStack {
				RoundedRectangle(cornerRadius: 30)
					.frame(width: screenWidth * 0.9, height: screenHeight/15)
					.foregroundStyle(.white)
				
				TextField("Password", text: $password)
					.keyboardType(.asciiCapable)
					.padding(.horizontal, 40)
			}
			
			Button {
				Task {
					print("Creating an account...")
					await authViewModel.signup(email: email, password: password)
					
					if authViewModel.authState == .Signin {
						appViewModel.user = authViewModel.currentUser
						dismiss()
					}
				}
			} label: {
				ZStack {
					RoundedRectangle(cornerRadius: 30)
						.frame(width: screenWidth * 0.9, height: screenHeight/15)
					
					Text("Start cooking!")
						.bold()
						.font(.title2)
						.foregroundStyle(.white)
				}
			}
			
			Spacer()
		}
	}
}

#Preview {
	SignUpView(authViewModel: AuthViewModel(), appViewModel: AppViewModel())
}
