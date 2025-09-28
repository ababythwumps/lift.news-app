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
	@Environment(\.colorScheme) var colorScheme
	@Environment(\.dismiss) var dismiss
	
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
				Text("get started")
					.font(.title3)
					.padding(.vertical)
					.foregroundStyle(colorScheme == .light ? Color.white : Color.black)
					.background(
						Rectangle()
							.stroke(.primary, lineWidth: 2)
							.frame(width: screenWidth * 0.9)
							.background(colorScheme == .light ? Color.black : Color.white)
					)
					.padding(.trailing)
			}.buttonStyle(PlainButtonStyle())
			
			Button {
				logInClicked = true
			} label: {
				Text("log in")
					.font(.title3)
					.padding(.horizontal)
					.padding(.vertical)
					.background(Color.clear)
					.overlay(
						Rectangle()
							.stroke(.primary, lineWidth: 2)
							.frame(width: screenWidth * 0.9)
					)
					.padding(.trailing)
			}.buttonStyle(PlainButtonStyle())
			
			Spacer()
		}.task {
			await authViewModel.isUserSignIn()
			
			if authViewModel.authState == .Signin {
				appViewModel.user = authViewModel.currentUser
			}
		}
		
		.sheet(isPresented: self.$logInClicked, onDismiss: {
			if appViewModel.user != nil {
				dismiss()
			}
		}) {
			LogInView(authViewModel: authViewModel, appViewModel: appViewModel)
		}
		.sheet(isPresented: self.$signUpClicked, onDismiss: {
			if appViewModel.user != nil {
				dismiss()
			}
		}) {
			SignUpView(authViewModel: authViewModel, appViewModel: appViewModel)
		}
	}
}

#Preview {
	LogInSignUpView(appViewModel: AppViewModel())
}
