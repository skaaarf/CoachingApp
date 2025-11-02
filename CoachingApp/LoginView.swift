//
//  LoginView.swift
//  CoachingApp
//
//  Created by Claude on 2025/11/02.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var authManager: AuthenticationManager
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // アプリのロゴ・タイトル
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                Text("コーチングアプリ")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("あなたの目標達成をサポート")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 40)

            Spacer()

            // Google サインインボタン
            Button(action: signInWithGoogle) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)

                    Text("Google でサインイン")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isLoading)
            .padding(.horizontal, 32)

            if isLoading {
                ProgressView()
                    .padding(.top, 8)
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
        .padding()
    }

    private func signInWithGoogle() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await authManager.signInWithGoogle()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
