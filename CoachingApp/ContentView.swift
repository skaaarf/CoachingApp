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
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("今日")) {
                    HistoryRow(title: "目標設定について", time: "13:45", preview: "今年の目標について相談しました")
                    HistoryRow(title: "キャリアプラン", time: "10:30", preview: "転職についてアドバイスを受けました")
                }

                Section(header: Text("昨日")) {
                    HistoryRow(title: "健康習慣", time: "昨日", preview: "運動習慣について話し合いました")
                }

                Section(header: Text("今週")) {
                    HistoryRow(title: "時間管理", time: "3日前", preview: "効率的な時間の使い方を学びました")
                    HistoryRow(title: "ストレス対処", time: "4日前", preview: "ストレス管理のテクニックを相談しました")
                }
            }
            .navigationTitle("履歴")
        }
        .navigationViewStyle(.stack)
    }
}

struct HistoryRow: View {
    let title: String
    let time: String
    let preview: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(preview)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @State private var enableNotifications = true
    @State private var darkModeEnabled = false
    @State private var coachingStyle = "バランス型"

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("通知設定")) {
                    Toggle("プッシュ通知", isOn: $enableNotifications)
                    Toggle("リマインダー", isOn: $enableNotifications)
                }

                Section(header: Text("表示設定")) {
                    Toggle("ダークモード", isOn: $darkModeEnabled)
                    Picker("文字サイズ", selection: .constant("標準")) {
                        Text("小").tag("小")
                        Text("標準").tag("標準")
                        Text("大").tag("大")
                    }
                }

                Section(header: Text("コーチング設定")) {
                    Picker("コーチングスタイル", selection: $coachingStyle) {
                        Text("励まし型").tag("励まし型")
                        Text("バランス型").tag("バランス型")
                        Text("厳格型").tag("厳格型")
                    }
                    NavigationLink("目標管理") {
                        Text("目標管理画面（準備中）")
                    }
                }

                Section(header: Text("アカウント")) {
                    NavigationLink("プロフィール") {
                        Text("プロフィール画面（準備中）")
                    }
                    NavigationLink("データのエクスポート") {
                        Text("エクスポート画面（準備中）")
                    }
                }

                Section(header: Text("情報")) {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    NavigationLink("利用規約") {
                        Text("利用規約（準備中）")
                    }
                    NavigationLink("プライバシーポリシー") {
                        Text("プライバシーポリシー（準備中）")
                    }
                }
            }
            .navigationTitle("設定")
        }
        .navigationViewStyle(.stack)
    }
}
