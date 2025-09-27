//
//  LogInSignUpView.swift
//  lift.news
//
//  Created by Michael Kao on 9/27/25.
//

import SwiftUI

struct LogInSignUpView: View {
	@StateObject private var authViewModel = AuthViewModel()
	@ObservedObject var appViewModel: AppViewModel
	
	@State private var logInClicked = false
	@State private var signUpClicked = false
	
	var screenWidth = UIScreen.main.bounds.width
	var screenHeight = UIScreen.main.bounds.height
	
	var body: some View {
		VStack {
			Spacer()
				.frame(height: screenHeight/3.5)
			
			Text("lift.news")
				.bold()
				.font(.largeTitle)
				.foregroundStyle(.primary)
			
			Spacer()
				.frame(height: screenHeight/9)
			
			Button {
				signUpClicked = true
			} label: {
				ZStack {
					RoundedRectangle(cornerRadius: 30)
						.frame(width: screenWidth * 0.9, height: screenHeight/15)
					
					Text("get started")
						.bold()
						.font(.title2)
						.foregroundStyle(.white)
				}
			}
			
			Button {
				logInClicked = true
			} label: {
				ZStack {
					RoundedRectangle(cornerRadius: 30)
						.frame(width: screenWidth * 0.9, height: screenHeight/15)
						.foregroundStyle(.white)
					
					Text("log in")
						.bold()
						.font(.title2)
						.foregroundStyle(.primary)
				}
			}
			
			Spacer()
		}.task {
			await authViewModel.isUserSignIn()
			
			if authViewModel.authState == .Signin {
				appViewModel.user = authViewModel.currentUser
			}
		}
		
		.sheet(isPresented: self.$logInClicked) {
			LogInView(authViewModel: authViewModel, appViewModel: appViewModel)
				.interactiveDismissDisabled()
		}
		.sheet(isPresented: self.$signUpClicked) {
			SignUpView(authViewModel: authViewModel, appViewModel: appViewModel)
				.interactiveDismissDisabled()
		}
	}
}

#Preview {
	LogInSignUpView(appViewModel: AppViewModel())
}
