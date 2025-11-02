import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ChatView()
                .tabItem {
                    Label("チャット", systemImage: "message.fill")
                }

            HistoryView()
                .tabItem {
                    Label("履歴", systemImage: "clock.fill")
                }

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
        }
        .accentColor(.blue)
    }
}

struct ChatView: View {
    @StateObject private var service = CoachingService()
    @State private var inputText = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        if service.messages.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray.opacity(0.3))
                                Text("メッセージを送信して\nコーチと会話を始めましょう")
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 100)
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(service.messages) { message in
                                    MessageRow(message: message)
                                        .id(message.id)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .onChange(of: service.messages.count) { _ in
                        if let lastMessage = service.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                HStack {
                    TextField("メッセージを入力", text: $inputText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.leading)

                    Button("送信") {
                        let text = inputText
                        inputText = ""
                        Task {
                            await service.sendMessage(text)
                        }
                    }
                    .padding(.trailing)
                    .disabled(inputText.isEmpty)
                }
                .padding(.vertical)
            }
            .navigationTitle("あなたのコーチ")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }
}

struct MessageRow: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .assistant {
                VStack(alignment: .leading, spacing: 4) {
                    Text("コーチ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(message.content)
                        .padding(12)
                        .foregroundColor(.primary)
                        .background(Color.blue.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                }
                Spacer()
            } else {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("あなた")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(message.content)
                        .padding(12)
                        .foregroundColor(.primary)
                        .background(Color(.systemGray5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(.systemGray3), lineWidth: 1)
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}

// MARK: - History View
struct HistoryView: View {
    @StateObject private var service = CoachingService()
    @State private var conversations: [Conversation] = []
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("読み込み中...")
                } else if conversations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.3))
                        Text("まだ会話履歴がありません")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(conversations) { conversation in
                            NavigationLink(
                                destination: ConversationDetailView(
                                    service: service,
                                    conversationId: conversation.id
                                )
                            ) {
                                HistoryRow(conversation: conversation)
                            }
                        }
                        .onDelete(perform: deleteConversation)
                    }
                }
            }
            .navigationTitle("履歴")
            .toolbar {
                EditButton()
            }
            .task {
                await loadConversations()
            }
        }
        .navigationViewStyle(.stack)
    }

    private func loadConversations() async {
        isLoading = true
        let firestoreService = FirestoreService()
        do {
            conversations = try await firestoreService.loadConversations()
        } catch {
            print("Error loading conversations: \(error)")
        }
        isLoading = false
    }

    private func deleteConversation(at offsets: IndexSet) {
        Task {
            let firestoreService = FirestoreService()
            for index in offsets {
                let conversation = conversations[index]
                do {
                    try await firestoreService.deleteConversation(conversationId: conversation.id)
                    await MainActor.run {
                        conversations.remove(at: index)
                    }
                } catch {
                    print("Error deleting conversation: \(error)")
                }
            }
        }
    }
}

struct HistoryRow: View {
    let conversation: Conversation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(conversation.title)
                    .font(.headline)
                Spacer()
                Text(formatDate(conversation.updatedAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(conversation.preview)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "昨日"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            return formatter.string(from: date)
        }
    }
}

// 会話詳細ビュー
struct ConversationDetailView: View {
    @ObservedObject var service: CoachingService
    let conversationId: String
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView("読み込み中...")
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(service.messages) { message in
                            MessageRow(message: message)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("会話")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await service.loadConversation(conversationId: conversationId)
            isLoading = false
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingLogoutAlert = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {
                // アカウント情報
                Section(header: Text("アカウント")) {
                    if let user = authManager.user {
                        HStack {
                            Text("メール")
                            Spacer()
                            Text(user.email ?? "未設定")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            Text("ログアウト")
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "arrow.right.square")
                                .foregroundColor(.red)
                        }
                    }
                }

                // アプリ情報
                Section(header: Text("情報")) {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
            .alert("ログアウト", isPresented: $showingLogoutAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("ログアウト", role: .destructive) {
                    logout()
                }
            } message: {
                Text("ログアウトしてもよろしいですか？")
            }
        }
        .navigationViewStyle(.stack)
    }

    private func logout() {
        do {
            try authManager.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
