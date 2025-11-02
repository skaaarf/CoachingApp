//
//  CoachingService.swift
//  CoachingApp
//
//  Created by Ushiku Ryotaro on 2025/11/01.
//
import Foundation
import Combine

class CoachingService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var currentConversationId: String?

    private let apiKey = APIKey.claude
    private let firestoreService = FirestoreService()

    private let systemPrompt = """
    あなたはプロのライフコーチです。
    ユーザーの目標達成をサポートし、建設的な質問を通じて
    自己理解を深める手助けをしてください。
    温かく励ましながら、具体的な行動計画を一緒に考えましょう。
    """

    /// 新しい会話を開始
    func startNewConversation() async {
        do {
            let conversationId = try await firestoreService.createConversation()
            await MainActor.run {
                currentConversationId = conversationId
                messages = []
            }
        } catch {
            print("Error starting new conversation: \(error)")
        }
    }

    /// 既存の会話を読み込み
    func loadConversation(conversationId: String) async {
        do {
            let loadedMessages = try await firestoreService.loadMessages(conversationId: conversationId)
            await MainActor.run {
                currentConversationId = conversationId
                messages = loadedMessages
            }
        } catch {
            print("Error loading conversation: \(error)")
        }
    }

    /// メッセージを送信
    func sendMessage(_ text: String) async {
        // 会話IDがなければ新しい会話を作成
        if currentConversationId == nil {
            await startNewConversation()
        }

        guard let conversationId = currentConversationId else {
            print("Error: No conversation ID")
            return
        }

        let userMessage = ChatMessage(role: .user, content: text)
        await MainActor.run {
            messages.append(userMessage)
        }

        // Firestore に保存
        do {
            try await firestoreService.saveMessage(conversationId: conversationId, message: userMessage)
        } catch {
            print("Error saving user message: \(error)")
        }

        // Claude API を呼び出し
        do {
            let response = try await callClaudeAPI(text)
            let assistantMessage = ChatMessage(role: .assistant, content: response)
            await MainActor.run {
                messages.append(assistantMessage)
            }

            // Firestore に保存
            try await firestoreService.saveMessage(conversationId: conversationId, message: assistantMessage)
        } catch {
            print("Error: \(error)")
        }
    }

    private func callClaudeAPI(_ prompt: String) async throws -> String {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let messagesArray = messages.map { message in
            ["role": message.role == .user ? "user" : "assistant",
             "content": message.content]
        }

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1024,
            "system": systemPrompt,
            "messages": messagesArray
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let content = json["content"] as! [[String: Any]]
        return content[0]["text"] as! String
    }
}

struct ChatMessage: Identifiable {
    let id: UUID
    let role: MessageRole
    let content: String

    init(role: MessageRole, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
    }

    init(id: UUID, role: MessageRole, content: String) {
        self.id = id
        self.role = role
        self.content = content
    }
}

enum MessageRole {
    case user
    case assistant
}
