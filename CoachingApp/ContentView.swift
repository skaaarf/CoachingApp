import SwiftUI

struct ContentView: View {
    @StateObject private var service = CoachingService()
    @State private var inputText = ""

    var body: some View {
        VStack(spacing: 0) {
            Text("あなたのコーチ")
                .font(.headline)
                .padding()

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(service.messages) { message in
                            MessageRow(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.vertical, 8)
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
