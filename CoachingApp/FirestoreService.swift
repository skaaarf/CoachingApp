//
//  FirestoreService.swift
//  CoachingApp
//
//  Created by Claude on 2025/11/02.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirestoreService {
    private let db = Firestore.firestore()

    // MARK: - Conversation Management

    /// 新しい会話セッションを作成
    func createConversation() async throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirestoreError.notAuthenticated
        }

        let conversationRef = db.collection("users").document(userId)
            .collection("conversations").document()

        let conversation: [String: Any] = [
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "title": "新しい会話"
        ]

        try await conversationRef.setData(conversation)
        return conversationRef.documentID
    }

    /// メッセージを保存
    func saveMessage(conversationId: String, message: ChatMessage) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirestoreError.notAuthenticated
        }

        let messageData: [String: Any] = [
            "role": message.role == .user ? "user" : "assistant",
            "content": message.content,
            "timestamp": FieldValue.serverTimestamp()
        ]

        // メッセージを保存
        try await db.collection("users").document(userId)
            .collection("conversations").document(conversationId)
            .collection("messages").document(message.id.uuidString)
            .setData(messageData)

        // 会話の更新日時を更新
        try await db.collection("users").document(userId)
            .collection("conversations").document(conversationId)
            .updateData(["updatedAt": FieldValue.serverTimestamp()])
    }

    /// 会話のメッセージを取得
    func loadMessages(conversationId: String) async throws -> [ChatMessage] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirestoreError.notAuthenticated
        }

        let snapshot = try await db.collection("users").document(userId)
            .collection("conversations").document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .getDocuments()

        return snapshot.documents.compactMap { doc -> ChatMessage? in
            let data = doc.data()
            guard let roleString = data["role"] as? String,
                  let content = data["content"] as? String,
                  let uuidString = UUID(uuidString: doc.documentID) else {
                return nil
            }

            let role: MessageRole = roleString == "user" ? .user : .assistant
            return ChatMessage(id: uuidString, role: role, content: content)
        }
    }

    /// 全ての会話一覧を取得
    func loadConversations() async throws -> [Conversation] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirestoreError.notAuthenticated
        }

        let snapshot = try await db.collection("users").document(userId)
            .collection("conversations")
            .order(by: "updatedAt", descending: true)
            .getDocuments()

        return try await withThrowingTaskGroup(of: Conversation?.self) { group in
            for doc in snapshot.documents {
                group.addTask {
                    let data = doc.data()
                    guard let title = data["title"] as? String else {
                        return nil
                    }

                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()

                    // 最初のメッセージをプレビューとして取得
                    let messagesSnapshot = try await self.db.collection("users").document(userId)
                        .collection("conversations").document(doc.documentID)
                        .collection("messages")
                        .order(by: "timestamp", descending: false)
                        .limit(to: 1)
                        .getDocuments()

                    let preview = messagesSnapshot.documents.first?["content"] as? String ?? "会話を開始"

                    return Conversation(
                        id: doc.documentID,
                        title: title,
                        preview: preview,
                        createdAt: createdAt,
                        updatedAt: updatedAt
                    )
                }
            }

            var conversations: [Conversation] = []
            for try await conversation in group {
                if let conversation = conversation {
                    conversations.append(conversation)
                }
            }
            return conversations.sorted { $0.updatedAt > $1.updatedAt }
        }
    }

    /// 会話を削除
    func deleteConversation(conversationId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirestoreError.notAuthenticated
        }

        // メッセージを全て削除
        let messagesSnapshot = try await db.collection("users").document(userId)
            .collection("conversations").document(conversationId)
            .collection("messages")
            .getDocuments()

        for doc in messagesSnapshot.documents {
            try await doc.reference.delete()
        }

        // 会話を削除
        try await db.collection("users").document(userId)
            .collection("conversations").document(conversationId)
            .delete()
    }
}

// MARK: - Models

struct Conversation: Identifiable {
    let id: String
    let title: String
    let preview: String
    let createdAt: Date
    let updatedAt: Date
}

enum FirestoreError: LocalizedError {
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "ログインが必要です"
        }
    }
}
