//
//  CoachingService.swift
//  CoachingApp
//
//  Created by Ushiku Ryotaro on 2025/11/01.
//
import Foundation
import Foundation
import Combine

class CoachingService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    private let apiKey = APIKey.claude
    
    private let systemPrompt = """
    あなたはプロのライフコーチです。
    ユーザーの目標達成をサポートし、建設的な質問を通じて
    自己理解を深める手助けをしてください。
    温かく励ましながら、具体的な行動計画を一緒に考えましょう。
    """
    
    func sendMessage(_ text: String) async {
        let userMessage = ChatMessage(role: .user, content: text)
        await MainActor.run {
            messages.append(userMessage)
        }
        
        do {
            let response = try await callClaudeAPI(text)
            let assistantMessage = ChatMessage(role: .assistant, content: response)
            await MainActor.run {
                messages.append(assistantMessage)
            }
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
    let id = UUID()
    let role: MessageRole
    let content: String
}

enum MessageRole {
    case user
    case assistant
}
