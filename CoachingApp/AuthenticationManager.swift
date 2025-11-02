//
//  AuthenticationManager.swift
//  CoachingApp
//
//  Created by Claude on 2025/11/02.
//

import Foundation
import Combine
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

class AuthenticationManager: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false

    init() {
        // Firebase の認証状態を監視
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isAuthenticated = user != nil
        }
    }

    // Google でサインイン
    func signInWithGoogle() async throws {
        // クライアント ID を取得
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.noClientID
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        // ルートビューコントローラーを取得
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw AuthError.noRootViewController
        }

        // Google サインイン
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        let user = result.user

        guard let idToken = user.idToken?.tokenString else {
            throw AuthError.noIDToken
        }

        let accessToken = user.accessToken.tokenString
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

        // Firebase で認証
        try await Auth.auth().signIn(with: credential)
    }

    // サインアウト
    func signOut() throws {
        try Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
    }
}

enum AuthError: LocalizedError {
    case noClientID
    case noRootViewController
    case noIDToken

    var errorDescription: String? {
        switch self {
        case .noClientID:
            return "Firebase Client ID が見つかりません"
        case .noRootViewController:
            return "ルートビューコントローラーが見つかりません"
        case .noIDToken:
            return "ID トークンの取得に失敗しました"
        }
    }
}
