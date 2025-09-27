//
//  AppModel.swift
//  lift.news
//
//  Created by Michael Kao on 9/27/25.
//

import Foundation
internal import Combine

final class AppModel: ObservableObject {
	@Published var user: User?
	@Published var articles: [Article] = []
	@Published var positiveArticles: [Article] = []
}
